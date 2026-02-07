#!/usr/bin/env node

/**
 * Cursor IDE Test Harness - Long-running approach
 *
 * Usage:
 *   cursor-prompt --start              # Launch Cursor with test profile (log in once)
 *   cursor-prompt "prompt text"        # Send prompt and wait for response
 *   cursor-prompt --status             # Check if Cursor is ready
 *   cursor-prompt --stop               # Stop Cursor
 *
 * Environment variables:
 *   CURSOR_PATH - Path to Cursor executable (auto-detected if not set)
 */

import * as path from 'path';
import * as fs from 'fs';
import { fileURLToPath } from 'url';
import { spawn, execSync } from 'child_process';
import { randomUUID } from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// IPC paths (must match extension)
const IPC_DIR = '/tmp/cursor-test-ipc';
const PROMPT_FILE = path.join(IPC_DIR, 'prompt.json');
const RESPONSE_FILE = path.join(IPC_DIR, 'response.json');
const STATUS_FILE = path.join(IPC_DIR, 'status.json');

// Test profile paths (persistent)
const TEST_PROFILE_DIR = path.resolve(__dirname, '.cursor-test-profile');
const TEST_EXTENSIONS_DIR = path.resolve(__dirname, '.cursor-test-extensions');

function findCursorPath() {
    if (process.env.CURSOR_PATH) {
        return process.env.CURSOR_PATH;
    }

    const locations = [
        '/Applications/Cursor.app/Contents/MacOS/Cursor',
        '/usr/local/bin/cursor',
        '/usr/bin/cursor',
        '/opt/Cursor/cursor',
    ];

    for (const loc of locations) {
        if (fs.existsSync(loc)) {
            return loc;
        }
    }

    try {
        const result = execSync('which cursor 2>/dev/null || true').toString().trim();
        if (result && fs.existsSync(result)) {
            return result;
        }
    } catch {}

    return null;
}

function getStatus() {
    if (!fs.existsSync(STATUS_FILE)) {
        return null;
    }
    try {
        return JSON.parse(fs.readFileSync(STATUS_FILE, 'utf8'));
    } catch {
        return null;
    }
}

function isCursorRunning() {
    const status = getStatus();
    if (!status || status.state === 'stopped') {
        return false;
    }

    // Check if the process is actually running
    if (status.pid) {
        try {
            process.kill(status.pid, 0);
            return true;
        } catch {
            return false;
        }
    }

    return false;
}

async function startCursor(workspacePath) {
    const cursorPath = findCursorPath();
    if (!cursorPath) {
        console.error('Error: Cursor not found. Set CURSOR_PATH environment variable.');
        process.exit(1);
    }

    // Ensure directories exist
    fs.mkdirSync(TEST_PROFILE_DIR, { recursive: true });
    fs.mkdirSync(TEST_EXTENSIONS_DIR, { recursive: true });
    fs.mkdirSync(IPC_DIR, { recursive: true });

    // Clean up old IPC files
    try { fs.unlinkSync(PROMPT_FILE); } catch {}
    try { fs.unlinkSync(RESPONSE_FILE); } catch {}
    try { fs.unlinkSync(STATUS_FILE); } catch {}

    const extensionPath = path.resolve(__dirname, 'extension');

    console.log('Starting Cursor with test profile...');
    console.log(`  Profile: ${TEST_PROFILE_DIR}`);
    console.log(`  Extension: ${extensionPath}`);
    console.log(`  Workspace: ${workspacePath}`);

    // Launch Cursor as a detached process
    const args = [
        workspacePath,
        `--user-data-dir=${TEST_PROFILE_DIR}`,
        `--extensions-dir=${TEST_EXTENSIONS_DIR}`,
        `--extensionDevelopmentPath=${extensionPath}`,
    ];

    const child = spawn(cursorPath, args, {
        detached: true,
        stdio: 'ignore',
    });

    child.unref();

    console.log(`\nCursor launched (PID: ${child.pid})`);
    console.log('\nWaiting for extension to initialize...');

    // Wait for extension to write status file
    const timeout = 30000;
    const start = Date.now();
    while (Date.now() - start < timeout) {
        const status = getStatus();
        if (status && status.state === 'ready') {
            console.log('\n✓ Extension ready! You can now send prompts.');
            console.log('\nIf this is your first run, please log in to Cursor.');
            console.log('The session will persist for future runs.');
            return;
        }
        await new Promise(r => setTimeout(r, 500));
    }

    console.log('\n⚠ Extension did not report ready within timeout.');
    console.log('Cursor may still be starting. Check the status with: cursor-prompt --status');
}

