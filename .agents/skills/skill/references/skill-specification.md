# Agent Skills Specification Reference

Condensed reference for the [Agent Skills specification](https://agentskills.io/specification). Use this when you need precise details about frontmatter fields, naming rules, or structural constraints.

## Frontmatter Fields

### Required

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `name` | string | 1-64 chars, must match `^[a-z][a-z0-9-]{0,63}$` | Becomes the `/slash-command` name. Must match directory name. |
| `description` | string | 1-1024 chars | Determines auto-activation. Must state WHAT and WHEN. |

### Optional (Universal)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `license` | string | Free-form | License name or reference to bundled LICENSE file |
| `compatibility` | string | Up to 500 chars | Environment requirements (runtimes, tools, OS) |
| `metadata` | object | Arbitrary key-value | Additional data; agents may ignore unknown keys |

### Agent-Specific (Claude Code)

These are safely ignored by other agents:

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `disable-model-invocation` | boolean | `false` | `true` = only user can invoke via `/name`; agent won't auto-activate |
| `user-invocable` | boolean | `true` | `false` = hidden from `/` menu; only agent can activate |
| `context` | string | (none) | `fork` = run in isolated subagent without conversation history |
| `agent` | string | (none) | Subagent type: `Explore`, `Plan`, `general-purpose` |
| `model` | string | (none) | Override model (e.g. `haiku`) |
| `allowed-tools` | string | (none) | Space-delimited pre-approved tools (e.g. `Read Grep Glob`) |
| `argument-hint` | string | (none) | Autocomplete hint (e.g. `[issue-number]`) |
| `hooks` | object | (none) | Lifecycle hooks scoped to this skill |

## Directory Structure

```
skill-name/           # Directory name must match `name` field
├── SKILL.md          # Required: frontmatter + instructions
├── references/       # Optional: detailed docs loaded on demand
├── scripts/          # Optional: executable helpers (sh, py, js)
└── assets/           # Optional: templates, data, images
```

- SKILL.md is the only required file
- Supporting files should be referenced from SKILL.md body so the agent knows they exist
- Keep references one level deep from SKILL.md (no nested subdirectories in references)

## Progressive Disclosure

Skills load in three tiers:

| Tier | Loaded when | Token budget | Content |
|------|-------------|-------------|---------|
| Metadata | Session start (always) | ~100 tokens | `name` + `description` from frontmatter |
| Instructions | Skill activates | <5,000 tokens | Full SKILL.md body |
| Resources | On demand | As needed | Files in `references/`, `scripts/`, `assets/` |

Agents have a description budget (~15,000 chars across all skills). If you have many skills, keep descriptions concise. The `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable can increase this limit in Claude Code.

**Content placement**: Content the agent needs in every or most activations belongs in SKILL.md (the Instructions tier). Use reference files only for content needed in specific scenarios — each with a clear load trigger stated in SKILL.md. A reference that's always loaded defeats the purpose of tiered loading.

## Description Best Practices

**Structure:** `<What it does>. <When to use it>.`

**Good examples:**

```yaml
# Specific, includes natural trigger keywords
description: >-
  Generate unit tests for Python functions using pytest. Use when the user
  asks to write tests, add test coverage, or create test cases for Python code.

# Clear about both what and when
description: >-
  Create or update database migrations. Use when schema changes are needed,
  the user mentions migrations, or new models are added.
```

**Bad examples:**

```yaml
# Too vague - will trigger on unrelated requests
description: Helps with code.

# Too specific - won't trigger on natural language
description: >-
  Generate exactly 3 pytest parametrized test functions for pure mathematical
  functions accepting two float arguments.

# Missing "when" - agent can't decide when to activate
description: Generates documentation for API endpoints.
```

**Keyword strategy:** Include the 3-5 most common ways a user would phrase the request. Think about synonyms: "test" / "spec" / "coverage", "deploy" / "ship" / "release".

## Body Guidelines

- **Length**: Under 500 lines (aim for under 200)
- **Structure**: Use markdown headers for clear sections
- **Examples**: Include input/output pairs — more effective than descriptions
- **Templates**: Use rigid templates for structured output, flexible guidance otherwise
- **References**: Tell the agent when and why to load supporting files
- **Conciseness**: Only include information the agent doesn't already know

## Name Validation

Names must:
- Start with a lowercase letter
- Contain only lowercase letters, digits, and hyphens
- Be 1-64 characters long
- Match the containing directory name
- Regex: `^[a-z][a-z0-9-]{0,63}$`

**Good names:** `test-generator`, `deploy`, `code-review`, `skill`
**Bad names:** `Test_Generator`, `my skill`, `a-very-long-name-that-goes-on-and-on-and-exceeds-the-sixty-four-character-limit-for-skill-names`
