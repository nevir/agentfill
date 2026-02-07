# agentfill Context

Project-specific conventions for creating skills in an [agentfill](https://github.com/nevir/agentfill) project.

## Shared Skills Directory

Skills live in `.agents/skills/` at the project root. This directory is symlinked to each agent's native skill directory:

```
.agents/skills/my-skill/SKILL.md
    ↓ symlinked
.claude/skills/ → ../.agents/skills/
.gemini/skills/ → ../.agents/skills/
```

This means a single skill works across all configured agents without duplication.

## Agent-Specific Notes

### Claude Code

- **Native support** — skills are automatically discovered from `.claude/skills/`
- **Hot reload** (v2.1.0+) — changes to SKILL.md are picked up without restarting the session
- **Symlink display bug** ([#14836](https://github.com/anthropics/claude-code/issues/14836)) — symlinked skills work but don't appear in the `/skills` list output. The skill is still usable.
- **Slash commands** — skills are invocable as `/skill-name`

### Gemini CLI

- **Experimental** — requires `experimental.skills: true` in `~/.gemini/settings.json`
- **Explicit activation** — skills need to be enabled via `/skills enable <name>`
- **Same SKILL.md format** — the Agent Skills spec is shared between Claude and Gemini

## Existing Skills

Check `.agents/skills/` for existing skills before creating new ones to avoid overlap:

```sh
ls -1 .agents/skills/
```

## Testing Across Agents

To test a skill works portably:

1. **Claude Code**: Start a new session, invoke `/skill-name` or trigger via natural language
2. **Gemini CLI**: Ensure `experimental.skills: true` is set, run `/skills reload`, then test

If a skill uses agent-specific frontmatter (like Claude's `allowed-tools`), verify the skill still works on other agents where those fields are ignored.

## Conventions

- Skills created in this project should prioritize **portability** — use universal frontmatter fields
- If a skill genuinely needs agent-specific features, document which fields are agent-specific in the SKILL.md body
- Follow the [Agent Skills Best Practices](../../docs/Agent%20Skills.md) documentation for detailed guidance
