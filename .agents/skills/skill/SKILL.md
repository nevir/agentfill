---
name: skill
description: >-
  Create or update portable agent skills in .agents/skills/. Use when asked
  to create a skill, improve an existing skill, build a slash command, or
  set up a reusable workflow. Guides through skill design, writes SKILL.md
  with proper frontmatter, and creates supporting files.
---

# /skill

Create or update portable agent skills in `.agents/skills/` that work across Claude Code, Gemini CLI, and other agents supporting the [Agent Skills specification](https://agentskills.io).

## Determine the Mode

**Creating a new skill** — the user wants a skill that doesn't exist yet. Follow the full workflow below.

**Updating an existing skill** — the user wants to modify a skill in `.agents/skills/`. Read the existing SKILL.md and supporting files first, then apply changes following the same quality principles.

## Creating a New Skill

### Step 1: Understand

Ask the user to describe what they want the skill to do. Gather:

- **Purpose**: What task does this skill help with?
- **Trigger**: When should an agent activate this skill? What would the user say?
- **Examples**: 2-3 concrete examples of the skill in action (input/output or before/after)

If the user is vague, suggest concrete examples to refine the scope. A good skill is focused — it does one thing well. If the request covers multiple distinct tasks, suggest splitting into separate skills.

### Step 2: Research

Before writing the skill:

- Search for existing patterns, conventions, and code related to the skill's domain
- Check `.agents/skills/` for existing skills that might overlap
- Identify project-specific conventions the skill should follow
- Note any tools, scripts, or references the skill might need to bundle

### Step 3: Plan

Design the skill and present the plan to the user before writing:

- **Name**: lowercase-hyphenated, 1-64 characters, descriptive. This becomes the `/slash-command`.
- **Description**: 1-2 sentences covering WHAT it does and WHEN to use it. Include keywords matching how users naturally phrase the request. This is the most important field — it determines when agents auto-activate the skill.
- **Instructions outline**: Key steps, rules, and examples. Only include information the agent doesn't already know.
- **Supporting files**: Decide what goes in SKILL.md vs `references/`:
  - **In SKILL.md**: Rules and content the agent needs in every or most activations
  - **In references/**: Content needed only in specific scenarios (e.g., "when creating a new script from scratch")
  - Each reference file needs a clear trigger condition — not just "overflow"
  - Multiple focused files are better than one monolithic reference

### Step 4: Create

Create the skill directory and files:

1. Create `.agents/skills/<name>/`
2. Write `SKILL.md` with YAML frontmatter and markdown body
3. Add supporting files as needed (`references/`, `scripts/`, `assets/`)

Use the SKILL.md template below. For the full frontmatter reference, read `references/skill-specification.md`.

**SKILL.md template:**

```yaml
---
name: <lowercase-hyphenated-name>
description: >-
  <What it does>. <When to use it — include trigger keywords>.
---

# <Skill Title>

<Brief overview — 1-2 sentences.>

## <Main workflow or instructions>

<Steps, rules, examples. Only include what the agent doesn't already know.>
```

**Key rules:**
- Keep the body under 500 lines (aim for under 200 for workflow skills; up to 400 for style/rules skills)
- Use universal frontmatter fields (`name`, `description`) for portability
- Agent-specific fields (like Claude's `allowed-tools`) are safe to add but will be ignored by other agents
- Use input/output examples — they're more effective than descriptions
- Reference supporting files from the body so the agent knows when to load them

### Step 5: Validate

Run the validation script to check structure and frontmatter:

```sh
.agents/skills/skill/scripts/validate-skill.sh .agents/skills/<name>
```

Also verify manually:

- [ ] `name` is lowercase-hyphenated, 1-64 characters
- [ ] `description` explains WHAT and WHEN (includes trigger keywords)
- [ ] Body is focused — no information the agent already knows
- [ ] No unnecessary agent-specific assumptions in instructions
- [ ] Supporting files are referenced from SKILL.md
- [ ] Scripts are executable (`chmod +x`)

### Step 6: Test

Suggest the user test the skill:

1. Start a new agent session (skills are discovered at session start)
2. Ask the agent to perform the task the skill handles
3. Verify the skill activates and produces correct results
4. If it doesn't activate, check the description for missing trigger keywords

## Updating an Existing Skill

1. **Read** the existing SKILL.md and all supporting files
2. **Understand** what changes are needed and why
3. **Update** the files, keeping the same quality principles (conciseness, portability, good description)
4. **Validate** with the validation script
5. **Note**: Claude Code hot-reloads skill changes (v2.1.0+) — no restart needed

## Design Principles

### Description Quality Matters Most

The description determines whether agents auto-activate the skill. Write it as if explaining to a colleague when they should reach for this tool. Include the 3-5 most natural phrasings a user would use.

### Concise is Key

Only include information the agent doesn't already know. If the agent can figure something out from context, don't spell it out. Challenge every paragraph.

### Portability First

Skills in `.agents/skills/` are shared across all configured agents. Stick to universal frontmatter fields. Describe actions rather than naming agent-specific tools. Use forward slashes for paths.

### One Skill, One Job

Each skill should have a focused purpose. If a skill tries to do too many things, it will either trigger too broadly or its instructions will be too vague to be useful. Split into separate skills instead.

### Right-Size Your References

Not all content belongs in `references/`. If the agent needs content in most activations, it belongs in SKILL.md. Reference files are for content needed only in specific scenarios.

**In SKILL.md** (loaded every activation):
- Core rules, conventions, and patterns
- Examples of correct/incorrect usage
- Common decision guidance

**In focused reference files** (loaded on demand):
- Full code templates (e.g., "read when creating a new script from scratch")
- Detailed rules for uncommon scenarios (e.g., "read when formatting tables")
- Extended examples for edge cases

**Reference file guidelines:**
- Each file should have a clear load trigger stated in SKILL.md
- Name files by scenario: `new-script-template.md` not `full-guide.md`
- Multiple small files (50-150 lines each) beat one large file
- A reference that's always loaded defeats the purpose — merge it into SKILL.md