async function sendPrompt(prompt, timeoutMs = 60000) {
    // Check if Cursor is running
    const status = getStatus();
    if (!status || status.state !== 'ready') {
        console.error('Error: Cursor is not running or not ready.');
        console.error('Start it first with: cursor-prompt --start');
        console.error(`Current status: ${status ? status.state : 'not running'}`);
        process.exit(1);
    }

    // Ensure IPC directory exists
    fs.mkdirSync(IPC_DIR, { recursive: true });

    // Clean up old response
    try { fs.unlinkSync(RESPONSE_FILE); } catch {}

    // Generate unique ID for this prompt
    const id = randomUUID().substring(0, 8);

    // Write prompt file
    const promptData = {
        id,
        prompt,
        timestamp: new Date().toISOString()
    };

    fs.writeFileSync(PROMPT_FILE, JSON.stringify(promptData, null, 2));
    console.error(`Sent prompt [${id}]: ${prompt.substring(0, 50)}...`);

    // Wait for response
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
        if (fs.existsSync(RESPONSE_FILE)) {
            const response = JSON.parse(fs.readFileSync(RESPONSE_FILE, 'utf8'));

            // Check if this is our response
            if (response.id === id || !response.id) {
                // Clean up
                try { fs.unlinkSync(RESPONSE_FILE); } catch {}

                if (response.success) {
                    console.log(response.response || 'Prompt sent successfully');
                    return response;
                } else {
                    console.error('Error:', response.error);
                    process.exit(1);
                }
            }
        }
        await new Promise(r => setTimeout(r, 200));
    }

    console.error('Timeout waiting for response');
    process.exit(1);
}

function showStatus() {
    const status = getStatus();
    if (!status) {
        console.log('Status: Not running');
        console.log('\nStart Cursor with: cursor-prompt --start');
        return;
    }

    console.log(`Status: ${status.state}`);
    console.log(`Message: ${status.message}`);
    console.log(`PID: ${status.pid || 'unknown'}`);
    console.log(`Last update: ${status.timestamp}`);

    if (status.state === 'ready') {
        console.log('\n✓ Ready to receive prompts');
    }
}

function stopCursor() {
    const status = getStatus();
    if (status && status.pid) {
        try {
            process.kill(status.pid, 'SIGTERM');
            console.log(`Sent SIGTERM to PID ${status.pid}`);
        } catch (error) {
            console.log('Process not running or already stopped');
        }
    }

    // Clean up status file
    try { fs.unlinkSync(STATUS_FILE); } catch {}
    console.log('Stopped');
}

function showHelp() {
    console.log(`
Cursor IDE Test Harness

Usage:
  cursor-prompt --start [--workspace PATH]    Launch Cursor with test profile
  cursor-prompt "prompt text"                 Send prompt and wait for response
  cursor-prompt --status                      Check if Cursor is ready
  cursor-prompt --stop                        Stop Cursor
  cursor-prompt --reset                       Reset test profile (requires re-login)
  cursor-prompt --help                        Show this help

Options:
  --workspace PATH    Workspace directory (default: current dir)
  --timeout MS        Prompt timeout in milliseconds (default: 60000)

First-time setup:
  1. Run: cursor-prompt --start
  2. Log in to Cursor when prompted
  3. The session will persist for future runs

Examples:
  cursor-prompt --start --workspace /path/to/project
  cursor-prompt "What is 2+2?"
  cursor-prompt --status
`);
}

async function main() {
    const args = process.argv.slice(2);

    if (args.includes('--help') || args.includes('-h')) {
        showHelp();
        process.exit(0);
    }

    // Parse workspace
    let workspacePath = process.cwd();
    const wsIdx = args.indexOf('--workspace');
    if (wsIdx !== -1 && args[wsIdx + 1]) {
        workspacePath = path.resolve(args[wsIdx + 1]);
    }

    // Parse timeout
    let timeout = 60000;
    const toIdx = args.indexOf('--timeout');
    if (toIdx !== -1 && args[toIdx + 1]) {
        timeout = parseInt(args[toIdx + 1], 10);
    }

    if (args.includes('--start')) {
        await startCursor(workspacePath);
    } else if (args.includes('--status')) {
        showStatus();
    } else if (args.includes('--stop')) {
        stopCursor();
    } else if (args.includes('--reset')) {
        console.log('Resetting test profile...');
        try { fs.rmSync(TEST_PROFILE_DIR, { recursive: true }); } catch {}
        try { fs.rmSync(TEST_EXTENSIONS_DIR, { recursive: true }); } catch {}
        try { fs.rmSync(IPC_DIR, { recursive: true }); } catch {}
        console.log('Done. Run --start to create a fresh profile.');
    } else {
        // Find prompt (first non-flag argument)
        const prompt = args.find(arg => !arg.startsWith('--'));
        if (prompt) {
            await sendPrompt(prompt, timeout);
        } else {
            // Check for stdin
            if (!process.stdin.isTTY) {
                let input = '';
                for await (const chunk of process.stdin) {
                    input += chunk;
                }
                if (input.trim()) {
                    await sendPrompt(input.trim(), timeout);
                    return;
                }
            }
            showHelp();
            process.exit(1);
        }
    }
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
