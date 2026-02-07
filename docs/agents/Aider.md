# Aider

## Overview

Aider is a terminal-based AI pair programming tool. It does **not** have a skills system comparable to the Agent Skills specification, but uses a conventions system (`read:`) for loading context files and coding standards.

**Status**: Not yet supported by agentfill install script

## Configuration File Locations

Aider looks for `.aider.conf.yml` files in multiple locations:

### Home Directory
- **File**: `~/.aider.conf.yml`
- **Scope**: User-wide, applies to all projects
- **Priority**: Lowest (loaded first)

### Git Repository Root
- **File**: `.aider.conf.yml`
- **Scope**: Project-wide, applies when running from within the git repo
- **Priority**: Medium (overrides home directory)

### Current Directory
- **File**: `.aider.conf.yml`
- **Scope**: Directory-specific
- **Priority**: Highest (overrides all others)

### Custom Config File
- **Flag**: `--config <filename>`
- **Behavior**: Only loads the specified file (bypasses default search)

## Settings Hierarchy

Files are loaded in order, with files loaded last taking priority:
1. Home directory (`~/.aider.conf.yml`)
2. Git repo root (`.aider.conf.yml`)
3. Current directory (`.aider.conf.yml`)

Later files override earlier ones.

## Configuration Format

**Format**: YAML

### Example Structure

```yaml
# Model configuration
model: gpt-4
edit-format: whole

# Files to include
read:
  - CONVENTIONS.md
  - AGENTS.md
  - README.md

# Editor settings
editor: vim

# Git settings
auto-commits: true
dirty-commits: false

# Linting
lint: true
```

### Alternative: .env Files

Aider also supports `.env` files for configuration via environment variables:
- `AIDER_MODEL=gpt-4`
- `AIDER_EDIT_FORMAT=whole`
- etc.

## Hooks System

**No hooks system.** Aider does not have lifecycle hooks for startup or other events.

## Skills System

**No Agent Skills support.** Aider does not recognize `SKILL.md` files or implement the Agent Skills specification.

### Conventions System (Alternative)

The closest analog to "skills" is Aider's **conventions** system using the `read:` directive:

```yaml
# .aider.conf.yml
read: CONVENTIONS.md
# Or multiple files:
read: [CONVENTIONS.md, CODING_STANDARDS.md, AGENTS.md]
```

This loads files as read-only context that guide the LLM's behavior.

### Potential Integration Approaches

While Aider doesn't support skills directly, you could:

1. **Use conventions**: Create a `SKILLS.md` conventions file that lists available skills and how to use them
2. **Prompt-based**: Include skill instructions in prompts manually
3. **AGENTS.md**: Configure Aider to read an AGENTS.md file via `read:` config

## Extension System

- **No plugin system**
- **No MCP support**
- **`read:` directive**: Only mechanism for loading additional context

## Local Settings Support

**Note**: Aider does NOT support `.aider.local.conf.yml` files.

There is no mechanism for:
- Config file inclusion
- Wildcard config file loading
- `.local` variants

The hierarchy-based loading (home -> git root -> current dir) provides the override mechanism.

## Future Integration

When agentfill adds Aider support, it will likely:
- Add AGENTS.md to the `read:` list in `.aider.conf.yml`
- Support project and global modes only (no local mode)
- Use YAML-specific merging utilities
- Note that skills would need to be documented in AGENTS.md rather than using SKILL.md files

## Sources

- [Aider Configuration Documentation](https://aider.chat/docs/config/aider_conf.html)
- [YAML Config File Guide](https://aider.chat/docs/config/aider_conf.html)
- [Specifying Coding Conventions | Aider](https://aider.chat/docs/usage/conventions.html)
- [Configuration System | DeepWiki](https://deepwiki.com/Aider-AI/aider/8.1-configuration-system)
- [Sample Configuration](https://github.com/Aider-AI/aider/blob/main/aider/website/assets/sample.aider.conf.yml)
