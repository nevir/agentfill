# Agent Skills Best Practices

A guide to writing portable agent skills for the [Agent Skills specification](https://agentskills.io). Skills written to this spec work across 25+ AI coding agents including Claude Code, Gemini CLI, GitHub Copilot, Cursor, Codex, Goose, Windsurf, and more.

In a universal-agents project, skills live in `.agents/skills/` and are symlinked to each agent's native directory (`.claude/skills/`, `.gemini/skills/`, etc.) for automatic discovery.

## SKILL.md Format

Every skill is a directory containing a `SKILL.md` file. The file has two parts: YAML frontmatter for metadata and a markdown body for instructions.

```yaml
---
name: my-skill
description: Does X when Y. Use when the user asks about Z or needs to perform W.
---

# My Skill

Instructions the agent follows when this skill is active.
```

### Frontmatter

**Required fields:**

| Field | Constraints | Purpose |
|-------|------------|---------|
| `name` | 1-64 chars, lowercase, hyphens only (`^[a-z][a-z0-9-]{0,63}$`) | Identifier and slash command name |
| `description` | 1-1024 chars | Tells the agent what this skill does and when to use it |

**Optional fields (universal):**

| Field | Purpose |
|-------|---------|
| `license` | License name or reference to bundled LICENSE file |
| `compatibility` | Environment requirements (up to 500 chars) |
| `metadata` | Arbitrary key-value pairs |

**Agent-specific extensions:**

These fields are recognized by specific agents and safely ignored by others:

| Field | Agent | Purpose |
|-------|-------|---------|
| `disable-model-invocation` | Claude | Only user can invoke (not auto-activated) |
| `user-invocable` | Claude | Set `false` to hide from `/` menu (agent-only) |
| `context` | Claude | Set `fork` for isolated subagent execution |
| `agent` | Claude | Subagent type (Explore, Plan, general-purpose) |
| `model` | Claude | Override model for this skill |
| `allowed-tools` | Claude | Pre-approve specific tools |
| `argument-hint` | Claude | Show expected args in autocomplete (e.g. `[issue-number]`) |
| `hooks` | Claude | Lifecycle hooks scoped to this skill |

### Body

The markdown body contains the instructions the agent follows when the skill is active. Keep it under 500 lines. If you need more depth, use supporting files in `references/`.

## Skill Directory Structure

**Minimal:**

```
my-skill/
└── SKILL.md
```

**With supporting files:**

```
my-skill/
├── SKILL.md              # Required: main instructions
├── references/           # Detailed docs loaded on demand
│   ├── api-reference.md
│   └── examples.md
├── scripts/              # Executable helpers (sh, py, js)
│   └── validate.sh
└── assets/               # Templates, data files
    └── template.md
```

Reference supporting files from SKILL.md so the agent knows they exist and when to load them. Keep references one level deep from SKILL.md.

## Writing Effective Descriptions

The `description` field is the most important part of a skill. It determines when agents auto-activate the skill based on conversation context.

**A good description covers:**
1. **What** the skill does
2. **When** to use it (trigger conditions)

**Include keywords that match natural user language.** The agent matches conversation context against descriptions to decide activation.

```yaml
# Good - specific, includes triggers
description: >-
  Generate unit tests for Python functions using pytest. Use when the user
  asks to write tests, add test coverage, or create test cases for Python code.

# Bad - vague, no triggers
description: Helps with testing.

# Bad - too specific, won't trigger
description: >-
  Generate exactly 3 pytest test functions for pure functions that take
  integers and return integers, using parametrize decorators.
```

**The spectrum:** Too vague triggers too often (false positives). Too specific never triggers. Aim for a description that would match the 3-5 most common ways a user would phrase the request.

## Writing Effective Instructions

### Content Principles

**Only include what the agent doesn't already know.** Challenge every paragraph: does the agent need this, or would it figure it out from context? Skills that repeat common knowledge waste context tokens.

**Use input/output examples.** Examples are the most effective way to communicate expectations — more effective than descriptions alone.

```markdown
## Example

When asked to document a function like:

    def calculate_total(items, tax_rate):
        subtotal = sum(item.price for item in items)
        return subtotal * (1 + tax_rate)

Produce:

    def calculate_total(items: list[Item], tax_rate: float) -> float:
        """Calculate the total price including tax.

        Args:
            items: List of items with a price attribute.
            tax_rate: Tax rate as a decimal (e.g. 0.08 for 8%).

        Returns:
            Total price including tax.
        """
        subtotal = sum(item.price for item in items)
        return subtotal * (1 + tax_rate)
```

**Match specificity to the task:**
- **Rigid templates** for structured output (APIs, data formats, commit messages)
- **Flexible guidance** for creative or context-dependent tasks

### Workflow Patterns

**Sequential** — for tasks with a clear linear flow:

```markdown
## Workflow

1. Read the existing code
2. Identify the public API surface
3. Generate test cases for each public function
4. Run the tests and fix failures
```

**Conditional** — for tasks that branch based on context:

```markdown
## Workflow

Determine the type of change, then follow the appropriate path:

- **New feature**: Write tests first, then implement
- **Bug fix**: Reproduce the bug in a test, then fix
- **Refactor**: Ensure existing tests pass, then refactor
```

### Progressive Disclosure

Skills load in three tiers to keep context lean:

| Tier | When loaded | Budget |
|------|-------------|--------|
| Metadata | Session start (always) | ~100 tokens (name + description) |
| Instructions | When skill activates | <5,000 tokens (SKILL.md body) |
| Resources | On demand | As needed (references/, scripts/) |

**What belongs in SKILL.md vs references:**

Content the agent needs in every or most activations belongs in SKILL.md. Reference files should contain content needed only in specific scenarios.

- **In SKILL.md**: Core rules, common patterns, frequently needed examples
- **In references/**: Full templates for specific scenarios, detailed rules for uncommon cases

**Reference file guidelines:**

- Each file should have a clear load trigger stated in SKILL.md
- Name files by scenario: `references/new-script-template.md` not `references/full-guide.md`
- Multiple focused files (50-150 lines each) beat one monolithic reference
- If a reference is always loaded when the skill activates, merge it into SKILL.md

Tell the agent when to load each reference:

```markdown
For complete script templates with usage/help patterns, read `references/new-script-template.md`.
```

## Portability

### What Is Universal

These work identically across all agents that support the Agent Skills spec:

- **SKILL.md format** — YAML frontmatter + markdown body
- **Directory structure** — `SKILL.md` + optional `scripts/`, `references/`, `assets/`
- **MCP server configurations** — 100% reusable across agents
- **Scripts and documentation** — fully portable

### What Varies by Agent

- **Agent-specific frontmatter** — fields like `disable-model-invocation` or `context: fork` are Claude-specific; they're safely ignored by other agents
- **Tool availability** — different agents have different built-in tools and naming conventions
- **Discovery mechanisms** — some agents auto-activate based on description, others require explicit invocation

### Best Practices for Portability

- **Prefer universal frontmatter fields** (`name`, `description`, `license`, `compatibility`) — add agent-specific fields only when needed
- **Use forward slashes** for all paths in instructions
- **Document requirements** in the `compatibility` field if the skill needs specific tools or runtimes
- **Avoid agent-specific tool names** in instructions when possible — describe the action rather than the tool
- **Test across agents** when possible — at minimum, verify the SKILL.md parses correctly

## Development Process

The most effective approach is iterative:

1. **Do the task manually** — complete the task with your agent, noting what context you repeatedly provide
2. **Extract patterns** — identify the reusable instructions, examples, and references
3. **Write the skill** — create SKILL.md with proper frontmatter and focused instructions
4. **Review for conciseness** — challenge every paragraph: does the agent need this?
5. **Test with real scenarios** — use the skill in fresh sessions on similar tasks
6. **Iterate** — refine based on when it activates (or doesn't) and output quality

**Common mistakes:**
- Writing skills speculatively before you have a real, repeated task
- Including information the agent already knows (common language features, standard patterns)
- Descriptions that are too vague or too specific
- Monolithic skills that try to do everything — split into focused skills instead

## Using Skills with universal-agents

In a universal-agents project, `.agents/skills/` is the shared skill directory. The install script creates symlinks from each agent's native directory:

```
.agents/skills/my-skill/SKILL.md
    ↓ symlinked via
.claude/skills/ → ../.agents/skills/
.gemini/skills/ → ../.agents/skills/
```

**Agent-specific notes:**

| Agent | Status | Notes |
|-------|--------|-------|
| Claude Code | Native support | Hot reload (v2.1.0+). Symlinked skills work but don't appear in `/skills` list ([display bug](https://github.com/anthropics/claude-code/issues/14836)). |
| Gemini CLI | Experimental | Requires `experimental.skills: true` in settings. Use `/skills enable` to activate specific skills. |

## Ecosystem

- **[Agent Skills Specification](https://agentskills.io/specification)** — the formal spec
- **[Agent Skills Directory](https://skills.sh/)** — discover and install community skills
- **[Anthropic Skills](https://github.com/anthropics/skills)** — official example skills
- **[Awesome Agent Skills](https://github.com/VoltAgent/awesome-agent-skills)** — community collection (200+ skills)
- **[skillkit](https://github.com/rohitg00/skillkit)** — portable skills across 30+ agents
- **[Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)** — Anthropic's official guide

## Sources

- [Agent Skills Specification](https://agentskills.io/specification)
- [Extend Claude with Skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Skill Authoring Best Practices - Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Equipping Agents for the Real World with Agent Skills - Anthropic Engineering](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Agent Skills - Gemini CLI](https://geminicli.com/docs/cli/skills/)
- [Agent Skills in VS Code - GitHub Copilot](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [How to Write a Great agents.md - GitHub Blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
