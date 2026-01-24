# Cursor IDE Test Harness

Test harness for running prompts through Cursor IDE using `@vscode/test-electron`.

## How It Works

This harness uses VS Code's test framework to launch Cursor with a test extension that can:

1. **Discover commands** - List all available VS Code/Cursor commands to find agent-related APIs
2. **Send prompts** - Attempt to send prompts to Cursor's agent and capture responses

Since Cursor is a VS Code fork, we can use `@vscode/test-electron` to launch it in test mode with our extension loaded.

## Usage

### Command Line

```sh
# Discover available commands
./cursor-prompt --discover

# Send a prompt
./cursor-prompt "What is the secret phrase?"

# Send prompt in specific workspace
./cursor-prompt "Hello" --workspace /path/to/project

# Read prompt from stdin (for test-agents.sh compatibility)
echo "What is the secret phrase?" | ./cursor-prompt
```

### From test-agents.sh

The `cursor-prompt` script is designed to work with the test harness:

```sh
# In test-agents.sh, add to agent_command():
cursor) echo "echo \"\$prompt\" | $SCRIPT_DIR/_support/cursor-ide/cursor-prompt --workspace \"\$temp_dir\"" ;;
```

## Architecture

```
cursor-ide/
├── cursor-prompt        # Shell wrapper for test-agents.sh
├── run-prompt.js        # Node.js launcher using @vscode/test-electron
├── package.json         # Node.js dependencies
└── extension/           # VS Code extension
    ├── package.json     # Extension manifest
    ├── tsconfig.json    # TypeScript config
    └── src/
        ├── extension.ts # Extension code
        └── test/
            └── suite/
                ├── index.ts         # Test suite runner
                └── discover.test.ts # Command discovery test
```

## Development

```sh
# Install dependencies
npm install
cd extension && npm install

# Compile extension
cd extension && npm run compile

# Run command discovery
./cursor-prompt --discover
```

## IPC Mechanism

The harness uses file-based IPC between the Node.js runner and the extension:

- `/tmp/cursor-test-prompt.txt` - Prompt to send
- `/tmp/cursor-test-response.txt` - Response from agent
- `/tmp/cursor-test-commands.json` - Discovered commands

Environment variables control extension behavior:
- `CURSOR_TEST_AUTO_DISCOVER=1` - Automatically run command discovery
- `CURSOR_TEST_AUTO_PROMPT=1` - Automatically send prompt from file

## Known Limitations

1. **Response capture is challenging** - Cursor's agent responses are async and go to the chat panel. We need to discover the right commands/APIs to capture them.

2. **Command discovery required** - Before we can reliably send prompts, we need to discover what commands Cursor exposes.

3. **May require Cursor-specific APIs** - Some features may not be accessible through standard VS Code extension APIs.

## Troubleshooting

### Cursor not found

Set the `CURSOR_PATH` environment variable:
```sh
export CURSOR_PATH="/Applications/Cursor.app/Contents/MacOS/Cursor"
```

### Extension doesn't compile

```sh
cd extension
rm -rf node_modules out
npm install
npm run compile
```
