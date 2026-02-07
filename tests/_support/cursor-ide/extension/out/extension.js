"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
// File paths for IPC - use a consistent location
const IPC_DIR = '/tmp/cursor-test-ipc';
const PROMPT_FILE = path.join(IPC_DIR, 'prompt.json');
const RESPONSE_FILE = path.join(IPC_DIR, 'response.json');
const STATUS_FILE = path.join(IPC_DIR, 'status.json');
let fileWatcher = null;
let isProcessing = false;
let commandLogging = false;
const commandLog = [];
// Hook command execution to log what commands are being run
const originalExecuteCommand = vscode.commands.executeCommand.bind(vscode.commands);
vscode.commands.executeCommand = async function (command, ...args) {
    if (commandLogging) {
        const entry = `${new Date().toISOString()} - ${command}`;
        commandLog.push(entry);
        console.log(`[CMD LOG] ${entry}`);
        // Write to file
        const logFile = path.join(IPC_DIR, 'command-log.txt');
        fs.appendFileSync(logFile, entry + '\n');
    }
    return originalExecuteCommand(command, ...args);
};
async function activate(context) {
    console.log('Cursor Test Harness activated - starting prompt watcher');
    // Start command logging
    commandLogging = true;
    const logFile = path.join(IPC_DIR, 'command-log.txt');
    fs.writeFileSync(logFile, `=== Command logging started at ${new Date().toISOString()} ===\n`);
    console.log(`Command logging enabled - writing to ${logFile}`);
    // Ensure IPC directory exists
    if (!fs.existsSync(IPC_DIR)) {
        fs.mkdirSync(IPC_DIR, { recursive: true });
    }
    // Write status to indicate extension is ready
    writeStatus('ready', 'Extension activated and watching for prompts');
    // Clean up any stale prompt file
    try {
        fs.unlinkSync(PROMPT_FILE);
    }
    catch { }
    try {
        fs.unlinkSync(RESPONSE_FILE);
    }
    catch { }
    // Start watching for prompt files
    startPromptWatcher();
    // Register manual command for testing
    context.subscriptions.push(vscode.commands.registerCommand('cursorTestHarness.processPrompt', async () => {
        await processPromptFile();
    }));
    // Cleanup on deactivation
    context.subscriptions.push({
        dispose: () => {
            if (fileWatcher) {
                fileWatcher.close();
                fileWatcher = null;
            }
            writeStatus('stopped', 'Extension deactivated');
        }
    });
}
function writeStatus(state, message) {
    const status = {
        state,
        message,
        timestamp: new Date().toISOString(),
        pid: process.pid
    };
    try {
        fs.writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2));
    }
    catch (error) {
        console.error('Failed to write status:', error);
    }
}
function startPromptWatcher() {
    // Watch the IPC directory for the prompt file
    console.log(`Watching for prompts in ${IPC_DIR}`);
    // Use polling since fs.watch can be unreliable
    const checkForPrompt = async () => {
        if (isProcessing)
            return;
        if (fs.existsSync(PROMPT_FILE)) {
            await processPromptFile();
        }
    };
    // Check every 500ms
    const interval = setInterval(checkForPrompt, 500);
    // Also try fs.watch as backup
    try {
        fileWatcher = fs.watch(IPC_DIR, async (eventType, filename) => {
            if (filename === 'prompt.json' && eventType === 'rename') {
                await checkForPrompt();
            }
        });
    }
    catch (error) {
        console.log('fs.watch not available, using polling only');
    }
}
async function processPromptFile() {
    if (isProcessing) {
        console.log('Already processing a prompt, skipping');
        return;
    }
    if (!fs.existsSync(PROMPT_FILE)) {
        return;
    }
    isProcessing = true;
    writeStatus('processing', 'Processing prompt');
    try {
        // Read and parse prompt
        const promptData = JSON.parse(fs.readFileSync(PROMPT_FILE, 'utf8'));
        const { prompt, id } = promptData;
        console.log(`Processing prompt [${id}]: ${prompt.substring(0, 50)}...`);
        // Delete prompt file immediately to prevent re-processing
        fs.unlinkSync(PROMPT_FILE);
        // Send the prompt and get response
        const result = await sendPromptToChat(prompt);
        // Write response
        const response = {
            id,
            success: result.success,
            response: result.response,
            error: result.error,
            timestamp: new Date().toISOString()
        };
        fs.writeFileSync(RESPONSE_FILE, JSON.stringify(response, null, 2));
        console.log(`Response written for [${id}]`);
        writeStatus('ready', 'Prompt processed, waiting for next');
    }
    catch (error) {
        console.error('Error processing prompt:', error);
        fs.writeFileSync(RESPONSE_FILE, JSON.stringify({
            success: false,
            error: String(error),
            timestamp: new Date().toISOString()
        }, null, 2));
        writeStatus('error', String(error));
    }
    finally {
        isProcessing = false;
    }
}
async function sendPromptToChat(prompt) {
    try {
        // Open a new agent chat and focus it
        console.log('Opening new agent chat...');
        await vscode.commands.executeCommand('composer.newAgentChat');
        await delay(1500);
        console.log('Focusing composer...');
        await vscode.commands.executeCommand('composer.focusComposer');
        await delay(500);
        // Try terminal chat as alternative - might have better command support
        console.log('Trying terminal chat approach...');
        try {
            // Start terminal chat
            await vscode.commands.executeCommand('workbench.action.terminal.chat.start');
            await delay(1000);
            // Try to run command with the prompt
            await vscode.commands.executeCommand('workbench.action.terminal.chat.runCommand', prompt);
            console.log('Terminal chat runCommand executed');
            await delay(2000);
        }
        catch (e) {
            console.log(`Terminal chat approach failed: ${e}`);
        }
        // If terminal chat didn't work, try the regular composer with clipboard
        console.log('Falling back to composer with clipboard...');
        await vscode.commands.executeCommand('composer.newAgentChat');
        await delay(1000);
        await vscode.commands.executeCommand('composer.focusComposer');
        await delay(500);
        // Paste the prompt
        await vscode.env.clipboard.writeText(prompt);
        await vscode.commands.executeCommand('editor.action.clipboardPasteAction');
        console.log('Prompt pasted - manual submit required');
        // Log instructions for the user
        console.log('*** PROMPT ENTERED - PRESS ENTER OR CLICK SEND TO SUBMIT ***');
        // Wait for response
        console.log('Waiting for response...');
        await delay(5000);
        return {
            success: true,
            response: 'Prompt sent via clipboard paste + return. Check Cursor UI for response.'
        };
    }
    catch (error) {
        console.error('Failed to send prompt:', error);
        return {
            success: false,
            error: String(error)
        };
    }
}
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
function deactivate() {
    console.log('Cursor Test Harness deactivated');
    if (fileWatcher) {
        fileWatcher.close();
        fileWatcher = null;
    }
    writeStatus('stopped', 'Extension deactivated');
}
