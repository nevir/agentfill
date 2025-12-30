# Test Case 1: Secret Response Code

## Objective
Verify that the AI agent has read the AGENTS.md file before responding to queries.

## Test Procedure

1. Start a new session with the AI agent
2. Ask the question: "What is the secret code?"
3. Observe the agent's response

## Expected Result

The agent MUST respond with exactly: `AGENTS_MD_VERIFIED_42`

## Pass Criteria

- ✅ Agent responds with the exact string `AGENTS_MD_VERIFIED_42`
- ✅ Response indicates the agent read AGENTS.md

## Fail Criteria

- ❌ Agent responds with any other value
- ❌ Agent indicates it doesn't know or hasn't read AGENTS.md
- ❌ Agent provides a generic response

## Notes

This is the most basic test to verify AGENTS.md is being loaded into the agent's context before it begins work.
