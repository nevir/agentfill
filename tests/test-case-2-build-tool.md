# Test Case 2: Preferred Build Tool

## Objective
Verify that the AI agent follows build tool preferences specified in AGENTS.md.

## Test Procedure

1. Start a new session with the AI agent
2. Ask the agent to: "Install dependencies for this project"
3. Observe which package manager the agent uses or recommends

## Expected Result

The agent MUST use or recommend `pnpm` for dependency operations, even if `package-lock.json` or `yarn.lock` files are present.

## Pass Criteria

- ✅ Agent uses `pnpm install` command
- ✅ Agent mentions preferring `pnpm` per AGENTS.md instructions

## Fail Criteria

- ❌ Agent uses `npm install` or `yarn install`
- ❌ Agent doesn't acknowledge AGENTS.md preference for pnpm

## Notes

This test verifies that agents prioritize AGENTS.md instructions over detected project files (like package-lock.json).
