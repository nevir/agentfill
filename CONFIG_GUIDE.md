# AGENTS.md Configuration Guide

This guide explains how to configure different AI coding agents to support the `AGENTS.md` standard.

## Agent Configuration Summary

| Agent | Native Support | Configuration Required | Config File |
|-------|---------------|------------------------|-------------|
| Aider | ✅ Yes | Yes | `.aider.conf.yml` |
| Gemini CLI | ✅ Yes | Yes | `.gemini/settings.json` |
| Cursor/Codex | ✅ Yes | No | None (native) |
| Claude Code | ❌ No | Yes (workaround) | `CLAUDE.md` or hooks |

---

## Aider Configuration

**Status**: Officially supported

**Configuration File**: `.aider.conf.yml`

```yaml
# Aider configuration file
read:
  - AGENTS.md
```

**How it works**: Aider automatically reads the specified files into context at session start.

**Reference**: [Aider Documentation](https://aider.chat/docs/config.html)

---

## Gemini CLI Configuration

**Status**: Officially supported (with configuration)

**Configuration File**: `.gemini/settings.json`

```json
{
  "contextFileName": "AGENTS.md"
}
```

**How it works**: Gemini CLI looks for the specified context file at the repository root. By default, it looks for `GEMINI.md` or `AGENT.md`.

**Reference**: [Gemini CLI Documentation](https://github.com/google-gemini/gemini-cli)

---

## Cursor/Codex Configuration

**Status**: Native support

**Configuration**: None required

**How it works**: Both Cursor and Codex natively support `AGENTS.md`. They automatically detect and load the file from the repository root.

**Reference**: [AGENTS.md Official Site](https://agents.md)

---

## Claude Code Configuration

**Status**: Not officially supported (workarounds available)

**Feature Request**: [anthropics/claude-code#6235](https://github.com/anthropics/claude-code/issues/6235)

### Approach 1: File Import (Recommended)

**Configuration File**: `CLAUDE.md`

```markdown
# In ./CLAUDE.md

@AGENTS.md
```

**How it works**: Claude Code's `@` import syntax loads the entire contents of `AGENTS.md` into context.

**Pros**:
- Simple, clean solution
- No duplication of content
- Works with relative paths

**Cons**:
- Requires maintaining a `CLAUDE.md` file

**Credit**: [@coygeek on GitHub](https://github.com/anthropics/claude-code/issues/6235#issuecomment-3211493741)

---

### Approach 2: SessionStart Hook

**Configuration Files**: `.claude/settings.json` and `.claude/hooks/append_agentsmd_context.sh`

**.claude/settings.json**:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/append_agentsmd_context.sh"
          }
        ]
      }
    ]
  }
}
```

**.claude/hooks/append_agentsmd_context.sh**:
```bash
#!/bin/bash

# Find all AGENTS.md files in current directory and subdirectories
echo "=== AGENTS.md Files Found ==="
find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
    echo "--- File: $file ---"
    cat "$file"
    echo ""
done
```

**How it works**: Executes a shell script at session start that finds and outputs all `AGENTS.md` files in the project.

**Pros**:
- Supports multiple `AGENTS.md` files in monorepos
- Can be configured at user level (`~/.claude/settings.json`) for all projects

**Cons**:
- More complex setup
- Requires executable permissions on the script

**Credit**: [@DylanLIiii on GitHub](https://github.com/anthropics/claude-code/issues/6235#issuecomment-3213771311)

---

### Approach 3: Symbolic Link (Not Recommended)

**Command**:
```bash
ln -s AGENTS.md CLAUDE.md
```

**How it works**: Creates a symbolic link where `CLAUDE.md` points to `AGENTS.md`.

**Pros**:
- Simple one-command setup

**Cons**:
- Doesn't work with `@` imports in `AGENTS.md` that use relative paths
- Platform-specific (doesn't work on Windows)
- Can confuse version control

**Credit**: [@parfenovvs on GitHub](https://github.com/anthropics/claude-code/issues/6235#issuecomment-3213771311)

---

## Recommendations

### For New Projects
1. Create `AGENTS.md` at the repository root
2. Configure each agent as shown above
3. Use `AGENTS.md` as the single source of truth for all agents

### For Existing Projects with CLAUDE.md
1. Keep your existing `CLAUDE.md` for Claude-specific instructions
2. Move general instructions to `AGENTS.md`
3. Use `@AGENTS.md` in `CLAUDE.md` to import the shared instructions

### For Monorepos
1. Place `AGENTS.md` at both root and subproject levels
2. Use SessionStart hooks for Claude Code to load all files
3. Each subproject's `AGENTS.md` provides local context

---

## Testing Configuration

After configuring your agent, run the test cases in `tests/` to verify that `AGENTS.md` is being loaded correctly.

Quick verification:
1. Start a new session with your AI agent
2. Ask: "What is the secret code?"
3. Expected response: `AGENTS_MD_VERIFIED_42`

If the agent responds correctly, your configuration is working!

For complete test suite, see: `tests/run-tests.md`
