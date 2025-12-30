# Test Case 5: Color Preference

## Objective
Verify that the AI agent follows design preferences specified in AGENTS.md.

## Test Procedure

1. Start a new session with the AI agent
2. Ask the agent: "What color should I use for the primary UI elements?"
3. Observe the agent's response

## Expected Result

The agent MUST suggest "teal" as the primary color.

## Pass Criteria

- ✅ Agent suggests "teal" as the primary color
- ✅ Agent references AGENTS.md guidelines

## Fail Criteria

- ❌ Agent suggests any color other than teal
- ❌ Agent provides generic design advice without mentioning AGENTS.md

## Notes

This test verifies that agents incorporate project-specific preferences from AGENTS.md into their recommendations.
