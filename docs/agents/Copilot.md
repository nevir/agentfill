# GitHub Copilot CLI

## Overview

GitHub Copilot CLI is GitHub's command-line coding agent. It features full Agent Skills support (announced December 2025), custom agents, and automatic loading of cross-agent context files including `AGENTS.md` and `.claude/skills/`.

**Status**: Not yet supported by universal-agents install script

## Configuration File Location

- **File**: `~/.copilot/config.json`
- **File**: `~/.copilot/mcp-config.json` (MCP servers)
- **Scope**: Global (user-wide)

## Configuration Format

**Format**: JSON

### Example Structure

```json
// ~/.copilot/config.json
{
  "model": "gpt-4",
  "autoApprove": false
}
```

### MCP Configuration

```json
// ~/.copilot/mcp-config.json
{
  "servers": {
    "github": {
      "command": "gh",
      "args": ["mcp", "serve"]
    }
  }
}
```

## Hooks System

**No hooks system found.** Copilot CLI does not have documented lifecycle hooks for startup or other events.

### What Exists

- Session resume (`--resume`, `--continue` flags)
- Configuration files (`config.json`, `mcp-config.json`)
- No startup hook mechanism

### Self-Contained Integration

Copilot CLI **cannot be self-contained** via hooks. Must use:
- Manual symlink creation
- Leverage auto-loading of `.github/agents/` and AGENTS.md

## Skills System

GitHub Copilot has **full native support** for the [Agent Skills specification](https://agentskills.io) (announced December 2025).

### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Repository | `.github/skills/` | Version-controlled, team-shared |
| Claude Compat | `.claude/skills/` | Auto-discovered for cross-agent compatibility |
| User | `~/.copilot/skills/` | Personal, cross-project |

**Key Finding**: Copilot reads `.claude/skills/` automatically for cross-agent compatibility.

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

No documented way to configure custom skill directories. Uses fixed paths.

## Custom Agents

Copilot supports custom agents in addition to skills:

| Location | Path | Scope |
|----------|------|-------|
| User-level | `~/.copilot/agents/` | Personal agents |
| Repository-level | `.github/agents/` | Team-shared agents |
| Organization-level | `/agents` in `.github-private` repository | Org-wide agents |

## Context Files

Copilot automatically loads:

- `.github/copilot-instructions.md` - Primary instructions
- `.github/copilot-instructions/**/*.instructions.md` - Modular instructions
- `AGENTS.md` - Automatically loaded (cross-agent)

## Extension System

- **Pre-configured GitHub MCP server**: Built-in
- **Additional MCP servers**: Via `mcp-config.json` or `/mcp add`
- **Custom agents**: Via `.github/agents/` directory

## Future Integration

When universal-agents adds Copilot support, it will likely:
- Use symlinks to both `.github/skills/` and `.claude/skills/`
- Leverage native AGENTS.md auto-loading
- Potentially create custom agents at `.github/agents/`

## Sources

- [Using GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli)
- [About GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)
- [GitHub Copilot CLI Repository](https://github.com/github/copilot-cli)
- [Copilot CLI Changelog](https://github.com/github/copilot-cli/blob/main/changelog.md)
- [GitHub Copilot Agent Skills Changelog](https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/)
- [Agent Skills in GitHub Copilot | Stefan Stranger](https://stefanstranger.github.io/2025/12/29/AgentSkillsInGithubCopilot/)
- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [github/awesome-copilot](https://github.com/github/awesome-copilot)
