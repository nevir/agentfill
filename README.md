# Universal AGENTS.md Support

One install script. Full-featured [AGENTS.md](https://agents.md) support for all your AI coding agents.

Stop maintaining CLAUDE.md, GEMINI.md, .cursorrules, and other agent-specific config files. Write AGENTS.md once, use it everywhere.

## Quick Start

```bash
# Install for current project
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh

# Or install globally for all projects
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh -s -- --global

# Or install for local user only
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh -s -- --local
```

See [Installation Options](#installation-options) for details on each mode.

## Why Universal Agents?

Most AI coding agents have incomplete or broken AGENTS.md support. You're stuck either:
- Maintaining separate config files for each agent (CLAUDE.md, GEMINI.md, .cursorrules, etc.)
- Using symlinks that break on Windows and don't support nested/selective loading
- Using sync tools that require running commands after every config change

**Universal Agents fixes this** by implementing the full AGENTS.md specification through agent-native mechanisms (hooks and config), with no file duplication or sync steps required.

## What You Get

Full-featured [AGENTS.md](https://agents.md) support for all configured agents:

✅ **📄 Basic support**: Agents automatically read AGENTS.md files instead of (or in addition to) their proprietary formats

✅ **🪺 Nested hierarchy**: Nested AGENTS.md files apply with proper precedence (closer = higher priority)

✅ **🎯 Selective loading**: Only loads relevant AGENTS.md files for your working directory (essential for monorepos)

✅ **🔧 Skills support**: Unified `.agents/skills/` directory shared across all agents

✅ **🔄 Hot reload**: Changes apply immediately, no rebuild or sync step needed

## Supported Agents

| Agent | Status | What Universal Agents Provides |
|-------|--------|-------------------------------|
| **Claude Code** | ✅ Fully Supported | SessionStart hook implementing all features (basic, nested, selective) |
| **Gemini CLI** | ✅ Fully Supported | Config modification to include AGENTS.md alongside GEMINI.md |
| **Cursor** | 📋 Planned | Hook-based implementation (contributions welcome) |
| **Aider** | 📋 Planned | Config-based implementation (contributions welcome) |

<details>
<summary>📊 Native Agent Support Comparison</summary>

Out of the box, most agents have incomplete or missing AGENTS.md support:

| Feature | Claude Code | Gemini CLI | After Universal Agents |
|---------|-------------|-----------|----------------------|
| 📄 **Basic support** | ❌ | ⚠️ [Configurable](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) | ✅ Both agents |
| 🪺 **Nested** | ❌ | ✅ | ✅ Both agents |
| 🎯 **Selective** | ❌ | ✅ | ✅ Both agents |
| 🔧 **Skills** | ✅ [Native](https://agentskills.io) | ⚠️ [Experimental](https://geminicli.com/docs/cli/skills/) | ✅ Unified `.agents/skills/` |

</details>

## Philosophy

- **No rebuild step** - Edit config files, they just work. No commands to run after changes.
- **Single source of truth** - `.agents/` is the canonical location for all agent configuration.
- **Native behavior** - Leverage each agent's built-in features (hot reload, skill discovery, etc.)
- **Simple and portable** - Shell scripts only. Works everywhere with minimal dependencies.

## How It Works

Universal Agents uses each agent's native extension mechanisms to add AGENTS.md support:

### Claude Code
- Adds a **SessionStart hook** to `.claude/settings.json`
- Hook script discovers all AGENTS.md files in your project
- Injects dynamic instructions for nested and selective loading
- Automatically loads root AGENTS.md if present
- No CLAUDE.md files needed, no symlinks required

### Gemini CLI
- Modifies `.gemini/settings.json` to include AGENTS.md in `context.fileName`
- Leverages Gemini's native nested and selective loading capabilities
- AGENTS.md works alongside GEMINI.md (or replaces it)

### Skills
- Creates `.agents/skills/` as the single source of truth
- Symlinks it to each agent's native skills directory (e.g., `.claude/skills/`)
- Enables native skill discovery and hot reloading
- Skills work across all configured agents

## Installation Options

The install script supports three modes:

### Project Mode (Default)
```bash
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh
# or explicitly:
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh -s -- --project
```
- Configures agents in the current project only
- Modifies `.claude/settings.json` and `.gemini/settings.json`
- Creates `.agents/` directory in project root
- Best for: Single projects, team environments

### Local Mode
```bash
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh -s -- --local
```
- Configures agents in `~/.claude-local/` and `~/.gemini-local/`
- User-specific settings that don't affect project configs
- Best for: Personal overrides, local development preferences

### Global Mode
```bash
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh -s -- --global
```
- Configures agents in `~/.claude/` and `~/.gemini/`
- Applies to all projects for your user
- Best for: Individual developers who want AGENTS.md everywhere
- Note: Restart your agent session after first global install

### Combining Modes
You can use multiple modes together. Settings are applied in order of precedence:
1. Project settings (highest priority)
2. Local settings
3. Global settings (lowest priority)

## Usage

Create AGENTS.md files anywhere in your project. They'll be loaded automatically with proper scoping:

```
project/
├── AGENTS.md                    # Project-wide rules
├── .agents/
│   └── skills/                  # Shared skills directory
│       └── my-skill/
│           └── SKILL.md
└── src/
    ├── frontend/
    │   └── AGENTS.md            # Frontend-specific rules
    └── backend/
        ├── AGENTS.md            # Backend-specific rules
        └── api/
            └── AGENTS.md        # API-specific rules (highest precedence)
```

### How Loading Works

**Nested Hierarchy (🪺)**: When working in `src/backend/api/`, the agent loads:
1. Root `AGENTS.md` (project-wide rules)
2. `src/backend/AGENTS.md` (backend rules, overrides root)
3. `src/backend/api/AGENTS.md` (API rules, overrides backend and root)

The closer the AGENTS.md file is to your working location, the higher its precedence.

**Selective Loading (🎯)**: Only loads AGENTS.md files in the directory hierarchy for your current working location. If you're working in `src/frontend/`, it won't load `src/backend/AGENTS.md` or `src/backend/api/AGENTS.md`, keeping context focused and token usage efficient.

### Example Use Cases

**Monorepo with multiple teams**:
```
monorepo/
├── AGENTS.md                    # Org-wide standards
├── packages/
│   ├── mobile-app/
│   │   └── AGENTS.md            # Mobile team preferences (React Native, TypeScript)
│   └── web-app/
│       └── AGENTS.md            # Web team preferences (Next.js, Tailwind)
```

**Polyglot codebase**:
```
project/
├── AGENTS.md                    # General project context
├── python-backend/
│   └── AGENTS.md                # Python style guide, Django patterns
└── rust-services/
    └── AGENTS.md                # Rust conventions, error handling patterns
```

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

## Comparison with Alternatives

Universal Agents takes a different approach compared to other solutions in the ecosystem:

| Approach | How It Works | Pros | Cons |
|----------|-------------|------|------|
| **Universal Agents** | Hook-based polyfill | ✅ No file duplication<br>✅ No sync step<br>✅ Full spec (nested + selective) | ⚠️ Limited agent support (2 currently) |
| **[Ruler](https://github.com/intellectronica/ruler)** | Centralized generation | ✅ Many agents supported<br>✅ Skills system | ❌ Must run sync command<br>❌ Duplicate files |
| **[OpenSkills](https://github.com/numman-ali/openskills)** | Package manager | ✅ Share/reuse capabilities<br>✅ Version control | ❌ Different abstraction<br>❌ Node.js required |
| **Symlinks** | File system links | ✅ Simple<br>✅ No tools | ❌ Windows issues<br>❌ No nested/selective |

**When to use Universal Agents**:
- You primarily use Claude Code or Gemini CLI
- You want AGENTS.md-only repos (no CLAUDE.md, etc.)
- You need selective loading for monorepos
- You want zero-maintenance (no sync step)

**When to consider alternatives**:
- You use many different agents → [Ruler](https://github.com/intellectronica/ruler)
- You want shareable skill packages → [OpenSkills](https://github.com/numman-ali/openskills)
- You need a quick temporary solution → Symlinks

See [docs/Comparison.md](docs/Comparison.md) for detailed analysis of the ecosystem.

## Documentation

- **[docs/AGENTS.md](docs/AGENTS.md)** - Documentation index and formatting guidelines
- **[docs/Comparison.md](docs/Comparison.md)** - Comprehensive comparison with Ruler, OpenSkills, and other solutions
- **[docs/agents/Claude.md](docs/agents/Claude.md)** - Claude Code configuration reference
- **[docs/agents/Gemini.md](docs/agents/Gemini.md)** - Gemini CLI configuration reference

## Troubleshooting

### Skills not showing up?

**Check the symlink**:
```bash
ls -la .claude/skills  # Should show: .claude/skills -> ../.agents/skills
```

**Restart your agent session**: Skills are loaded at session start, so restart after adding new skills.

**Claude Code display bug**: The `/skills` command may not show skills in symlinked directories ([known issue](https://github.com/anthropics/claude-code/issues/14836)), but the skills still work. Try invoking them directly to verify.

### "Warning: directory exists" during install

This means you have existing skills or config that would be overwritten.

**Solution**:
```bash
# Move existing skills to the unified directory
mv .claude/skills/* .agents/skills/
rmdir .claude/skills

# Re-run the install
curl -fsSL https://raw.githubusercontent.com/agentsmd/universal-agents/main/install.sh | sh
```

### AGENTS.md not being loaded

**For Claude Code**:
1. Check that `.claude/settings.json` contains a `SessionStart` hook
2. Verify the hook script exists in `.claude/hooks/SessionStart/`
3. Try restarting your Claude session

**For Gemini CLI**:
1. Check that `.gemini/settings.json` includes AGENTS.md in `context.fileName`
2. Verify the file: `cat .gemini/settings.json | grep AGENTS.md`

**Check your mode**: If you installed globally but expected project-level config (or vice versa), the settings may be in a different location.

### Global install not taking effect

**After first global install**: You must restart your agent session for the global hooks to activate.

**Check global config**:
```bash
cat ~/.claude/settings.json    # Global Claude settings
cat ~/.gemini/settings.json    # Global Gemini settings
```

### Uninstalling

To remove Universal Agents configuration:

**Project mode**:
```bash
rm -rf .agents/
rm .claude/hooks/SessionStart/universal-agents.sh
# Manually remove SessionStart hook from .claude/settings.json
# Manually remove AGENTS.md from .gemini/settings.json
```

**Global mode**:
```bash
rm -rf ~/.agents/
rm ~/.claude/hooks/SessionStart/universal-agents.sh
# Manually remove SessionStart hook from ~/.claude/settings.json
# Manually remove AGENTS.md from ~/.gemini/settings.json
```

## Contributing

We welcome contributions! Here are some ways you can help:

### Add Support for More Agents

Current priority agents for implementation:
- **Cursor** ([docs/agents/Cursor.md](docs/agents/Cursor.md) has research)
- **Aider** ([docs/agents/Aider.md](docs/agents/Aider.md) has research)
- **Codex/OpenAI** ([docs/agents/Codex.md](docs/agents/Codex.md) has research)

See [docs/agents/](docs/agents/) for existing research on these agents.

### Improve Documentation

- Share your AGENTS.md patterns and use cases
- Document edge cases or configuration issues
- Add examples for different project types

### Report Issues

- [Open an issue](https://github.com/agentsmd/universal-agents/issues) for bugs or feature requests
- Share feedback on the hook implementation
- Suggest improvements to the install script

### Philosophy

When contributing, please follow the project philosophy:
- **Use native mechanisms**: Hooks, config files, not wrappers
- **No file duplication**: Implement the spec, don't generate files
- **Portable shell**: POSIX sh, minimal dependencies
- **Respect conventions**: Follow the shell script style guide in [AGENTS.md](AGENTS.md)

## License

This project is licensed under the [Blue Oak Model License, Version 1.0.0](LICENSE.md), but you may also license it under [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0) if you—or your legal team—prefer.
