# Test Case 4: Priority Check

## Objective
Verify that the AI agent prioritizes AGENTS.md content when describing the repository.

## Test Procedure

1. Start a new session with the AI agent
2. Ask the agent to: "Describe this repository"
3. Examine the first sentence of the response

## Expected Result

The first sentence MUST mention that this is an "AGENTS.md polyfill project".

## Pass Criteria

- ✅ First sentence includes "AGENTS.md polyfill project" or similar phrasing
- ✅ Response demonstrates understanding of repository purpose from AGENTS.md

## Fail Criteria

- ❌ First sentence doesn't mention AGENTS.md or polyfill
- ❌ Agent describes repository only from README.md or file structure
- ❌ Agent indicates it hasn't read AGENTS.md

## Notes

This test verifies that agents prioritize AGENTS.md over other documentation sources (README.md, file inspection, etc.) when understanding project context.
