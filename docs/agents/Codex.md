# OpenAI Codex CLI

## Overview

OpenAI Codex CLI is OpenAI's command-line coding agent. It features full native support for the Agent Skills specification, a built-in skill installer, and environment variable configuration for custom skill directories.

**Status**: Not yet supported by agentfill install script

## Configuration File Location

- **File**: `~/.codex/config.toml`
- **Scope**: Global only (user-wide)
- **Shared**: CLI and IDE extension use the same config file

## Configuration Format

**Format**: TOML

### Example Structure

```toml
[features]
shell_snapshot = true
web_search_request = true

[analytics]
enabled = true

[tui]
scroll_speed = 1.0

[profiles.default]
model = "gpt-4"
provider = "openai"

[approval]
policy = "prompt"

[sandbox]
mode = "container"
```

### Key Configuration Sections

1. **Features**: Enable/disable CLI features
2. **Analytics**: Control analytics behavior
3. **TUI**: Terminal UI settings (scroll behavior, etc.)
4. **Profiles**: Model and provider configuration
5. **Approval**: Approval policies for commands
6. **Sandbox**: Shell environment policies

## Command-Line Overrides

Any `-c key=value` overrides passed at the command line take precedence for that invocation:
```sh
codex -c features.shell_snapshot=false
```

## Project-Level Configuration

**Note**: Codex natively only supports global configuration in `~/.codex/config.toml`.

There is no documented project-level config file support.

## Hooks System

Codex CLI has **limited hook support** - primarily through the `notify` configuration.

### Available Events

| Event | Purpose |
|-------|---------|
| `agent-turn-complete` | When agent completes a turn (via notify) |

**Note**: No SessionStart/SessionEnd hooks are documented.

### Notify Configuration

```toml
# ~/.codex/config.toml
notify = ["bash", "-lc", "/path/to/script.sh"]
```

The notify script receives JSON with thread ID, turn ID, working directory, and message content. This is primarily for notifications, not setup tasks.

### Self-Contained Integration

Codex **cannot be fully self-contained** via hooks. No startup hook exists to automatically create symlinks. Options include:
- Manual symlink creation
- Shell wrapper script
- `$CODEX_HOME` environment variable

## Skills System

OpenAI Codex CLI has **full native support** for the [Agent Skills specification](https://agentskills.io).

### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| System Skills | `~/.codex/skills/.system/` | OpenAI-shipped (plan, skill-creator) |
| User Skills | `~/.codex/skills/` | Personal, cross-project |
| Repo Skills | `.codex/skills/` | Version-controlled, team-shared |

Codex discovers skills by scanning for any `SKILL.md` file within the skills directories.

### Custom Directory via Environment Variable

The `CODEX_HOME` environment variable controls the base directory (defaults to `~/.codex`). Skills are then stored in `$CODEX_HOME/skills/`.

```sh
export CODEX_HOME=/custom/path
# Skills go in /custom/path/skills/
```

This is the **only agent** with environment variable configuration for skill location.

**Note**: This is global, not project-scoped.

### SKILL.md Format

```yaml
---
name: skill-name
description: Description of what this skill does
---

# Skill Instructions
Markdown body with procedural guidance...
```

### Skill Installation

Codex has a built-in `$skill-installer` skill that can install from:
- Curated GitHub repository (openai/skills)
- Any GitHub URL (public or private repos)
- Local paths (manual installation by copying)

```sh
# Install from GitHub
$skill-installer install https://github.com/openai/skills/tree/main/skills/create-plan

# Manual local install: just copy folder with SKILL.md to ~/.codex/skills/
```

### Discovery and Invocation

- **Explicit**: `/skills` command or `$` prefix to mention a skill
- **Implicit**: Codex autonomously activates skills based on task matching description

## Extension System

- **MCP Servers**: Supported for tool extensions
- **No plugin system**: Unlike Claude/Gemini
- **`$CODEX_HOME` Environment Variable**: Controls base directory

## Future Integration

When agentfill adds Codex support, it will likely:
- Create TOML-specific utilities for config merging
- Support global mode primarily
- Use symlinks: `ln -s .agents/skills .codex/skills`
- Document `CODEX_HOME` approach as an alternative

## Sources

- [Codex CLI Documentation](https://developers.openai.com/codex/cli/)
- [Agent Skills - OpenAI Codex](https://developers.openai.com/codex/skills)
- [Create Skills - OpenAI Codex](https://developers.openai.com/codex/skills/create-skill/)
- [Codex CLI Features](https://developers.openai.com/codex/cli/features/)
- [Advanced Configuration](https://developers.openai.com/codex/config-advanced/)
- [GitHub Repository](https://github.com/openai/codex)
- [openai/skills GitHub](https://github.com/openai/skills)
- [Skills in OpenAI Codex (blog)](https://blog.fsck.com/2025/12/19/codex-skills/)
- [skill-installer | DeepWiki](https://deepwiki.com/openai/skills/7.2-skill-installer)
- [Hook Feature Request Discussion #2150](https://github.com/openai/codex/discussions/2150)
- [Comprehensive Setup Guide](https://smartscope.blog/en/generative-ai/chatgpt/openai-codex-cli-comprehensive-guide/)
