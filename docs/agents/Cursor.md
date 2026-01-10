# Cursor

## Overview

Cursor provides both an IDE and a CLI (cursor-agent). The IDE (Cursor 1.7+) has comprehensive hooks support, while the CLI currently lacks hooks. Both support the Agent Skills specification natively and automatically load `AGENTS.md` and `CLAUDE.md` files.

**Status**: Not yet supported by universal-agents install script

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

The Cursor IDE has comprehensive hooks support, but the CLI (cursor-agent) does **not** yet support hooks.

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

Cursor automatically loads context from:
- `AGENTS.md` - Automatically loaded
- `CLAUDE.md` - Automatically loaded
- `.cursor/rules/` - Rule files

## Extension System

- **MCP Servers**: Supported
- **Rules**: `.cursor/rules/` directory
- **No plugin/extension system** for skill directories

## Local Settings Support

**Note**: Cursor CLI does NOT support `.local.json` variants.
Project-level configuration is limited to permissions only.

## Future Integration

When universal-agents adds Cursor support, it will likely:
- Configure permissions via project-level settings
- Use symlinks: `ln -s .agents/skills .cursor/skills`
- Leverage native AGENTS.md auto-loading

## Sources

- [Cursor CLI Configuration Documentation](https://cursor.com/docs/cli/reference/configuration)
- [Agent Skills | Cursor Docs](https://cursor.com/docs/context/skills)
- [Cursor Hooks Documentation](https://cursor.com/docs/agent/hooks)
- [Cursor 1.7 Adds Hooks - InfoQ](https://www.infoq.com/news/2025/10/cursor-hooks/)
- [How to Use Cursor 1.7 Hooks](https://skywork.ai/blog/how-to-cursor-1-7-hooks-guide/)
- [Deep Dive into Cursor Hooks | GitButler](https://blog.gitbutler.com/cursor-hooks-deep-dive)
- [Hooks for Cursor CLI Feature Request](https://forum.cursor.com/t/hooks-for-cursor-cli-aka-cursor-agent/137847)
- [Cursor Agent CLI](https://cursor.com/blog/cli)
- [January 2026 Update](https://forum.cursor.com/t/cursor-cli-jan-8-2026-new-commands-and-performance-improvement/148372)
