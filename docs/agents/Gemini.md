# Gemini CLI

## Overview

Gemini CLI is Google's command-line interface for Gemini. It features a comprehensive hooks system, native Agent Skills support (experimental), and a robust extension system for extensibility.

## Environment Variables

Gemini CLI supports environment variable configuration but does not set specific detection variables.

### Configuration Override Variables

| Variable | Purpose |
|----------|---------|
| `GEMINI_CLI_SYSTEM_DEFAULTS_PATH` | Override system defaults location |
| `GEMINI_CLI_SYSTEM_SETTINGS_PATH` | Override system settings location |

**Note**: These variables are typically used for testing or custom deployments, not for general detection.

### Detection Pattern

Gemini CLI does not set a dedicated environment variable to indicate it's running. Detection is unreliable and not recommended.

### Environment Variable Interpolation

String values in `settings.json` can reference environment variables:

```json
{
	"customPath": "$HOME/.agents/custom",
	"anotherPath": "${PROJECT_ROOT}/config"
}
```

Variables are resolved using `$VAR_NAME` or `${VAR_NAME}` syntax when settings are loaded.

## Configuration File Locations

Gemini CLI uses a four-tier configuration system:

### System Defaults
- **File**: `/etc/gemini-cli/system-defaults.json` (Linux)
- **File**: `C:\ProgramData\gemini-cli\system-defaults.json` (Windows)
- **File**: `/Library/Application Support/GeminiCli/system-defaults.json` (macOS)
- **Scope**: System-wide default settings
- **Override**: Can be overridden via `GEMINI_CLI_SYSTEM_DEFAULTS_PATH` env var

### Global Settings
- **File**: `~/.gemini/settings.json`
- **Scope**: User-specific, applies to all projects
- **Use**: Personal preferences

### Project Settings
- **File**: `.gemini/settings.json`
- **Scope**: Project-specific
- **Use**: Team-wide project configuration

### System Overrides
- **File**: `/etc/gemini-cli/settings.json` (Linux)
- **File**: `C:\ProgramData\gemini-cli\settings.json` (Windows)
- **File**: `/Library/Application Support/GeminiCli/settings.json` (macOS)
- **Scope**: System-wide overrides (highest precedence)
- **Override**: Can be overridden via `GEMINI_CLI_SYSTEM_SETTINGS_PATH` env var

## Settings Hierarchy

Settings are applied in order of precedence (highest to lowest):
1. System overrides (`/etc/gemini-cli/settings.json`)
2. Project (`.gemini/settings.json`)
3. User (`~/.gemini/settings.json`)
4. System defaults (`/etc/gemini-cli/system-defaults.json`)

## Configuration Format

**Format**: JSON

### Example Settings Structure

```json
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  },
  "model": "gemini-2.0-flash-exp",
  "git": {
    "respectGitignore": true
  }
}
```

## Environment Variable Interpolation

String values in `settings.json` can reference environment variables:
- `$VAR_NAME` or `${VAR_NAME}` syntax
- Variables are resolved when settings are loaded

## Local Settings Support

**Note**: Gemini CLI does NOT natively support `.gemini/settings.local.json` files.

The documented hierarchy only includes the four tiers listed above. Unlike Claude Code, there is no auto-merging of `.local.json` variants.

## Hooks System

Gemini CLI has a comprehensive hooks system with many lifecycle events.

### Available Hook Events

| Event | Purpose |
|-------|---------|
| `SessionStart` | When a session begins - initialize resources |
| `SessionEnd` | When a session ends - cleanup |
| `BeforeAgent` | After user input, before planning |
| `AfterAgent` | When agent loop concludes |
| `BeforeModel` | Before sending request to LLM |
| `AfterModel` | After receiving LLM response |
| `BeforeToolSelection` | Before tool selection |
| `BeforeTool` | Before a tool executes |
| `AfterTool` | After a tool executes |
| `PreCompress` | Before context compression |
| `Notification` | When notifications occur |

### Hook Configuration

Hooks can be configured in `settings.json` or within extensions:

```json
// .gemini/settings.json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "sh -c 'mkdir -p .gemini && ln -sf ../.agents/skills .gemini/skills 2>/dev/null || true'"
      }
    ]
  }
}
```

For extensions, hooks are defined in `hooks/hooks.json`:

```json
// hooks/hooks.json (within extension directory)
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "node ${extensionPath}/setup.js",
        "name": "Setup Skills Symlink"
      }
    ]
  }
}
```

**Note**: Hooks are defined in `hooks/hooks.json`, NOT in `gemini-extension.json`.

### Self-Contained Integration

Gemini CLI can be fully self-contained via SessionStart hooks that auto-create symlinks for skill directories.

## Skills System

