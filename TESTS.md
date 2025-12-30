# AGENTS.md Test Harness

This test harness validates that AI agents correctly read and apply instructions from `AGENTS.md` files.

## Test Structure

Each test is a directory containing:
- `prompt.md` - The prompt to give the agent (never mentions AGENTS.md)
- `expected.md` - Pass/fail criteria and expected behavior

## Testing Philosophy

All tests should verify that agents:
1. Read AGENTS.md before performing tasks
2. Follow instructions specified in AGENTS.md
3. Prioritize AGENTS.md over other documentation sources
4. Avoid accidental context leakage (prompts never mention AGENTS.md, test infrastructure, or file paths)

## How to Run These Tests

**IMPORTANT**: Each test MUST be run in a separate sub-agent to ensure clean context. Do not run tests in your current context.

### Running All Tests

1. List all test directories (any directory except this harness file)
2. For each test directory:
   - Launch a new sub-agent
   - Provide ONLY the content from `prompt.md`
   - Compare the agent's response against `expected.md`
   - Mark as PASS or FAIL
3. Output results in the format specified below

### Output Format

When running tests, output results in this format:

```
## Test Results

[Test Name]: PASS/FAIL
  Expected: [brief description]
  Actual: [what happened]

[Test Name]: PASS/FAIL
  Expected: [brief description]
  Actual: [what happened]

---
Summary: X/Y tests passed
```

### Example Output

```
## Test Results

secret-code: PASS
  Expected: Response contains "AGENTS_MD_VERIFIED_42"
  Actual: Agent responded with "AGENTS_MD_VERIFIED_42"

file-creation: PASS
  Expected: File contains header "// Created by AI Agent following AGENTS.md guidelines"
  Actual: File created with correct header

repo-description: FAIL
  Expected: First sentence mentions "AGENTS.md polyfill project"
  Actual: Description did not mention AGENTS.md polyfill

color-preference: PASS
  Expected: Recommends "teal" as primary color
  Actual: Agent suggested teal

---
Summary: 3/4 tests passed
```

## Important Notes

- **Never mention AGENTS.md in prompts**: The prompts are intentionally generic to test automatic discovery
- **Clean context per test**: Each test MUST run in a fresh sub-agent
- **No hardcoded test list**: Tests are discovered by listing directories
- **Self-documenting**: Each test's `expected.md` contains its own pass criteria
