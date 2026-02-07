# Cursor

## Overview

Cursor provides both an IDE and a standalone CLI agent. These are independent products with different capabilities:

- **Cursor IDE** (Cursor 1.7+): Comprehensive hooks support, full agent integration
- **Cursor CLI** (`cursor-agent` binary): No hooks support, limited configuration

Both support the Agent Skills specification natively.

**Universal-agents naming**: In universal-agents, we use `cursor-cli` and `cursor-ide` to distinguish between these two independent products (e.g., `./test-agents.sh cursor-cli`).

**AGENTS.md Support Status**:

| Feature | Cursor IDE | Cursor CLI |
|---------|------------|------------|
| 📄 **Basic support** | ✅ Reads root AGENTS.md | ❌ Not auto-loaded |
| 🪺 **Nested** | ❌ | ❌ |
| 🎯 **Selective** | ✅ (via CLAUDE.md mechanism) | ❌ |
| 🔧 **Skills** | ✅ Native | ✅ Native |

- **Cursor IDE**: Reads root-level AGENTS.md files automatically. Supports selective loading (same mechanism as CLAUDE.md). Does not support nested AGENTS.md files.
- **Cursor CLI**: AGENTS.md is **not preloaded in context automatically**. Users must manually reference the file in each conversation.

**Status**: Supported for Cursor IDE (via `sessionStart` hook). Cursor CLI not supported (no hooks).

## Configuration File Location

- **File**: `~/.cursor/cli-config.json`
- **Scope**: Global only (user-wide)

## Project-Level Configuration

Only **permissions** can be configured at the project level.
All other CLI settings must be set globally.

## Configuration Format

**Format**: JSON

### Example Structure

```json
{
  "version": 1,
  "editor": {
    "vimMode": false
  },
  "permissions": {
    "allow": ["Shell(ls)"],
    "deny": []
  }
}
```

## Hooks System

### IDE Hooks (Cursor 1.7+)

The Cursor IDE has comprehensive hooks support, but the CLI (`cursor-agent` binary) does **not** yet support hooks.

#### Available IDE Hook Events

| Event | Purpose |
|-------|---------|
| `beforeShellExecution` | Before shell command runs |
| `afterShellExecution` | After shell command completes |
| `beforeMCPExecution` | Before MCP tool call |
| `afterMCPExecution` | After MCP tool call |
| `beforeReadFile` | Before reading a file |
| `afterFileEdit` | After editing a file |
| `beforeSubmitPrompt` | Before prompt submission |
| `afterAgentResponse` | After agent responds |
| `afterAgentThought` | After agent thinking step |
| `stop` | When agent stops |

#### IDE Hook Configuration

- **Project**: `.cursor/hooks.json`
- **User**: `~/.cursor/hooks.json`

```json
// .cursor/hooks.json
{
  "stop": [
    {
      "command": "sh -c 'ln -sf ../.agents/skills .cursor/skills'"
    }
  ]
}
```

### CLI Hooks Status

**Not Available**: There is an [open feature request](https://forum.cursor.com/t/hooks-for-cursor-cli-aka-cursor-agent/137847) for hooks support in Cursor CLI.

### Self-Contained Integration

Cursor CLI **cannot be self-contained** currently due to lack of hooks. Must use:
- Manual symlink creation
- AGENTS.md auto-loading (built-in)

## Skills System

Cursor has native support for the [Agent Skills specification](https://agentskills.io).

### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Rules | `.cursor/rules/` | Project configuration rules |
| Skills | `.cursor/skills/` | Agent Skills spec support |
| Claude Compat | `.claude/skills/` | Also discovered |

### SKILL.md Format

```yaml
---
name: skill-name
description: Description of what this skill does
---

# Skill Instructions
Markdown body with procedural guidance...
```

### Custom Directory Configuration

No documented way to configure custom skill directories. Uses fixed paths (`.cursor/skills/`, `.cursor/rules/`).

## Rules Configuration

Cursor has a separate rules system for project configuration:

- **Project**: `.cursor/rules/*.mdc` files (new system)
- **Legacy**: `.cursorrules` in project root (deprecated)
- **Global**: User Rules via Cursor Settings

Rules are automatically loaded based on file patterns.

### Management

- `/rules` command for creating/editing rules

## Context Files

### Cursor IDE (as of Feb 2026)
- `AGENTS.md` - ✅ Root-level file automatically loaded
- `CLAUDE.md` - ✅ Automatically loaded with selective loading support
- `.cursor/rules/` - ✅ Automatically loaded rule files
- **Nested AGENTS.md**: ❌ Not supported - only root-level file is loaded

### Cursor CLI (as of Jan 2026)
- `AGENTS.md` - ❌ Not automatically loaded (must be manually referenced)
- `CLAUDE.md` - ❌ Not automatically loaded (must be manually referenced)
- `.cursor/rules/` - ✅ Automatically loaded rule files
- **Nested AGENTS.md**: ❌ Not supported

## Extension System

- **MCP Servers**: Supported
- **Rules**: `.cursor/rules/` directory
- **No plugin/extension system** for skill directories

## Local Settings Support

**Note**: Cursor CLI does NOT support `.local.json` variants.
Project-level configuration is limited to permissions only.

## Universal-Agents Integration

**Status**: Supported (Cursor IDE only; Cursor CLI lacks hooks)

**Cursor IDE** integration uses a `sessionStart` hook to polyfill nested AGENTS.md support:

- **AGENTS.md polyfill**: `.agents/polyfills/agentsmd/cursor-ide.sh` discovers all AGENTS.md files and injects them via JSON `additional_context`
- **Hook config**: `.cursor/hooks.json` configures the `sessionStart` hook
- **Skills**: `.cursor/skills/` symlinked to `../.agents/skills/` for native discovery
- **How it works**: The hook outputs `{"additional_context": "...", "continue": true}` — Cursor injects the string into agent context at session start

**Cursor CLI** cannot be integrated due to lack of hooks support ([open feature request](https://forum.cursor.com/t/hooks-for-cursor-cli-aka-cursor-agent/137847)).

## Sources

- [Cursor CLI Configuration Documentation](https://cursor.com/docs/cli/reference/configuration)
- [Using Agent in CLI | Cursor Docs](https://cursor.com/docs/cli/using)
- [Agent Skills | Cursor Docs](https://cursor.com/docs/context/skills)
- [Cursor Hooks Documentation](https://cursor.com/docs/agent/hooks)
- [Cursor 1.7 Adds Hooks - InfoQ](https://www.infoq.com/news/2025/10/cursor-hooks/)
- [How to Use Cursor 1.7 Hooks](https://skywork.ai/blog/how-to-cursor-1-7-hooks-guide/)
- [Deep Dive into Cursor Hooks | GitButler](https://blog.gitbutler.com/cursor-hooks-deep-dive)
- [Hooks for Cursor CLI Feature Request](https://forum.cursor.com/t/hooks-for-cursor-cli-aka-cursor-agent/137847)
- [Cursor Agent CLI](https://cursor.com/blog/cli)
- [Cursor CLI (Jan 8, 2026) Release](https://forum.cursor.com/t/cursor-cli-jan-8-2026/148374)
- [Support AGENTS.MD - Bug Report](https://forum.cursor.com/t/support-agents-md/133414) - User reports AGENTS.md not automatically loaded
