# Universal AGENTS.md Support

One install script. Full-featured [AGENTS.md](https://agents.md) support for all your AI coding agents.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh
```

## What This Does

Configures your installed AI coding agents with complete [AGENTS.md](https://agents.md) support:

📄 **Basic support**: Agents automatically read AGENTS.md files instead of (or in addition to) their proprietary formats

🪺 **Nested**: Nested AGENTS.md files apply with proper precedence (closer = higher priority)

🎯 **Selective**: Only loads relevant AGENTS.md files, not all of them (essential for large monorepos)

## Philosophy

- **No rebuild step** - Edit config files, they just work. No commands to run after changes.
- **Single source of truth** - `.agents/` is the canonical location for all agent configuration.
- **Native behavior** - Leverage each agent's built-in features (hot reload, skill discovery, etc.)
- **Simple and portable** - Shell scripts only. Works everywhere with no dependencies.

## Native Support

Out of the box, most agents have incomplete or missing AGENTS.md support:

| Feature | Claude Code | Cursor Agent | Gemini CLI |
|---------|-------------|--------------|------------|
| 📄 **Basic support** | ❌ | ✅ [Root only](https://cursor.com/docs/context/rules) | ⚠️ [Configurable](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) |
| 🪺 **Nested** | ❌ | ⚠️ [Broken](https://forum.cursor.com/t/nested-agents-md-files-not-being-loaded/138411) | ✅ |
| 🎯 **Selective** | ❌ | ❌ | ✅ |
| 🔧 **Skills** | ✅ [Native](https://agentskills.io) | ❌ | ⚠️ [Experimental](https://geminicli.com/docs/cli/skills/) |

## How It Works

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

## Skills

Store skills in `.agents/skills/` and they'll be available to all configured agents:

```
.agents/
└── skills/
    └── my-skill/
        └── SKILL.md
```

Skills are symlinked to each agent's native skills directory (e.g., `.claude/skills/`), enabling:
- Native skill discovery
- Hot reloading
- Cross-agent compatibility

See [Agent Skills Specification](https://agentskills.io/specification) for SKILL.md format.

## Troubleshooting

**Skills not showing up?**
- Check that the symlink exists (e.g., `.claude/skills` -> `../.agents/skills`)
- Try restarting the agent session
- Note: Claude Code's `/skills` command has a [display bug](https://github.com/anthropics/claude-code/issues/14836) with symlinked directories - skills still work

**"Warning: directory exists" during install?**
- Move existing skills from `.claude/skills/` to `.agents/skills/`
- Re-run the install script

**Global install first run?**
- After installing globally, restart your agent session for hooks to take effect

## License

This project is licensed under the [Blue Oak Model License, Version 1.0.0](LICENSE.md), but you may also license it under [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0) if you—or your legal team—prefer.
