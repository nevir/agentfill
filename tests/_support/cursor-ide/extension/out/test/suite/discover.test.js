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
suite('Command Discovery', () => {
    test('Discover Cursor commands', async () => {
        const allCommands = await vscode.commands.getCommands(true);
        // Filter for relevant commands
        const cursorCommands = allCommands.filter(cmd => cmd.toLowerCase().includes('cursor') ||
            cmd.toLowerCase().includes('chat') ||
            cmd.toLowerCase().includes('agent') ||
            cmd.toLowerCase().includes('composer') ||
            cmd.toLowerCase().includes('aichat')).sort();
        const outputFile = process.env.CURSOR_TEST_OUTPUT_FILE || '/tmp/cursor-commands.json';
        const result = {
            total: allCommands.length,
            cursorCommands,
            chatCommands: allCommands.filter(cmd => cmd.includes('chat')).sort(),
            agentCommands: allCommands.filter(cmd => cmd.includes('agent')).sort(),
        };
        fs.writeFileSync(outputFile, JSON.stringify(result, null, 2));
        console.log(`\n=== Cursor Commands (${cursorCommands.length}) ===`);
        cursorCommands.forEach(cmd => console.log(`  ${cmd}`));
        assert.ok(allCommands.length > 0, 'Should find some commands');
    });
});
