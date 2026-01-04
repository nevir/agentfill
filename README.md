# Universal AGENTS.md Polyfill

Universal AGENTS.md support for popular coding agents.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh
```

## Features

✨ **One-Command Setup** - Install and configure in seconds
🔧 **Smart Polyfills** - Implements AGENTS.md support via SessionStart hooks
📂 **Hierarchical Support** - Proper inheritance from nested AGENTS.md files
🔄 **Idempotent** - Safe to re-run, updates only what's needed

## Supported Agents

| Agent | Support Method |
|-------|----------------|
| **Claude Code** | SessionStart hook with inheritance logic |
| **Gemini CLI** | Native `context.fileName` configuration |

More agents coming soon.

## How It Works

The installer configures agents to support AGENTS.md ([learn more about the standard](https://agents.md)) - either through direct configuration or by adding polyfill hooks where native support is missing.

### For Claude Code

Installs a SessionStart hook that implements hierarchical AGENTS.md support:
- **On-demand loading** - Loads AGENTS.md files only as you work in relevant directories (minimizes context token usage)
- **Hierarchical inheritance** - Nested AGENTS.md files automatically apply with proper precedence
- **Root context** - Project-wide AGENTS.md loaded once at startup

### For Gemini

Updates `.gemini/settings.json` to include AGENTS.md in the context file list.

## Usage

After installation, just create an `AGENTS.md` file in your project root:

```bash
# AGENTS.md

This project uses TypeScript with strict mode enabled.
Always run `npm test` before committing.
```

Your AI agent will now automatically load and follow these instructions.

### Nested AGENTS.md

Create scoped instructions for specific directories:

```
project/
├── AGENTS.md                  # Applies to entire project
├── src/
│   └── api/
│       └── AGENTS.md          # Applies only to API code
```

More specific instructions override general ones.

## CLI Reference

```bash
./install.sh [OPTIONS] [PATH] [AGENTS...]

Options:
  -h, --help       Show help
  -y, --yes        Auto-confirm changes
  -n, --dry-run    Show planned changes without applying

Examples:
  ./install.sh                    # All agents, current directory
  ./install.sh claude             # Claude only
  ./install.sh /path/to/project   # All agents, specific path
  ./install.sh -n                 # Preview changes
```

## Testing

Verify AGENTS.md support is working:

```bash
./tests/test.sh              # Run all tests on all agents
./tests/test.sh claude       # Test Claude only
./tests/test.sh basic-load   # Run specific test
```

## Resources

- **AGENTS.md Spec**: https://agents.md
- **GitHub**: https://github.com/agentsmd/agents.md
- **Issues**: https://github.com/anthropics/claude-code/issues/6235

## License

MIT
