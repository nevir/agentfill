# Universal AGENTS.md Polyfill

A comprehensive example repository demonstrating how to configure popular AI coding agents to support the `AGENTS.md` standard.

## What is AGENTS.md?

`AGENTS.md` is an open format designed to provide AI coding agents with specific context and instructions they need to work on a project. It's currently used by over 60,000 open-source projects and is supported by tools like:

- **Aider** - AI pair programming in your terminal
- **Gemini CLI** - Google's AI coding assistant
- **Cursor** - AI-first code editor
- **OpenAI Codex** - OpenAI's coding agent
- **GitHub Copilot** - Microsoft's AI pair programmer
- And many more...

## Quick Start

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   cd universal-agents
   ```

2. **Choose your AI agent** and follow the configuration guide in `CONFIG_GUIDE.md`

3. **Test the configuration** using the test suite in `tests/`

## Repository Structure

```
universal-agents/
├── AGENTS.md                    # Example AGENTS.md with test cases
├── CLAUDE.md                    # Claude Code configuration (imports AGENTS.md)
├── .aider.conf.yml              # Aider configuration
├── .gemini/
│   └── settings.json            # Gemini CLI configuration
├── .claude/
│   ├── settings.json            # Claude Code SessionStart hook config
│   └── hooks/
│       └── append_agentsmd_context.sh
├── CONFIG_GUIDE.md              # Detailed configuration guide
├── tests/
│   ├── TESTS.md                 # Test harness (run this to execute all tests)
│   ├── secret-code/             # Test: Secret response verification
│   ├── file-creation/           # Test: File creation conventions
│   ├── repo-description/        # Test: Repository description priority
│   └── color-preference/        # Test: UI color preferences
└── README.md                    # This file
```

## Configuration by Agent

| Agent | Status | Config File | Details |
|-------|--------|-------------|---------|
| **Aider** | ✅ Supported | `.aider.conf.yml` | See [CONFIG_GUIDE.md](CONFIG_GUIDE.md#aider-configuration) |
| **Gemini CLI** | ✅ Supported | `.gemini/settings.json` | See [CONFIG_GUIDE.md](CONFIG_GUIDE.md#gemini-cli-configuration) |
| **Cursor/Codex** | ✅ Native | None required | See [CONFIG_GUIDE.md](CONFIG_GUIDE.md#cursorcodex-configuration) |
| **Claude Code** | ⚠️ Workaround | `CLAUDE.md` + hooks | See [CONFIG_GUIDE.md](CONFIG_GUIDE.md#claude-code-configuration) |

## Testing AGENTS.md Support

This repository includes a comprehensive test suite to verify that your AI agent correctly reads and follows `AGENTS.md` instructions.

### Running the Test Harness

The test harness is located at [`tests/TESTS.md`](./tests/TESTS.md). It contains self-contained prompts that verify AGENTS.md compliance without mentioning the file itself.

**Test with Claude Code:**
```bash
claude-code "Please read and execute the instructions in tests/TESTS.md"
```

**Test with Aider:**
```bash
aider --message "Please read and execute the instructions in tests/TESTS.md"
```

**Test with Cursor:**
Open the repository in Cursor and ask in chat:
```
Please read and execute the instructions in tests/TESTS.md
```

**Test with any agent:**
Simply provide the content of `tests/TESTS.md` as your initial prompt.

### Quick Verification

For a quick check, start your AI agent and ask:
```
What is the secret code?
```

**Expected response**: `AGENTS_MD_VERIFIED_42`

If you get this response, your agent is correctly reading `AGENTS.md`!

### What Gets Tested

- ✅ AGENTS.md file loading verification
- ✅ File creation conventions
- ✅ Repository description priority
- ✅ Project-specific UI preferences

## Contributing

This is an example repository demonstrating `AGENTS.md` configuration patterns. Contributions are welcome, especially:

- Additional agent configurations
- Improved test cases
- Better workarounds for agents without native support
- Documentation improvements

## Resources

- **AGENTS.md Specification**: https://agents.md
- **GitHub Repository**: https://github.com/agentsmd/agents.md
- **Claude Code Feature Request**: https://github.com/anthropics/claude-code/issues/6235

## License

MIT
