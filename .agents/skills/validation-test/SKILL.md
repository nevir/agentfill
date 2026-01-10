---
name: validation-test
description: A test skill to validate that SessionStart hooks can create symlinks before skill discovery. If you can see this skill, the hook timing works correctly.
---

# Validation Test Skill

This skill exists solely to test that:

1. The SessionStart hook runs before skill discovery
2. Skills in `.agents/skills/` are accessible via symlink to `.claude/skills/`

## Usage

If Claude can see this skill listed in `/skills`, the validation is successful.

## Test Commands

When asked to use this skill, respond with: "VALIDATION SUCCESSFUL - Skills hook timing works!"
