# Documentation Index

This directory contains reference documentation for AI coding agents and their configuration patterns.

## Directory Structure

```
docs/
├── AGENTS.md           # This file - index and guidelines
├── Agent Skills.md     # Best practices for writing portable agent skills
├── Comparison.md       # Comparison with similar projects
└── agents/             # Per-agent configuration references
    ├── Claude.md       # Claude Code configuration
    ├── Gemini.md       # Gemini CLI configuration
    ├── Cursor.md       # Cursor CLI configuration (future)
    ├── Aider.md        # Aider configuration (future)
    └── Codex.md        # OpenAI Codex configuration (future)
```

## Documentation

### Project Overview

- **[Agent Skills Best Practices](Agent%20Skills.md)** - Guide to writing portable agent skills:
  - **SKILL.md Format**: Frontmatter fields, body structure, directory layout
  - **Writing Skills**: Descriptions, instructions, progressive disclosure, workflow patterns
  - **Portability**: What's universal vs agent-specific, cross-agent best practices
  - **Development Process**: Iterative workflow for creating effective skills
  - **Ecosystem**: Specification, directories, community resources

- **[Comparison with Similar Projects](Comparison.md)** - Comprehensive analysis comparing universal-agents with similar projects and standards:
  - **Configuration Management Tools**: Ruler, OpenSkills, Symlinks, Codebase Context Specification
  - **Standards & Protocols**: AGENTS.md standard, MCP (Model Context Protocol), Agent2Agent, .aiignore
  - **Agent-Specific Systems**: Detailed coverage of 10+ coding agents (Continue.dev, Windsurf, Cline, Tabnine, Copilot, Replit Agent, OpenHands, Cody)
  - **Context Engineering**: Security considerations, best practices, and tooling
  - **Industry Trends**: Standardization efforts, emerging patterns, Linux Foundation initiatives

### Agent Documentation

#### Currently Supported
- **[Claude Code](agents/Claude.md)** - Full support (project + global modes)
- **[Gemini CLI](agents/Gemini.md)** - Full support (project + global modes)

#### Future Support
- **[Cursor CLI](agents/Cursor.md)** - Research complete, implementation pending
- **[Aider](agents/Aider.md)** - Research complete, implementation pending
- **[Codex](agents/Codex.md)** - Research complete, implementation pending

## Documentation Guidelines

### When to Update

**AI Agents should update these docs when:**
1. Learning new information about agent configuration
2. Discovering new features or settings
3. Finding corrections to existing documentation
4. Adding support for new agents

### How to Document

**Typical agent doc includes:**
- Configuration file locations (all supported paths)
- Settings hierarchy (order of precedence)
- Configuration format (JSON/YAML/TOML with examples)
- Local settings support (whether `.local` variants work)
- AGENTS.md integration (how the agent loads it)
- Sources (links to official documentation)

**Feel free to add other relevant information:**
- Special features or quirks
- Common gotchas or limitations
- Migration guides
- Advanced configuration patterns
- Environment variables
- Performance considerations
- Security best practices
- Anything else that would help future developers

### Suggested Content Structure

Agent documentation files should generally follow this structure:

1. H1: Agent name
2. Status note if not yet supported
3. Configuration details (file locations, hierarchy, format)
4. Examples
5. Sources at bottom

Organize information in whatever way makes it most useful and clear.

## For AI Agents

**Before making configuration changes:**
1. Read the relevant agent doc in `docs/agents/<Agent>.md`
2. Understand the config hierarchy and file locations
3. Respect the agent's native patterns

**After learning new information:**
1. Update the relevant doc in `docs/agents/`
2. Keep information accurate and current
3. Add sources for new information
