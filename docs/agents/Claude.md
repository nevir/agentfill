# Claude Code

## Overview

Claude Code is Anthropic's official CLI for Claude. It features a comprehensive hooks system, native Agent Skills support, and a plugin mechanism for extensibility.

## Configuration File Locations

Claude Code uses a hierarchical settings system:

### Global Settings
- **File**: `~/.claude/settings.json`
- **Scope**: Applies to all projects for the current user
- **Use**: Personal preferences and defaults

### Project Settings (Shared)
- **File**: `.claude/settings.json`
- **Scope**: Project-specific, checked into source control
- **Use**: Team-wide configuration

### Project Settings (Local)
- **File**: `.claude/settings.local.json`
- **Scope**: Project-specific, git-ignored
- **Use**: User-specific overrides within the project
- **Merge Behavior**: Native auto-merging with `.claude/settings.json`

## Settings Hierarchy

Settings are applied in order of precedence (highest to lowest):
1. Managed settings (organizational policies)
2. Project-shared (`.claude/settings.json`)
3. Project-local (`.claude/settings.local.json`)
4. Global (`~/.claude/settings.json`)

## Configuration Format

**Format**: JSON

### Example Settings Structure

```json
{
  "model": "claude-sonnet-4-20250514",
  "maxTokens": 4096,
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.agents/polyfills/claude_agentsmd.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write(*.py)",
        "hooks": [
          {
            "type": "command",
            "command": "python -m black $file"
          }
        ]
      }
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1"
  }
}
```

## Hooks System

Claude Code has a comprehensive hooks system for lifecycle automation.

### Available Hook Events

| Event | Purpose |
|-------|---------|
| `SessionStart` | When a session begins - initialize resources |
| `Stop` | When session ends - cleanup |
| `PreToolUse` | Before a tool executes |
| `PostToolUse` | After a tool executes |
| `Notification` | When notifications occur |

### Hook Configuration

Hooks are configured in `settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write(*.py)",
        "hooks": [
          {
            "type": "command",
            "command": "python -m black $file"
          }
        ]
      }
    ]
  }
}
```

### Self-Contained Integration

Claude Code can be fully self-contained via SessionStart hooks. For example, to auto-link skills:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c 'mkdir -p .claude && ln -sf ../.agents/skills .claude/skills 2>/dev/null || true'"
          }
        ]
      }
    ]
  }
}
```

## Skills System

Claude Code has native support for the [Agent Skills specification](https://agentskills.io).

### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Project Skills | `.claude/skills/` | Version-controlled, team-shared |
| Personal Skills | `~/.claude/skills/` | Personal, cross-project |

**Note**: There is no setting to configure custom skill directories. Skills must reside in `.claude/skills/` or `~/.claude/skills/`.

### SKILL.md Format

```yaml
---
name: skill-name
description: A description of what this skill does and when to use it.
---

# Skill Instructions
Markdown instructions that Claude follows when the Skill is active.
```

### Hot Reloading (v2.1.0+)

As of Claude Code 2.1.0 (January 7, 2026):

> "Skills created or modified in `~/.claude/skills` or `.claude/skills` are now immediately available without restarting the session."

### Symlink Support

Symlinked skill directories have a known display bug (GitHub Issue #14836):
- The skill **is loaded and usable** by the model
- The `/skills` command doesn't list symlinked skills
- This is a display bug only, not a functional limitation

### Management Commands

- `/skills` - List available skills
- Skills are auto-discovered and activated based on task matching

## Plugin System

Claude Code supports plugins via the `.claude/plugins/` directory or configured in settings.json:

```json
{
  "plugins": [
    {
      "path": "/path/to/plugin"
    }
  ]
}
```

## CLAUDE.md Context Files

Claude Code automatically loads context from CLAUDE.md files:

| Location | Scope |
|----------|-------|
| `~/.claude/CLAUDE.md` | Global, all projects |
| `./CLAUDE.md` | Project-level |
| `./.claude/rules/` | Modular rule organization |

### Import Syntax

CLAUDE.md supports importing external files:

```markdown
@path/to/file.md
@~/.claude/shared-instructions.md
```

## AGENTS.md Integration

The universal-agents install script configures Claude Code to load AGENTS.md files via a SessionStart hook that:
1. Finds all AGENTS.md files in the project
2. Injects instructions for loading nested AGENTS.md files
3. Pre-loads root `./AGENTS.md` if it exists

### Skills Integration

Universal-agents creates a symlink from `.claude/skills/` to `.agents/skills/`, enabling:
- Shared skills directory across all configured agents
- Native Claude Code skill discovery
- Hot reloading of skill changes (v2.1.0+)

## Sources

- [Claude Code Settings Documentation](https://code.claude.com/docs/en/settings)
- [Claude Code Hooks Documentation](https://docs.anthropic.com/en/docs/claude-code/settings#hooks)
- [Agent Skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Claude Code Changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [Symlink Bug Issue #14836](https://github.com/anthropics/claude-code/issues/14836)
- [Configuration Guide](https://claudelog.com/configuration/)
- [Developer's Guide to settings.json](https://www.eesel.ai/blog/settings-json-claude-code)
- [Anthropic: Equipping Agents with Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
