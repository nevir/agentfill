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
├── TESTS.md                     # Test harness (run this to execute all tests)
├── tests/
│   └── [test directories]/      # Self-contained test cases
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

The test harness is located at [`TESTS.md`](./TESTS.md). Run it with your agent:

- `claude "$(cat TESTS.md)"`
- `aider --message "$(cat TESTS.md)"`
- `cursor-agent chat "$(cat TESTS.md)"`
- `codex "$(cat TESTS.md)"`
- `gemini "$(cat TESTS.md)"`

**Note:** All commands should be run from the repository root directory.

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
