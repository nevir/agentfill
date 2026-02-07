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
const assert = __importStar(require("assert"));
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
suite('Prompt Sending', () => {
    test('Send a simple prompt to Cursor', async function () {
        this.timeout(300000); // 5 minute timeout to allow login
        const prompt = process.env.CURSOR_TEST_PROMPT || 'What is 2+2? Reply with just the number.';
        const outputFile = process.env.CURSOR_TEST_OUTPUT_FILE || '/tmp/cursor-prompt-result.json';
        const waitForLogin = process.env.CURSOR_TEST_WAIT_LOGIN === '1';
        const interactiveMode = process.env.CURSOR_TEST_INTERACTIVE === '1';
        const waitSeconds = parseInt(process.env.CURSOR_TEST_WAIT_SECONDS || '30', 10);
        console.log(`\n=== Sending prompt: "${prompt}" ===\n`);
        // If waiting for login, give user time to complete it
        if (waitForLogin) {
            console.log('Waiting 2 minutes for user to complete login...');
            await delay(120000);
        }
        const results = {};
        // Try various methods to send the prompt
        const methods = [
            {
                name: 'composer.openComposer + focusComposer + type',
                fn: async () => {
                    // Open the composer pane
                    console.log('Step 1: Opening composer...');
                    await vscode.commands.executeCommand('composer.openComposer');
                    await delay(1500);
                    // Switch to agent mode
                    console.log('Step 2: Switching to agent mode...');
                    await vscode.commands.executeCommand('composerMode.agent');
                    await delay(500);
                    // Focus the composer input
                    console.log('Step 3: Focusing composer input...');
                    await vscode.commands.executeCommand('composer.focusComposer');
                    await delay(500);
                    // Focus again to be sure
                    await vscode.commands.executeCommand('composer.focusComposer');
                    await delay(500);
                    // Type the prompt character by character (works with webviews better)
                    console.log('Step 4: Typing prompt via type command...');
                    await vscode.commands.executeCommand('type', { text: prompt });
                    await delay(500);
                    // Submit with Enter
                    console.log('Step 5: Submitting with Enter...');
                    await vscode.commands.executeCommand('type', { text: '\n' });
                }
            },
            {
                name: 'composer.newAgentChat + clipboard',
                fn: async () => {
                    console.log('Step 1: Opening new agent chat...');
                    await vscode.commands.executeCommand('composer.newAgentChat');
                    await delay(2000);
                    console.log('Step 2: Focusing...');
                    await vscode.commands.executeCommand('composer.focusComposer');
                    await delay(1000);
                    console.log('Step 3: Writing to clipboard...');
                    await vscode.env.clipboard.writeText(prompt);
                    console.log('Step 4: Executing paste...');
                    await vscode.commands.executeCommand('editor.action.clipboardPasteAction');
                    await delay(500);
                    console.log('Step 5: Submitting...');
                    await vscode.commands.executeCommand('type', { text: '\n' });
                }
            },
        ];
        // Only run the first method that works
        for (const method of methods) {
            console.log(`Trying: ${method.name}`);
            try {
                await method.fn();
                results[method.name] = 'SUCCESS - command executed';
                console.log(`  Result: SUCCESS`);
                // Wait to see the response
                if (interactiveMode) {
                    console.log(`Interactive mode: keeping Cursor open for ${waitSeconds} seconds...`);
                    console.log('Use this time to inspect the UI and test interactions.');
                    await delay(waitSeconds * 1000);
                }
                else {
                    console.log(`Waiting ${waitSeconds} seconds for agent response...`);
                    await delay(waitSeconds * 1000);
                }
                break;
            }
            catch (error) {
                results[method.name] = `FAILED: ${error}`;
                console.log(`  Result: FAILED - ${error}`);
            }
        }
        // Write results to file
        fs.writeFileSync(outputFile, JSON.stringify({
            prompt,
            results,
            timestamp: new Date().toISOString(),
            note: 'Check the Cursor UI to see if the prompt was sent'
        }, null, 2));
        console.log(`\n=== Results written to ${outputFile} ===`);
        console.log('Check the Cursor UI to see the results.');
        assert.ok(Object.values(results).some(r => r.includes('SUCCESS')), 'At least one method should succeed');
    });
});
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
