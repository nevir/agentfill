# agentfill: Comparison with Similar Projects

This document compares agentfill with similar projects in the AI coding agent configuration space, analyzing different approaches to solving the problem of fragmented agent configuration standards.

## Executive Summary

The AI coding agent ecosystem suffers from configuration fragmentation, with each tool requiring its own format (CLAUDE.md, .cursorrules, GEMINI.md, etc.). The **AGENTS.md** standard emerged in 2025 as a vendor-neutral solution, but adoption remains incomplete.

**Key Projects Analyzed:**

- **agentfill** (this project): Hook-based polyfill implementing full AGENTS.md spec (nested + selective loading) without file duplication. Currently supports Claude Code and Gemini CLI.

- **Ruler**: Centralized rule management with automatic distribution to tool-specific files. Supports many agents but requires sync workflow and maintains duplicate files.

- **Rulesync**: Similar approach to Ruler, but with support for translating rule metadata to agent-specific formats, subagent configurations, `.aiignore` file, and commands.

- **OpenSkills**: Package manager for AI agent skills/capabilities. Focuses on shareable, reusable skill definitions rather than project configuration.

- **Codebase Context Specification (CCS)**: `.context` directory convention for documenting codebase structure. Separate paradigm from behavioral instructions.

- **Context Exclusion Standards**: Push toward `.aiignore` as universal standard for security/privacy (currently fragmented across .cursorignore, .aiexclude, etc.).

**agentfill' Unique Position**: Only solution providing full AGENTS.md spec without file duplication or sync steps, using agent-native extension mechanisms (hooks/config). Trade-off is limited agent support (2 vs many) for deeper, cleaner integration.

**The Broader Ecosystem**: Beyond configuration files, the industry is establishing protocols for agent interoperability (MCP, A2A), context engineering, and security. Each AI coding tool has distinct configuration approaches, from Continue.dev's YAML to Windsurf's memories system.

## Table of Contents

