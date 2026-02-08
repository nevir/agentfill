# agentfill

A "polyfill" that standardizes [AGENTS.md](https://agents.md) configuration and [Agent Skills](https://agentskills.io) support across Claude Code, Gemini CLI, Cursor, and beyond.

## One Install To Fill Them All

```sh
curl -fsSL https://agentfill.dev/install | sh
```

Most AI coding agents have incomplete or broken `AGENTS.md` support natively. agentfill polyfills that support so you can rely on consistent behavior, no matter which agent you use.

📄 **AGENTS.md support**: Agents automatically read `AGENTS.md` files instead of (or in addition to) their proprietary formats

🪺 **Nested precedence**: `AGENTS.md` files in subdirectories apply and layer with proper precedence (closer = higher priority)

🎯 **Selective loading**: Only loads relevant `AGENTS.md` files, not all of them (e.g. to minimize context bloat)

🔧 **Shared skills**: Store skills once in `.agents/skills/`, use across all agents

> [!NOTE]
>
> You can either install **globally** to get `AGENTS.md` support everywhere you use your agents, or **per-project** to check it into your repo so everyone on the team benefits.

## Philosophy

AI coding agents shouldn't fragment your configuration. This project enables:

- **Universal format** - Write `AGENTS.md` once, use it across major AI agents (Claude Code, Gemini CLI)
- **Standard locations** - `.agents/` and `AGENTS.md` files in predictable places, not scattered proprietary formats
- **No rebuild step** - Edit `AGENTS.md` files, they just work. No commands to run after changes.
- **Native behavior** - Leverage each agent's built-in features (hot reload, skill discovery, etc.)
- **Simple and portable** - Shell scripts only. Works everywhere with no dependencies.

## Native Support

Out of the box, most agents have incomplete or missing `AGENTS.md` support:

| Agent | 📄 Basic | 🪺 Nested | 🎯 Selective | 🔧 Skills |
|-------|----------|-----------|--------------|-----------|
| **Claude Code** | ❌ | ❌ | ❌ | ✅ [Native](https://agentskills.io) |
| **Gemini CLI** | ⚠️ [Configurable](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) | ✅ | ❌ | ⚠️ [Experimental](https://geminicli.com/docs/cli/skills/) |
| **Cursor IDE** | ✅ | ❌ | ✅ | ✅ [Native](https://cursor.com/docs/context/skills) |

## How It Works

**Claude Code:** A [SessionStart hook](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/hooks) discovers all `AGENTS.md` files in the project and injects them into context with precedence instructions. The root `AGENTS.md` is pre-loaded; nested files are loaded on-demand as Claude works in specific directories. Skills are symlinked from `.agents/skills/` to `.claude/skills/` for native discovery and hot reloading.

**Cursor IDE:** A [sessionStart hook](https://cursor.com/docs/agent/hooks) discovers all `AGENTS.md` files and injects them into context via JSON `additional_context`. The root `AGENTS.md` is pre-loaded; nested files are loaded on-demand as Cursor works in specific directories. Skills are symlinked from `.agents/skills/` to `.cursor/skills/` for native discovery.

**Gemini CLI:** Gemini's [`context.fileName`](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) setting is configured to load `AGENTS.md` alongside `GEMINI.md` - Gemini natively walks the directory tree and applies them with proper precedence, so no polyfill is needed for `AGENTS.md` loading. Skills are symlinked from `.agents/skills/` to `.gemini/skills/` for native discovery.

## Usage

Create `AGENTS.md` files anywhere in your project. They'll be loaded automatically with proper scoping:

```
project/
├── AGENTS.md              # Applies project-wide
└── src/
    └── api/
        └── AGENTS.md      # Applies to API work (overrides project-wide)
```

When working in `src/api/`, both `AGENTS.md` files apply - with the API-specific one taking precedence for conflicts (🪺 **nested**).

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

## License

This project is licensed under the [Blue Oak Model License, Version 1.0.0](LICENSE.md), but you may also license it under [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0) if you—or your legal team—prefer.