Gemini CLI added Agent Skills support in **v0.23.0** as an experimental feature, based on the [Agent Skills specification](https://agentskills.io).

### Enabling Skills

Skills are **disabled by default**. Enable via:
- `experimental.skills: true` in `~/.gemini/settings.json`
- Toggle in `/settings` interactive UI (search for "Skills")

### Skill Locations

Three discovery tiers with precedence (Project > User > Extension):

| Location | Path | Scope |
|----------|------|-------|
| Project Skills | `.gemini/skills/` | Version-controlled, team-shared |
| User Skills | `~/.gemini/skills/` | Personal, cross-project |
| Extension Skills | Within installed extensions | Extension-bundled |

### SKILL.md Format

```yaml
---
name: skill-name
description: Description of what this skill does
---

# Skill Instructions
Markdown body with procedural guidance...
```

### Skill Discovery and Activation

1. System scans enabled skills at session start
2. Only **metadata** (name/description) is initially loaded (~100 tokens)
3. Model autonomously identifies relevant skills based on task
4. Model calls `activate_skill` tool
5. User receives confirmation prompt (name, purpose, directory path)
6. Upon approval: full SKILL.md content loaded into conversation
7. Skill directory granted as allowed file path for asset access

### Management Commands

- `/skills list` - View discovered skills
- `/skills enable/disable <name>` - Toggle skill usage
- `/skills reload` - Refresh skill discovery

## Extension System

Gemini CLI has a robust extension system using `gemini-extension.json` manifests.

### Extension Structure

```
my-extension/
├── gemini-extension.json    # Manifest
├── hooks/
│   └── hooks.json           # Hook definitions
├── GEMINI.md                # Context file
└── scripts/                 # Optional scripts
```

### gemini-extension.json Fields

- `name`: Extension identifier
- `version`: Version number
- `mcpServers`: MCP server configurations
- `contextFileName`: Context file (defaults to GEMINI.md)
- `excludeTools`: Tools to block
- `settings`: User-configurable options

### Extension Installation

```sh
# From GitHub
gemini extensions install https://github.com/user/repo

# From local path
gemini extensions install /path/to/extension

# Development linking (symlink-based)
gemini extensions link /path/to/dev/extension
```

### Skills via Extension

The [gemini-cli-skillz](https://github.com/intellectronica/gemini-cli-skillz) extension allows custom skill directories:

```json
// ~/.gemini/extensions/skillz/gemini-extension.json
{
  "mcpServers": {
    "skillz": {
      "command": "uvx",
      "args": [
        "skillz@latest",
        "/absolute/path/to/your/skills",
        "--verbose"
      ]
    }
  }
}
```

This allows sharing the same skills directory between Claude Code and Gemini CLI without copying files.

## GEMINI.md Context Files

Gemini supports context files similar to CLAUDE.md:

| Location | Scope |
|----------|-------|
| `~/.gemini/GEMINI.md` | Global, all projects |
| `./GEMINI.md` + parent directories | Project-level |
| Subdirectory GEMINI.md files | Module-specific |

### Custom Filename Support

Configure custom context filenames via `context.fileName`:

```json
{
  "context": {
    "fileName": ["AGENTS.md", "CONTEXT.md", "GEMINI.md"]
  }
}
```

### Import Syntax

Supports `@path/to/file.md` for modular context.

## AGENTS.md Integration

The agentfill install script configures Gemini CLI to load AGENTS.md files via the `context.fileName` setting, which tells Gemini to automatically include these files in the conversation context.

### Skills Integration

agentfill creates a symlink from `.gemini/skills/` to `.agents/skills/`, enabling:
- Shared skills directory across all configured agents
- Native Gemini CLI skill discovery (requires `experimental.skills: true`)

**Note**: Gemini CLI skills are experimental and must be explicitly enabled in settings.

## Sources

- [Gemini CLI Configuration Documentation](https://geminicli.com/docs/get-started/configuration/)
- [Agent Skills | Gemini CLI](https://geminicli.com/docs/cli/skills/)
- [Gemini CLI Hooks](https://geminicli.com/docs/hooks/)
- [Gemini CLI Extensions](https://geminicli.com/docs/extensions/)
- [Getting Started with Extensions](https://geminicli.com/docs/extensions/getting-started-extensions/)
- [GEMINI.md Files](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html)
- [gemini-cli-skillz Extension](https://github.com/intellectronica/gemini-cli-skillz)
- [Hooks System | DeepWiki](https://deepwiki.com/google-gemini/gemini-cli/3.10-hooks-system)
- [GitHub Configuration Guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/configuration.md)
- [Tutorial: Configuration Settings](https://medium.com/google-cloud/gemini-cli-tutorial-series-part-3-configuration-settings-via-settings-json-and-env-files-669c6ab6fd44)