- [The Problem Space](#the-problem-space)
- [The AGENTS.md Standard](#the-agentsmd-standard)
- [Project Comparison](#project-comparison)
  - [agentfill (This Project)](#agentfill-this-project)
  - [Ruler](#ruler)
  - [Rulesync](#rulesync)
  - [OpenSkills](#openskills)
  - [Symlink Approach](#symlink-approach)
  - [Codebase Context Specification (CCS)](#codebase-context-specification-ccs)
  - [Context Exclusion Standards (.aiignore, .aiexclude)](#context-exclusion-standards-aiignore-aiexclude)
- [Feature Comparison Matrix](#feature-comparison-matrix)
- [Approach Comparison](#approach-comparison)
- [Native Agent Support Comparison](#native-agent-support-comparison)
- [Recommendations](#recommendations)
- [Additional Related Projects & Standards](#additional-related-projects--standards)
  - [Model Context Protocol (MCP)](#model-context-protocol-mcp)
  - [Agent Communication Protocols](#agent-communication-protocols)
  - [Agent-Specific Configuration Systems](#agent-specific-configuration-systems)
  - [Context Engineering & Security](#context-engineering--security)
- [Industry Trends](#industry-trends)
- [Conclusion](#conclusion)
- [Sources](#sources)

## The Problem Space

AI coding agents have proliferated with tool-specific configuration formats:
- **Claude Code**: CLAUDE.md files
- **Cursor**: .cursorrules files in .cursor/rules/
- **Gemini CLI**: GEMINI.md files
- **GitHub Copilot**: .github/copilot-instructions.md
- **Windsurf**: .windsurf/rules/
- **Cline**: .clinerules/rules.md

This fragmentation forces developers to maintain multiple configuration files containing largely duplicate information, turning repositories into "a junk drawer of rule files that don't translate across agents."

## The AGENTS.md Standard

The **AGENTS.md** format emerged as an industry initiative to standardize AI agent configuration. Announced by OpenAI on July 16, 2025 as a vendor-neutral standard, it aims to provide a single markdown file that all tools can understand.

### Adoption Status

**Who's Adopted:**
- OpenAI (Code)
- Google's Jules
- Cursor (with some limitations)
- Factory AI
- AMP Code
- Rodeo (open-source)
- Over 25,000 projects (some sources cite 60,000+)

**Notable Holdouts:**
- Anthropic's Claude Code (still uses CLAUDE.md natively)
- Gemini CLI (still uses GEMINI.md natively)

### Standard Features

The AGENTS.md specification includes:
- **Basic support**: Read markdown instructions from AGENTS.md files
- **Nested hierarchy**: Multiple AGENTS.md files with precedence rules (closer = higher priority)
- **Selective loading**: Load only relevant context based on working directory

## Project Comparison

### agentfill (This Project)

**Repository**: github.com/nevir/agentfill (assumed)

**Approach**: Polyfill/hook-based implementation that adds AGENTS.md support to agents that don't natively support it (or have incomplete support).

**Installation**:
```sh
curl -fsSL https://raw.githubusercontent.com/nevir/agentfill/main/install.sh | sh
```

**Key Features**:
- ✅ **Basic support**: Adds AGENTS.md reading capability
- ✅ **Nested hierarchy**: Implements proper precedence rules
- ✅ **Selective loading**: Only loads relevant context for working directory
- ✅ **No file duplication**: No need for CLAUDE.md symlinks
- ✅ **Project and global modes**: Install per-project or user-wide
- ✅ **Portable shell scripts**: POSIX sh, works on Linux/macOS/BSD/Windows

**Implementation Strategy**:

*For Claude Code*:
- Uses SessionStart hooks in .claude/settings.json
- Hook script discovers all AGENTS.md files in project
- Injects instructions for nested/selective loading
- Automatically loads root AGENTS.md if present

*For Gemini CLI*:
- Modifies .gemini/settings.json to include AGENTS.md in context.fileName
- Native support handles nested/selective features

**Strengths**:
- Non-invasive (uses native extension mechanisms)
- No symlinks or file duplication required
- Implements full spec including selective loading
- Clean uninstall (just remove hook configuration)
- Installation modes support different team workflows

**Limitations**:
- Requires Perl with JSON::PP module
- Hook-based approach adds small startup overhead
- Currently supports only Claude Code and Gemini CLI

**Philosophy**: Implement AGENTS.md support through agent-native extension mechanisms rather than maintaining duplicate files.

---

### Ruler

**Repository**: [github.com/intellectronica/ruler](https://github.com/intellectronica/ruler)

**Stars**: 2.2k | **License**: MIT

**Approach**: Centralized rule management with automatic distribution to tool-specific configuration files.

**Installation**:
```sh
npm i @intellectronica/ruler
```

**Key Features**:
- ✅ **Centralized management**: Single .ruler/ directory as source of truth
- ✅ **Automatic distribution**: Generates tool-specific config files
- ✅ **Nested rule loading**: Supports multiple .ruler/ directories
- ✅ **Skills support**: Specialized knowledge packages in .ruler/skills/
- ✅ **Targeted configuration**: ruler.toml specifies which agents and paths

**Implementation Strategy**:
- Store rules in .ruler/ directory
- Run `ruler apply` to distribute to agent-specific files
- Maintains both AGENTS.md and tool-specific files

**Strengths**:
- Works with any agent (generates their native formats)
- TypeScript-based with good tooling
- Active development (v0.3.14, updated daily)
- Skills system for extending capabilities
- Fine-grained control via ruler.toml

**Limitations**:
- Requires Node.js/npm
- Must run `ruler apply` after changes
- Creates duplicate files (maintenance burden)
- Generated files must be committed to version control

**Philosophy**: Accept fragmentation, provide tooling to manage it. Maintain both standard and tool-specific files.

---

### Rulesync

**Repository**: [github.com/dyoshikawa/rulesync](https://github.com/dyoshikawa/rulesync)

**Approach**: Centralized config management with automatic distribution to tool-specific formats.

**Installation**:
```sh
npm i rulesync
# or
brew install rulesync
# or
# download pre-built binary for your platform here: https://github.com/dyoshikawa/rulesync/releases
```

**Key Features**:
- ✅ **Centralized management**: Single .ruler/ directory as source of truth
- ✅ **Automatic distribution**: Generates tool-specific config files
- ✅ **Skills support**: Specialized knowledge packages in .rulesync/skills/
- ✅ **Aiignore support**: Single aiignore file in .rulesync/.aiignore
- ✅ **Commands support**: Simple referencable prompts in .rulesync/commands/
- ✅ **MCP support**: Centralized MCP configuration in .rulesync/mcp.json
- ✅ **Subagents support**: Custom subagent definitions in .rulesync/subagents/

**Implementation Strategy**:
- Store everything in .rulesync/ directory
- Run `rulesync generate --targets "claudecode,cursor,etc" --features "rules,mcp,etc"` to distribute to agent-specific files
- Maintains custom rulesync dir/format and tool-specific files

**Strengths**:
- Works with any agent (generates their native formats)
- TypeScript-based with good tooling
- Active development (v5.7.0, updated daily)
- Very comprehensive tool support (rules, ignore, mcp, commands, subagents, and skills)
- Distributes pre-built binaries

**Limitations**:
- No config file for controlling supported agents and tools
- Must run `rulesync generate` after changes
- Creates duplicate files (maintenance burden)
- Generated files must be committed to version control

**Philosophy**: Accept fragmentation, provide tooling to manage it. Maintain both non-standard but comprehensive and tool-specific files.

---

### OpenSkills

**Repository**: [github.com/numman-ali/openskills](https://github.com/numman-ali/openskills)

**Approach**: CLI-based skill management implementing Anthropic's Agent Skills specification for universal use.

**Installation**:
```sh
npm i -g openskills
```

**Key Features**:
- ✅ **Universal agent support**: Works with Claude Code, Cursor, Windsurf, Aider
- ✅ **Multiple sources**: Install from GitHub, local paths, private Git repos
- ✅ **Project and global modes**: Default project install to .claude/skills or .agent/skills/
- ✅ **SKILL.md format**: Anthropic's Agent Skills specification
- ✅ **Management commands**: install, sync, list, manage (interactive removal)

**Implementation Strategy**:
- Package skills as SKILL.md files
- Install to project or global directories
- Use `openskills sync` to update AGENTS.md
- `--universal` flag for multi-agent support

**Strengths**:
- Focuses on skills/capabilities, not just configuration
- Package/repository model enables sharing
- Works across multiple agents
- Good for collaborative AI development
- Version control and updates

**Limitations**:
- Requires Node.js/npm
- Focused on skills rather than general configuration
- Opinionated about Anthropic's SKILL.md format
- May duplicate content between Claude's native plugins and universal mode

**Philosophy**: Standardize on shareable skill packages. Configuration as dependencies.

---

### Symlink Approach

**Approach**: Create symbolic links from AGENTS.md to tool-specific files.

**Implementation**:
```sh
# Claude Code
ln -s AGENTS.md CLAUDE.md

# Cline
ln -s AGENTS.md .clinerules/rules.md

# Cursor
ln -s AGENTS.md .cursor/rules/rules.md

# Windsurf
ln -s AGENTS.md .windsurf/rules/rules.md

# GitHub Copilot
ln -s AGENTS.md .github/copilot-instructions.md
```

**Strengths**:
- Simple, no tools required
- Single source of truth (one file, multiple names)
- Works immediately
- No build/sync step

**Limitations**:
- Windows symlink support issues
- Git handling varies (must track symlinks)
- Doesn't solve nested/selective loading
- Frontmatter compatibility issues (Cursor needs it, Claude ignores it)
- Repository clutter (multiple links)

**Philosophy**: Minimal tool approach. Accept some duplication for simplicity.

---

### Codebase Context Specification (CCS)

**Repository**: [github.com/Agentic-Insights/codebase-context-spec](https://github.com/Agentic-Insights/codebase-context-spec)

**License**: MIT

**Approach**: Standardized `.context` directory convention for documenting codebases for both AI and humans.

**Implementation**:
```
project/
└── .context/
    ├── index.md       # Main context documentation
    ├── config.yaml    # Optional structured config
    └── data.json      # Optional data files
```

**Key Features**:
- ✅ **Tool-agnostic**: Works with any AI coding agent
- ✅ **Simple setup**: Just create `.context/index.md`
- ✅ **Human-readable**: Standard markdown format
- ✅ **Validation tooling**: TypeScript-based linter (codebase-context-lint)
- ✅ **Multi-level contexts**: Can nest `.context` directories

**Supported Tools**:
- Claude-Dev, Aider, Cursor, Continue
- GitHub Copilot, Amazon Q Developer
- OpenHands, Devin, Factory.ai

**Strengths**:
- Similar to .env and .editorconfig conventions
- Focused on teaching AI about codebase structure
- Separate from instruction/rule files
- Active tooling ecosystem

**Limitations**:
- Different paradigm (context vs instructions)
- Requires tools to explicitly support it
- Additional directory/files to maintain

**Philosophy**: Document codebase structure and conventions separately from behavioral instructions. Similar to how README.md documents for humans, .context documents for AI.

---

### Context Exclusion Standards (.aiignore, .aiexclude)

**Approach**: Standardized ignore files for controlling what AI agents can access.

**Current State**:
- **Multiple formats**: .aiignore, .aiexclude, .geminiignore, .cursorignore, .codeiumignore, .continueignore, .aiderignore
- **Standardization effort**: Push for .aiignore as industry-wide standard
- **Syntax**: Follows .gitignore syntax and conventions

**Cross-Tool Support**:
- **JetBrains AI Assistant**: Supports .aiignore, .cursorignore, .codeiumignore, .aiexclude
- **Android Studio/Gemini**: Uses .aiexclude
- **Cursor**: Uses .cursorignore
- **Aider**: Uses .aiderignore
- **Continue.dev**: Uses .continueignore

**Key Features**:
- ✅ **Security**: Prevent sensitive files from AI access
- ✅ **Performance**: Exclude unnecessary files from context
- ✅ **Cross-tool compatibility**: Many tools support multiple formats
- ✅ **Familiar syntax**: Uses .gitignore patterns

**Standardization Status**:
- Active GitHub issue on Gemini CLI proposing standard adoption
- JetBrains pioneering .aiignore as universal standard
- Community consensus building around single format

**Strengths**:
- Critical for security/privacy
- Simple, well-understood syntax
- Some tools already multi-format compatible
- Low barrier to adoption

**Limitations**:
- Still fragmented (multiple file names)
- Need to keep multiple files in sync currently
- Pollutes root directory with multiple ignore files

**Philosophy**: Security and performance through controlled context access. Moving toward .aiignore as universal standard, similar to .gitignore.

---

## Feature Comparison Matrix

| Feature | agentfill | Ruler | OpenSkills | Symlinks | CCS |
|---------|-----------------|-------|------------|----------|-----|
| **No file duplication** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Nested hierarchy** | ✅ | ✅ | Partial | ❌ | ✅ |
| **Selective loading** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Cross-platform** | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| **No build step** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Skills support** | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Works with any agent** | ⚠️ (2 agents) | ✅ | ✅ | ✅ | ✅ |
| **Zero dependencies** | ⚠️ (Perl) | ❌ (Node) | ❌ (Node) | ✅ | ⚠️ (Linter: Node) |
| **Validation tooling** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Active development** | ✅ | ✅ | ✅ | N/A | ✅ |

## Approach Comparison

### Philosophy Differences

**agentfill**:
- *Principle*: Implement the standard through native mechanisms
- *Trade-off*: Limited agent support for deep integration
- *Best for*: Teams wanting clean AGENTS.md-only repos

**Ruler**:
- *Principle*: Accept fragmentation, provide management tools
- *Trade-off*: Maintains duplicate files but with single source
- *Best for*: Teams using many different agents

**OpenSkills**:
- *Principle*: Standardize on shareable skill packages
- *Trade-off*: Different abstraction (skills vs config)
- *Best for*: Teams sharing reusable capabilities

**Symlinks**:
- *Principle*: Minimize tooling, accept duplication
- *Trade-off*: Simple but incomplete solution
- *Best for*: Small projects, quick experiments

**Codebase Context Specification (CCS)**:
- *Principle*: Document structure separately from instructions
- *Trade-off*: Different directory convention (.context vs root files)
- *Best for*: Projects needing comprehensive codebase documentation

### Technical Implementation

**Extension Mechanisms**:
- **agentfill**: Hooks (Claude), native config (Gemini)
- **Ruler**: File generation from templates
- **OpenSkills**: Package installation to known paths
- **Symlinks**: Filesystem links
- **CCS**: Tool reads .context/index.md if present
- **Context Exclusion**: Tools read .aiignore/.aiexclude if present

**Runtime Behavior**:
- **agentfill**: Hook runs at session start, dynamically loads context
- **Ruler**: Pre-generate files, agents read them normally
- **OpenSkills**: Files exist in place, agents read them normally
- **Symlinks**: Files are links, agents read through them

**Update Workflow**:
- **agentfill**: Edit AGENTS.md, reload session
- **Ruler**: Edit .ruler/, run `ruler apply`, commit
- **OpenSkills**: Edit SKILL.md, run `openskills sync`, commit
- **Symlinks**: Edit AGENTS.md, commit (links follow)

## Native Agent Support Comparison

From the README and research, here's the current state:

| Feature | Claude Code | Cursor Agent | Gemini CLI |
|---------|-------------|--------------|------------|
| **Basic support** | ❌ Native | ✅ [Root only](https://cursor.com/docs/context/rules) | ⚠️ [Configurable](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) |
| **Nested** | ❌ Native | ⚠️ [Broken](https://forum.cursor.com/t/nested-agents-md-files-not-being-loaded/138411) | ✅ Native |
| **Selective** | ❌ Native | ❌ Native | ✅ Native |

### What agentfill Fixes

**For Claude Code**:
- Adds all three features (basic, nested, selective)
- No CLAUDE.md files needed
- Maintains compatibility with existing hooks

**For Gemini CLI**:
- Adds AGENTS.md to fileName list alongside GEMINI.md
- Leverages native nested/selective support

**For Others**:
- Not yet supported (Cursor, Aider, Codex documented but not implemented)

## Recommendations

### Use agentfill When:
- You want AGENTS.md-only repositories (no CLAUDE.md, etc.)
- You need selective loading (important for monorepos)
- You primarily use Claude Code and/or Gemini CLI
- You want minimal maintenance (no sync step)
- You're comfortable with hook-based solutions

### Use Ruler When:
- Your team uses many different agents
- You need skills support
- You want fine-grained control (ruler.toml)
- You're comfortable with a sync workflow
- You have Node.js in your toolchain

### Use OpenSkills When:
- You want to share/reuse capabilities across projects
- You're invested in Anthropic's SKILL.md format
- You need package-style dependency management
- You value the skills abstraction over raw config
- You have Node.js in your toolchain

### Use Symlinks When:
- You need a quick, simple solution
- You're on Unix-like systems only
- You don't need nested/selective features
- You want zero dependencies
- You're okay with repository clutter

### Hybrid Approaches

**agentfill + OpenSkills**:
- agentfill for configuration
- OpenSkills for shareable capabilities
- Clean separation of concerns

**Ruler + AGENTS.md Standard**:
- Keep .ruler/ as source of truth
- Generate both AGENTS.md and tool-specific files
- Ruler's distribution handles compatibility

## Additional Related Projects & Standards

Beyond the main configuration management tools, several other projects and standards are relevant to the AI coding agent ecosystem:

### Model Context Protocol (MCP)

**What**: Open standard by Anthropic for connecting AI applications to external systems.

**Architecture**: Client-server model where AI apps (clients) interact with MCP servers to access data, tools, and prompts.

**Key Features**:
- Bi-directional connections between data sources and AI apps
- Tool definitions for AI agent actions
- Structured prompt management
- Security-focused design

**Adoption**:
- Claude Desktop native support
- OpenAI Agents SDK integration
- Microsoft Azure Foundry Agent Service
- Cursor, Windsurf (via configuration)

**Configuration**:
- `.cursor/mcp.json` for project-specific servers
- JSON config with server labels, URLs, commands, args
- Environment variable support

**Relevance**: MCP extends agent capabilities beyond static configuration to dynamic tool/data access. Complements AGENTS.md by providing runtime capabilities.

**Sources**: [Model Context Protocol](https://modelcontextprotocol.io/), [OpenAI MCP Docs](https://openai.github.io/openai-agents-python/mcp/), [Microsoft MCP Guide](https://learn.microsoft.com/en-us/azure/developer/ai/intro-agents-mcp)

---

### Agent Communication Protocols

**Agent2Agent (A2A)**: Google's protocol for agent-to-agent communication, donated to Linux Foundation alongside MCP.

**Agent Communication Protocol (ACP)**: IBM's vendor-neutral standard under Linux Foundation for RESTful, HTTP-based task invocation and lifecycle management.

**Agentic AI Foundation**: Linux Foundation initiative (late 2025) to establish shared standards and best practices for agentic AI interoperability.

**Significance**: These protocols address agent interoperability at a higher level than configuration files. They enable multi-agent systems where different AI agents coordinate and delegate tasks.

**Relevance to agentfill**: As agents become more interoperable, standardized configuration (like AGENTS.md) becomes even more critical to ensure consistent behavior across coordinated systems.

**Sources**: [AI Agent Protocols](https://www.ssonetwork.com/intelligent-automation/columns/ai-agent-protocols-10-modern-standards-shaping-the-agentic-era), [Microsoft Agent Factory](https://azure.microsoft.com/en-us/blog/agent-factory-connecting-agents-apps-and-data-with-new-open-standards-like-mcp-and-a2a/)

---

### Agent-Specific Configuration Systems

#### **Sourcegraph Cody**

**Configuration**: Custom commands in `~/.vscode/code.json` or workspace settings

**Context Options**: Selection, current file, directory, file path, command output, codebase search, or none

**Unique Features**:
- Rich context control (8+ context types)
- Workspace vs user-level commands
- @mentions for explicit context references
- Workspace toggle for context inclusion

**Sources**: [Cody Commands](https://docs.sourcegraph.com/cody/capabilities/commands), [Custom Commands](https://docs.sourcegraph.com/cody/custom-commands)

#### **Continue.dev**

**Configuration**: `config.yaml` (or deprecated `config.json`)

**Defines**: Models (chat, edit, apply, embed, rerank), context providers, system messages, custom slash commands

**Ignore Files**: `.continueignore` for excluding files

**Unique Features**:
- Terminal-native (TUI mode or headless)
- Role-based model configuration
- Extensive context provider system

**Sources**: [Continue.dev Docs](https://docs.continue.dev/), [Continue GitHub](https://github.com/continuedev/continue)

#### **Windsurf IDE**

**Configuration**: Memories and Rules system (YAML-based)

**Types**:
- User-generated memories (explicit rules)
- Automatically generated memories (from interactions)

**Unique Features**:
- MCP server support
- Closed-source binary with YAML configuration
- Rules for language, framework, API preferences

**Sources**: [Cline vs Windsurf](https://www.qodo.ai/blog/cline-vs-windsurf/), [Windsurf Docs](https://docs.windsurf.com/)

#### **Cline**

**Configuration**: `.clinerules` files for project-level instructions

**Features**:
- Coding standards and architectural constraints
- Apache-2.0 licensed, forkable
- Agentic (iterative problem solving)

**Sources**: [Cline vs Windsurf](https://www.qodo.ai/blog/cline-vs-windsurf/)

#### **Tabnine**

**Configuration**: Workspace-level context controls

**Context Management**:
- Restriction by file, folder, or monorepo
- Workspace toggle for context inclusion
- @mentions for explicit context
- Enterprise Context Engine (learns org patterns)

**Unique Features**:
- Privacy-focused (encrypted, immediate deletion)
- Adapts to mixed stacks and legacy systems
- Local code awareness with RAG

**Sources**: [Tabnine Platform](https://www.tabnine.com/platform/), [Tabnine Personalization](https://docs.tabnine.com/main/welcome/readme/personalization)

#### **GitHub Copilot**

**Configuration**: `.github/copilot-instructions.md` for repository-wide instructions

**Workspace Configuration**: `.github/copilot-workspace/CONTRIBUTING.md` (Copilot Workspace was sunset May 2025)

**Features**:
- URL inclusion in instruction files (fetched and added to context)
- Workspace vs user profile instructions
- Multiple `.instructions.md` files for specific contexts

**Sources**: [GitHub Copilot Custom Instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions), [Copilot Workspace](https://github.com/githubnext/copilot-workspace-user-manual)

#### **Replit Agent**

**Configuration**: `prompt.txt` and `tool.json` files

**Context Management**:
- Checkpoint system (snapshots of work, context, databases)
- Maintains context during interaction

**Limitations**: Context retention could be improved, occasionally loses track of earlier conversations

**Sources**: [Replit Agent](https://docs.replit.com/replitai/agent), [5 AI Agents](https://dev.to/ebonyl/5-ai-agents-you-need-to-know-about-3969)

#### **OpenHands**

**Architecture**: Event-sourced state management with nine interlocking components

**Context Management**:
- Automatic conversation history condensation when context limits approached
- Summarization to preserve critical information
- Immutable, validated components
- Mutable conversation state object

**Unique Features**: Most sophisticated context management with automatic optimization

**Sources**: [OpenHands SDK](https://arxiv.org/html/2511.03690v1), [OpenHands DeepWiki](https://deepwiki.com/All-Hands-AI/OpenHands/1-openhands-overview)

---

### Context Engineering & Security

**Context Engineering**: The art and science of curating what goes into limited context windows from the universe of possible information (system instructions, tools, MCP, external data, message history).

**Tools**:
- **Augment Code**: Automatically injects missing context (files, dependencies, historical decisions)
- **Qodo**: Compiles and injects context from codebases, docs, team inputs
- **n8n**: Simplifies context engineering workflows

**Security Concerns**: Prompt injection vulnerabilities where agents confuse user data with system instructions. If underlying model is vulnerable, agent can be manipulated into writing insecure code.

**Best Practices**: Treat LLM like a developer on team; put equal effort into tool configuration and prompt crafting; provide best possible context from user-supplied information.

**Sources**: [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [Context Engineering Guide](https://www.promptingguide.ai/guides/context-engineering-guide), [Prompt Injection Risks](https://www.securecodewarrior.com/article/prompt-injection-and-the-security-risks-of-agentic-coding-tools)

---

## Industry Trends

### Standardization Movement
The AGENTS.md initiative represents a significant push toward standardization, with major industry players (OpenAI, Google, Cursor, Factory) adopting a common format. However, complete standardization faces challenges:

1. **Existing investment**: Tools have established formats with users
2. **Feature parity**: Not all tools have equivalent capabilities
3. **Migration cost**: Converting existing configurations
4. **Vendor lock-in fears**: Tools may resist full interoperability

### Emerging Patterns

**Selective Loading**: Increasingly recognized as essential for monorepos. Without it, agents load irrelevant context, wasting tokens and reducing accuracy.

**Skills/Capabilities Model**: Moving beyond static configuration to dynamic, composable capabilities (Agent Skills, OpenSkills).

**Hook-Based Extension**: Agents providing lifecycle hooks (SessionStart, UserPromptSubmit) enable powerful customization without forking.

**Hierarchical Context**: Nested configuration with precedence rules becoming table stakes.

## Conclusion

agentfill occupies a unique position in the ecosystem:

**Unique Value Proposition**:
- Only solution implementing full AGENTS.md spec (nested + selective) without file duplication
- Hook-based approach respects agent-native patterns
- Zero runtime dependencies beyond shell

**Competitive Advantages vs Ruler**:
- No sync step or generated files
- Simpler mental model (one source file)
- Better monorepo support (selective loading)

**Competitive Disadvantages vs Ruler**:
- Limited agent support (2 vs many)
- No skills management
- Less control over distribution

**Competitive Advantages vs OpenSkills**:
- Configuration-focused (not skills)
- No package management complexity
- Native AGENTS.md support

**Competitive Disadvantages vs OpenSkills**:
- No skill sharing/reuse
- Not focused on collaborative development
- Missing the capabilities abstraction

**The Landscape**: These projects are complementary rather than directly competitive. agentfill provides the cleanest AGENTS.md implementation for supported agents. Ruler solves the multi-agent distribution problem. OpenSkills addresses skill/capability sharing. Symlinks offer a no-tool fallback.

Teams may use multiple approaches: agentfill for Claude/Gemini AGENTS.md support, OpenSkills for shared capabilities, or Ruler for comprehensive multi-agent workflows.

## Sources

### AGENTS.md Standard
- [AGENTS.md Official Site](https://agents.md)
- [AGENTS.md GitHub Repository](https://github.com/agentsmd/agents.md)
- [AGENTS.md: A New Standard for Unified Coding Agent Instructions](https://addozhang.medium.com/agents-md-a-new-standard-for-unified-coding-agent-instructions-0635fc5cb759)
- [Agents.md — A New Standard for Coding Agents](https://medium.com/@jason_81067/agents-md-a-new-standard-for-coding-agents-e7e8c2d9d9ca)
- [AGENTS.md: A Standard for AI Coding Agents](https://kupczynski.info/posts/agents-md-a-standard-for-ai-coding-agents/)
- [agents.md: The Complete Guide to the Open Standard for AI Coding Agents](https://prpm.dev/blog/agents-md-deep-dive)
- [AGENTS.md: The New Standard for AI Coding Assistants](https://medium.com/@proflead/agents-md-the-new-standard-for-ai-coding-assistants-af72910928b6)

### Configuration File Comparison
- [Some notes on AI Agent Rule / Instruction / Context files](https://gist.github.com/0xdevalias/f40bc5a6f84c4c5ad862e314894b2fa6)
- [AGENTS.md vs CLAUDE.md vs GEMINI.md: The Ultimate AI Agent Configuration Files Comparison](https://www.xugj520.cn/en/archives/ai-agent-configuration-comparison.html)
- [Cursor vs Claude Code: The Ultimate Comparison Guide](https://www.builder.io/blog/cursor-vs-claude-code)
- [Claude Code Gets Path-Specific Rules (Cursor Had This First)](https://paddo.dev/blog/claude-rules-path-specific-native/)

### Ruler
- [GitHub - intellectronica/ruler](https://github.com/intellectronica/ruler)
- [Ruler — OKIGU](https://ai.intellectronica.net/ruler)
- [Ruler: Centralise Your AI Coding Assistant Instructions](https://okigu.com/ruler)
- [Ruler: a rule configuration tool for unified management of multiple AI coding agents](https://www.kdjingpai.com/en/ruler/)

### OpenSkills
- [GitHub - numman-ali/openskills](https://github.com/numman-ali/openskills)
- [OpenSkills, adding Claude Skills and Superpowers for any agent or IDE](https://dev.to/wakeupmh/openskills-adding-claude-skills-and-superpowers-for-any-agent-or-ide-3j35)
- [OpenSkills: Revolutionizing AI Coding with Claude Code-Style Skills for All Agents](https://www.xugj520.cn/en/archives/openskills-ai-coding-skills.html)
- [GitHub - skillmatic-ai/awesome-agent-skills](https://github.com/skillmatic-ai/awesome-agent-skills)

### Claude Code Hooks
- [How to configure hooks - Coding](https://claude.com/blog/how-to-configure-hooks)
- [Hooks reference - Claude Code Docs](https://code.claude.com/docs/en/hooks)
- [Claude Code — Use Hooks to Enforce End-of-Turn Quality Gates](https://jpcaparas.medium.com/claude-code-use-hooks-to-enforce-end-of-turn-quality-gates-5bed84e89a0d)
- [GitHub - disler/claude-code-hooks-multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability)

### Codebase Context Specification
- [GitHub - Agentic-Insights/codebase-context-spec](https://github.com/Agentic-Insights/codebase-context-spec)
- [Codebase Context Specification RFC: Revolutionizing AI-Assisted Development](https://agenticinsights.substack.com/p/codebase-context-specification-rfc)
- [AI in Large Codebase Context](https://medium.com/@amjad.shaikh/ai-in-large-codebase-context-building-enterprise-grade-software-with-ai-coding-assistants-19c0bac87b3c)
- [Codebase Insight MCP Server](https://skywork.ai/skypage/en/codebase-insight-mcp-server-ai-engineers/1978276735696687104)

### Context Exclusion Standards
- [Introduce and use a standard for ai agent ignore file - Gemini CLI Issue](https://github.com/google-gemini/gemini-cli/issues/4688)
- [Configure context sharing with .aiexclude files - Android Studio](https://developer.android.com/studio/gemini/aiexclude)
- [Exclude files from Gemini Code Assist use](https://docs.cloud.google.com/gemini/docs/codeassist/create-aiexclude-file)
- [Value your code, why the .aiexclude file matters](https://www.myhappyplace.dev/blog/value-your-code-ai-exclude/)
- [GitHub - SixArm/aiexclude](https://github.com/SixArm/aiexclude)
- [Restrict or disable AI Assistant features - JetBrains](https://www.jetbrains.com/help/ai-assistant/disable-ai-assistant.html)
- [Ignore files - Cursor Docs](https://cursor.com/docs/context/ignore-files)
- [Configuration - aider](https://aider.chat/docs/config.html)

### Model Context Protocol (MCP)
- [Model Context Protocol Official Site](https://modelcontextprotocol.io/)
- [Model context protocol (MCP) - OpenAI Agents SDK](https://openai.github.io/openai-agents-python/mcp/)
- [Build Agents using Model Context Protocol on Azure](https://learn.microsoft.com/en-us/azure/developer/ai/intro-agents-mcp)
- [GitHub - lastmile-ai/mcp-agent](https://github.com/lastmile-ai/mcp-agent)
- [Powering AI Agents with Real-Time Data Using Anthropic's MCP and Confluent](https://www.confluent.io/blog/ai-agents-using-anthropic-mcp/)

### Agent Communication Protocols
- [AI Agent Protocols: 10 Modern Standards Shaping the Agentic Era](https://www.ssonetwork.com/intelligent-automation/columns/ai-agent-protocols-10-modern-standards-shaping-the-agentic-era)
- [Agent Factory: Connecting agents, apps, and data with new open standards like MCP and A2A](https://azure.microsoft.com/en-us/blog/agent-factory-connecting-agents-apps-and-data-with-new-open-standards-like-mcp-and-a2a/)
- [7 Agentic AI Trends to Watch in 2026](https://machinelearningmastery.com/7-agentic-ai-trends-to-watch-in-2026/)

### Agent-Specific Configuration
- [Sourcegraph Cody Commands](https://docs.sourcegraph.com/cody/capabilities/commands)
- [Cody Custom Commands](https://docs.sourcegraph.com/cody/custom-commands)
- [Continue.dev Documentation](https://docs.continue.dev/)
- [GitHub - continuedev/continue](https://github.com/continuedev/continue)
- [Cline vs Windsurf: Which AI Coding Agent Fits Enterprise Engineering Teams?](https://www.qodo.ai/blog/cline-vs-windsurf/)
- [Windsurf Docs](https://docs.windsurf.com/)
- [Tabnine Platform](https://www.tabnine.com/platform/)
- [Tabnine Personalization](https://docs.tabnine.com/main/welcome/readme/personalization)
- [GitHub Copilot Custom Instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions)
- [GitHub - githubnext/copilot-workspace-user-manual](https://github.com/githubnext/copilot-workspace-user-manual)
- [Replit Agent](https://docs.replit.com/replitai/agent)
- [5 AI Agents You Need to Know About](https://dev.to/ebonyl/5-ai-agents-you-need-to-know-about-3969)
- [The OpenHands Software Agent SDK](https://arxiv.org/html/2511.03690v1)
- [OpenHands DeepWiki](https://deepwiki.com/All-Hands-AI/OpenHands/1-openhands-overview)

### Context Engineering & Security
- [Effective context engineering for AI agents - Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Context Engineering Guide](https://www.promptingguide.ai/guides/context-engineering-guide)
- [Context Engineering: The New Backbone of Scalable AI Systems](https://www.qodo.ai/blog/context-engineering/)
- [Prompt Injection and the Security Risks of Agentic Coding Tools](https://www.securecodewarrior.com/article/prompt-injection-and-the-security-risks-of-agentic-coding-tools)
- [Your AI, My Shell: Demystifying Prompt Injection Attacks](https://arxiv.org/html/2509.22040v1)
- [How to build your agent: 11 prompting techniques](https://www.augmentcode.com/blog/how-to-build-your-agent-11-prompting-techniques-for-better-ai-agents)

### General Resources
- [Testing AI coding agents (2025): Cursor vs. Claude, OpenAI, and Gemini](https://render.com/blog/ai-coding-agents-benchmark)
- [AGENTS.md: One File for All Agents](https://www.devshorts.in/p/agentsmd-one-file-for-all-agents)
- [Keep your AGENTS.md in sync - One Source of Truth for AI Instructions](https://kau.sh/blog/agents-md/)
- [AGENTS.md: Why your README matters more than AI configuration files](https://devcenter.upsun.com/posts/why-your-readme-matters-more-than-ai-configuration-files/)
- [Show me your AGENTS.md rules system! - Cursor Community Forum](https://forum.cursor.com/t/show-me-your-agents-md-rules-system/132323)
- [Best AI Coding Assistants as of January 2026](https://www.shakudo.io/blog/best-ai-coding-assistants)
- [Agentic IDE Comparison: Cursor vs Windsurf vs Antigravity](https://www.codecademy.com/article/agentic-ide-comparison-cursor-vs-windsurf-vs-antigravity)
