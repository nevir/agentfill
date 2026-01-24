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
// File path for IPC with test runner
const COMMAND_FILE = process.env.CURSOR_TEST_COMMAND_FILE || '/tmp/cursor-test-commands.json';
const PROMPT_FILE = process.env.CURSOR_TEST_PROMPT_FILE || '/tmp/cursor-test-prompt.txt';
const RESPONSE_FILE = process.env.CURSOR_TEST_RESPONSE_FILE || '/tmp/cursor-test-response.txt';
async function activate(context) {
    console.log('Cursor Test Harness activated');
    // Register command discovery
    context.subscriptions.push(vscode.commands.registerCommand('cursorTestHarness.discoverCommands', async () => {
        await discoverCommands();
    }));
    // Register prompt sender
    context.subscriptions.push(vscode.commands.registerCommand('cursorTestHarness.sendPrompt', async () => {
        await sendPromptFromFile();
    }));
    // If CURSOR_TEST_AUTO_DISCOVER is set, automatically discover commands
    if (process.env.CURSOR_TEST_AUTO_DISCOVER) {
        setTimeout(() => discoverCommands(), 2000);
    }
    // If CURSOR_TEST_AUTO_PROMPT is set, automatically send prompt
    if (process.env.CURSOR_TEST_AUTO_PROMPT) {
        setTimeout(() => sendPromptFromFile(), 3000);
    }
}
async function discoverCommands() {
    try {
        const allCommands = await vscode.commands.getCommands(true);
        // Filter for relevant commands
        const relevantPatterns = [
            'cursor', 'chat', 'agent', 'ai', 'copilot',
            'assistant', 'composer', 'prompt', 'aichat'
        ];
        const relevantCommands = allCommands.filter(cmd => relevantPatterns.some(pattern => cmd.toLowerCase().includes(pattern)));
        const result = {
            timestamp: new Date().toISOString(),
            totalCommands: allCommands.length,
            relevantCommands: relevantCommands.sort(),
            // Also include any command that might be useful for chat interaction
            chatCommands: allCommands.filter(cmd => cmd.includes('chat') || cmd.includes('Chat')).sort(),
            workbenchCommands: allCommands.filter(cmd => cmd.startsWith('workbench.action')).sort()
        };
        fs.writeFileSync(COMMAND_FILE, JSON.stringify(result, null, 2));
        console.log(`Commands written to ${COMMAND_FILE}`);
        // Also show in VS Code
        vscode.window.showInformationMessage(`Found ${relevantCommands.length} relevant commands. Written to ${COMMAND_FILE}`);
    }
    catch (error) {
        console.error('Failed to discover commands:', error);
        fs.writeFileSync(COMMAND_FILE, JSON.stringify({ error: String(error) }));
    }
}
async function sendPromptFromFile() {
    try {
        // Read prompt from file
        if (!fs.existsSync(PROMPT_FILE)) {
            throw new Error(`Prompt file not found: ${PROMPT_FILE}`);
        }
        const prompt = fs.readFileSync(PROMPT_FILE, 'utf8').trim();
        console.log(`Sending prompt: ${prompt.substring(0, 100)}...`);
        // Try various methods to send the prompt
        const methods = [
            tryWorkbenchChat,
            tryCursorChat,
            tryAIChat,
            tryComposer,
        ];
        let success = false;
        let lastError = '';
        for (const method of methods) {
            try {
                await method(prompt);
                success = true;
                break;
            }
            catch (error) {
                lastError = String(error);
                console.log(`Method failed: ${lastError}`);
            }
        }
        if (!success) {
            fs.writeFileSync(RESPONSE_FILE, JSON.stringify({
                success: false,
                error: `All methods failed. Last error: ${lastError}`
            }));
        }
    }
    catch (error) {
        console.error('Failed to send prompt:', error);
        fs.writeFileSync(RESPONSE_FILE, JSON.stringify({
            success: false,
            error: String(error)
        }));
    }
}
async function tryWorkbenchChat(prompt) {
    // Try the test command that opens chat with a prompt
    console.log('Trying workbench.action.chat.testOpenWithPrompt...');
    await vscode.commands.executeCommand('workbench.action.chat.testOpenWithPrompt', prompt);
}
async function tryCursorChat(prompt) {
    // Try Cursor composer commands
    console.log('Trying composer.startComposerPrompt...');
    // First open the composer
    await vscode.commands.executeCommand('composer.openComposer');
    await delay(1000);
    // Then try to send the prompt
    try {
        await vscode.commands.executeCommand('composer.startComposerPrompt', prompt);
    }
    catch {
        // If that doesn't work, try sendToAgent
        await vscode.commands.executeCommand('composer.sendToAgent', prompt);
    }
}
async function tryAIChat(prompt) {
    // Try new agent chat
    console.log('Trying composer.newAgentChat...');
    await vscode.commands.executeCommand('composer.newAgentChat');
    await delay(1000);
    // Type the prompt using the editor type command
    await vscode.commands.executeCommand('type', { text: prompt });
    await delay(200);
    // Try to submit
    await vscode.commands.executeCommand('workbench.action.chat.stopListeningAndSubmit');
}
async function tryComposer(prompt) {
    // Try opening composer and using type command
    console.log('Trying composer.focusComposer with type...');
    await vscode.commands.executeCommand('composer.focusComposer');
    await delay(500);
    // Type the prompt
    await vscode.commands.executeCommand('type', { text: prompt });
    await delay(200);
    // Press Enter to submit (key code 13)
    await vscode.commands.executeCommand('type', { text: '\n' });
}
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
function deactivate() {
    console.log('Cursor Test Harness deactivated');
}
