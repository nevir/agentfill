# AGENTS.md for Popular Coding Agents

Full-featured AGENTS.md support for Claude Code, Gemini CLI, and more.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh
```

## What This Does

Configures your installed AI coding agents with complete [AGENTS.md](https://agents.md) support:

📄 **Basic support**: Agents automatically read AGENTS.md files instead of (or in addition to) their proprietary formats

🪺 **Nested**: Nested AGENTS.md files apply with proper precedence (closer = higher priority)

🎯 **Selective**: Only loads relevant AGENTS.md files, not all of them (essential for large monorepos)

### Native Support

Out of the box, most agents have incomplete or missing AGENTS.md support:

| Feature | Claude Code | Cursor Agent | Gemini CLI |
|---------|-------------|--------------|------------|
| 📄 **Basic support** | ❌ | ✅ [Root only](https://cursor.com/docs/context/rules) | ⚠️ [Configurable](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) |
| 🪺 **Nested** | ❌ | ⚠️ [Broken](https://forum.cursor.com/t/nested-agents-md-files-not-being-loaded/138411) | ✅ |
| 🎯 **Selective** | ❌ | ❌ | ✅ |

### How It Works

**Claude Code:** SessionStart hook that implements AGENTS.md with no CLAUDE.md files or symlinks needed

**Gemini CLI:** Native configuration pointing to AGENTS.md in addition to GEMINI.md

## Usage

Create AGENTS.md files anywhere in your project. They'll be loaded automatically with proper scoping:

```
project/
├── AGENTS.md              # Applies project-wide
└── src/
    └── api/
        └── AGENTS.md      # Applies to API work (overrides project-wide)
```

When working in `src/api/`, both AGENTS.md files apply - with the API-specific one taking precedence for conflicts (🪺 **nested**).

Agents load context only for the directories you're working in, keeping token usage efficient even in large projects (🎯 **selective**).

## License

This project is licensed under the [Blue Oak Model License, Version 1.0.0](LICENSE.md), but you may also license it under [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0) if you—or your legal team—prefer.
