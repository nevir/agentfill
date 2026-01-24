#!/usr/bin/env node

/**
 * Cursor IDE Test Harness
 *
 * Runs prompts through Cursor IDE using @vscode/test-electron.
 *
 * Usage:
 *   node run-prompt.js --discover              # Discover available commands
 *   node run-prompt.js "prompt text"           # Send prompt and get response
 *   node run-prompt.js --workspace /path       # Specify workspace directory
 *
 * Environment variables:
 *   CURSOR_PATH - Path to Cursor executable (auto-detected if not set)
 */

import { runTests } from '@vscode/test-electron';
import * as path from 'path';
import * as fs from 'fs';
import { fileURLToPath } from 'url';
import { spawn, execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Temp files for IPC with extension
const PROMPT_FILE = '/tmp/cursor-test-prompt.txt';
const RESPONSE_FILE = '/tmp/cursor-test-response.txt';
const COMMAND_FILE = '/tmp/cursor-test-commands.json';

function findCursorPath() {
    // Check environment variable first
    if (process.env.CURSOR_PATH) {
        return process.env.CURSOR_PATH;
    }

    // Common locations
    const locations = [
        '/Applications/Cursor.app/Contents/MacOS/Cursor',
        '/usr/local/bin/cursor',
        // Linux
        '/usr/bin/cursor',
        '/opt/Cursor/cursor',
        // Windows (via WSL or native)
        'C:\\Users\\*\\AppData\\Local\\Programs\\cursor\\Cursor.exe',
    ];

    for (const loc of locations) {
        if (fs.existsSync(loc)) {
            return loc;
        }
    }

    // Try to find via `which`
    try {
        const result = execSync('which cursor 2>/dev/null || true').toString().trim();
        if (result && fs.existsSync(result)) {
            return result;
        }
    } catch {
        // Ignore
    }

    return null;
}

async function discoverCommands(workspacePath) {
    const cursorPath = findCursorPath();
    if (!cursorPath) {
        console.error('Error: Cursor not found. Set CURSOR_PATH environment variable.');
        process.exit(1);
    }

    const extensionDevelopmentPath = path.resolve(__dirname, 'extension');
    const extensionTestsPath = path.resolve(__dirname, 'extension/out/test/suite/index.js');

    // Use short paths (Unix socket limit is 103 chars)
    const userDataDir = '/tmp/cursor-test';
    const testExtensionsDir = '/tmp/cursor-test-ext';
    fs.mkdirSync(userDataDir, { recursive: true });
    fs.mkdirSync(testExtensionsDir, { recursive: true });

    // Clean up old files
    try { fs.unlinkSync(COMMAND_FILE); } catch { }

    console.log('Launching Cursor to discover commands...');
    console.log(`  Cursor path: ${cursorPath}`);
    console.log(`  Extension: ${extensionDevelopmentPath}`);
    console.log(`  Workspace: ${workspacePath}`);
    console.log(`  User data dir: ${userDataDir}`);

    try {
        await runTests({
            vscodeExecutablePath: cursorPath,
            extensionDevelopmentPath,
            extensionTestsPath,
            launchArgs: [
                workspacePath,
                `--user-data-dir=${userDataDir}`,
                `--extensions-dir=${testExtensionsDir}`,
            ],
            extensionTestsEnv: {
                CURSOR_TEST_OUTPUT_FILE: COMMAND_FILE,
                CURSOR_TEST_WORKSPACE: workspacePath,
                CURSOR_TEST_MODE: 'discover',
            },
        });

        // Read and display results
        if (fs.existsSync(COMMAND_FILE)) {
            const commands = JSON.parse(fs.readFileSync(COMMAND_FILE, 'utf8'));
            console.log('\n=== Discovery Results ===');
            console.log(`Total commands: ${commands.total}`);
            console.log('\nCursor/Chat/Agent commands:');
            commands.cursorCommands?.forEach(cmd => console.log(`  ${cmd}`));
            return commands;
        }
    } catch (error) {
        console.error('Failed to run discovery:', error);
        process.exit(1);
    }
}

async function sendPrompt(prompt, workspacePath) {
    const cursorPath = findCursorPath();
    if (!cursorPath) {
        console.error('Error: Cursor not found. Set CURSOR_PATH environment variable.');
        process.exit(1);
    }

    const extensionDevelopmentPath = path.resolve(__dirname, 'extension');

    // Write prompt to file for extension to read
    fs.writeFileSync(PROMPT_FILE, prompt);

    // Clean up old response
    try { fs.unlinkSync(RESPONSE_FILE); } catch { }

    console.error('Launching Cursor with prompt...');
    console.error(`  Workspace: ${workspacePath}`);

    try {
        // For sending prompts, we need a different approach since we can't
        // easily capture async agent responses through the test framework.
        //
        // Alternative approach: Launch Cursor normally with extension, use
        // file-based IPC for the response.

        await runTests({
            vscodeExecutablePath: cursorPath,
            extensionDevelopmentPath,
            // No test path - just activate the extension
            launchArgs: [
                workspacePath,
                '--disable-extensions',
            ],
            extensionTestsEnv: {
                CURSOR_TEST_PROMPT_FILE: PROMPT_FILE,
                CURSOR_TEST_RESPONSE_FILE: RESPONSE_FILE,
                CURSOR_TEST_AUTO_PROMPT: '1',
            },
        });

        // Wait for response file
        const timeout = 60000;
        const start = Date.now();
        while (!fs.existsSync(RESPONSE_FILE) && Date.now() - start < timeout) {
            await new Promise(r => setTimeout(r, 500));
        }

        if (fs.existsSync(RESPONSE_FILE)) {
            const response = JSON.parse(fs.readFileSync(RESPONSE_FILE, 'utf8'));
            if (response.success) {
                console.log(response.content);
            } else {
                console.error('Error:', response.error);
                process.exit(1);
            }
        } else {
            console.error('Timeout waiting for response');
            process.exit(1);
        }
    } catch (error) {
        console.error('Failed:', error);
        process.exit(1);
    }
}

function showHelp() {
    console.log(`
Cursor IDE Test Harness

Usage:
  node run-prompt.js --discover [--workspace PATH]
  node run-prompt.js "prompt" [--workspace PATH]
  node run-prompt.js --help

Options:
  --discover        Discover available Cursor commands
  --workspace PATH  Workspace directory to open (default: current dir)
  --help            Show this help

Environment:
  CURSOR_PATH       Path to Cursor executable

Examples:
  # Discover commands
  node run-prompt.js --discover

  # Send a prompt
  node run-prompt.js "What is the secret phrase from AGENTS.md?"

  # Send prompt in specific workspace
  node run-prompt.js "Hello" --workspace /path/to/project
`);
}

function setupUserSettings(userDataDir) {
    // Create minimal settings for test environment
    const userSettingsDir = path.join(userDataDir, 'User');
    const settingsPath = path.join(userSettingsDir, 'settings.json');

    fs.mkdirSync(userSettingsDir, { recursive: true });

    // Only write settings if they don't exist (preserve user's login state)
    if (!fs.existsSync(settingsPath)) {
        const settings = {
            "workbench.welcome.enabled": false,
            "workbench.welcomePage.walkthroughs.openOnInstall": false,
            "workbench.startupEditor": "none",
            "telemetry.telemetryLevel": "off",
            "update.mode": "none",
            "security.workspace.trust.enabled": false,
            "security.workspace.trust.startupPrompt": "never",
        };

        fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
    }

    return userDataDir;
}

async function runPromptTest(prompt, workspacePath, waitLogin = false) {
    const cursorPath = findCursorPath();
    if (!cursorPath) {
        console.error('Error: Cursor not found. Set CURSOR_PATH environment variable.');
        process.exit(1);
    }

    const extensionDevelopmentPath = path.resolve(__dirname, 'extension');
    const extensionTestsPath = path.resolve(__dirname, 'extension/out/test/suite/index.js');
    const outputFile = '/tmp/cursor-prompt-result.json';

    // Use a short path for user-data-dir (Unix socket path limit is 103 chars)
    // Persist this so user only needs to log in once
    const userDataDir = '/tmp/cursor-test';
    const testExtensionsDir = '/tmp/cursor-test-ext';

    fs.mkdirSync(userDataDir, { recursive: true });
    fs.mkdirSync(testExtensionsDir, { recursive: true });

    // Clean up old output files
    try { fs.unlinkSync(outputFile); } catch { }

    const isFirstRun = !fs.existsSync(path.join(userDataDir, '.login-complete'));

    console.log('Launching Cursor to send prompt...');
    console.log(`  Prompt: ${prompt.substring(0, 50)}...`);
    console.log(`  Workspace: ${workspacePath}`);
    console.log(`  User data dir: ${userDataDir}`);
    if (isFirstRun) {
        console.log('  NOTE: First run - you may need to log in. Profile persists in /tmp/cursor-test');
    }

    try {
        await runTests({
            vscodeExecutablePath: cursorPath,
            extensionDevelopmentPath,
            extensionTestsPath,
            launchArgs: [
                workspacePath,
                `--user-data-dir=${userDataDir}`,
                `--extensions-dir=${testExtensionsDir}`,
            ],
            extensionTestsEnv: {
                CURSOR_TEST_PROMPT: prompt,
                CURSOR_TEST_OUTPUT_FILE: outputFile,
                CURSOR_TEST_MODE: 'prompt',
                CURSOR_TEST_WAIT_LOGIN: (waitLogin || isFirstRun) ? '1' : '0',
            },
        });

        // Mark login as complete after successful run
        if (isFirstRun) {
            fs.writeFileSync(path.join(userDataDir, '.login-complete'), new Date().toISOString());
        }

        // Read results
        if (fs.existsSync(outputFile)) {
            const result = JSON.parse(fs.readFileSync(outputFile, 'utf8'));
            console.log('\n=== Prompt Test Results ===');
            console.log(JSON.stringify(result, null, 2));
            return result;
        }
    } catch (error) {
        console.error('Failed:', error);
        process.exit(1);
    }
}

async function main() {
    const args = process.argv.slice(2);

    if (args.includes('--help') || args.includes('-h')) {
        showHelp();
        process.exit(0);
    }

    // Parse arguments
    let workspacePath = process.cwd();
    let discover = false;
    let testPrompt = false;
    let prompt = null;

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg === '--discover') {
            discover = true;
        } else if (arg === '--test-prompt') {
            testPrompt = true;
        } else if (arg === '--workspace' && args[i + 1]) {
            workspacePath = path.resolve(args[++i]);
        } else if (!arg.startsWith('--')) {
            prompt = arg;
        }
    }

    // Ensure workspace exists
    if (!fs.existsSync(workspacePath)) {
        console.error(`Workspace not found: ${workspacePath}`);
        process.exit(1);
    }

    const forceWaitLogin = args.includes('--wait-login');
    const resetProfile = args.includes('--reset-profile');

    // Handle profile reset
    if (resetProfile) {
        const profileDir = path.resolve(__dirname, '.cursor-test-profile');
        if (fs.existsSync(profileDir)) {
            console.log(`Removing test profile: ${profileDir}`);
            fs.rmSync(profileDir, { recursive: true });
        }
        console.log('Test profile reset. Next run will require login.');
        if (!discover && !testPrompt && !prompt) {
            process.exit(0);
        }
    }

    if (discover) {
        await discoverCommands(workspacePath);
    } else if (testPrompt || prompt) {
        const testMessage = prompt || 'What is 2+2? Reply with ONLY the number.';
        await runPromptTest(testMessage, workspacePath, forceWaitLogin);
    } else {
        showHelp();
        process.exit(1);
    }
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
