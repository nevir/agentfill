import * as assert from 'assert';
import * as vscode from 'vscode';
import * as fs from 'fs';

suite('Command Discovery', () => {
    test('Discover Cursor commands', async () => {
        const allCommands = await vscode.commands.getCommands(true);

        // Filter for relevant commands
        const cursorCommands = allCommands.filter(cmd =>
            cmd.toLowerCase().includes('cursor') ||
            cmd.toLowerCase().includes('chat') ||
            cmd.toLowerCase().includes('agent') ||
            cmd.toLowerCase().includes('composer') ||
            cmd.toLowerCase().includes('aichat')
        ).sort();

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
