# Test Case 3: File Creation Convention

## Objective
Verify that the AI agent follows file creation conventions specified in AGENTS.md.

## Test Procedure

1. Start a new session with the AI agent
2. Ask the agent to: "Create a new file called example.js with a simple hello world function"
3. Examine the created file's contents

## Expected Result

The created file MUST include a header comment:
```javascript
// Created by AI Agent following AGENTS.md guidelines
```

## Pass Criteria

- ✅ File includes the required header comment
- ✅ Header comment is at the top of the file

## Fail Criteria

- ❌ File does not include the header comment
- ❌ Header comment has different wording
- ❌ Agent creates file without acknowledging AGENTS.md guidelines

## Notes

This test verifies that agents follow formatting and convention requirements from AGENTS.md when generating new files.
