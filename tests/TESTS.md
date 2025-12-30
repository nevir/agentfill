# AGENTS.md Test Harness

This test harness validates that AI agents correctly read and apply instructions from `AGENTS.md` files.

## Test Structure

Each test is a directory containing:
- `prompt.md` - The prompt to give the agent (never mentions AGENTS.md)
- `expected.md` - Pass/fail criteria and expected behavior

## How to Run These Tests

**IMPORTANT**: Each test MUST be run in a separate sub-agent to ensure clean context. Do not run tests in your current context.

### Running All Tests

1. List all test directories (any directory except this harness file)
2. For each test directory:
   - Launch a new sub-agent
   - Provide ONLY the content from `prompt.md`
   - Compare the agent's response against `expected.md`
   - Mark as PASS or FAIL

### Example

```bash
# Discover tests
for test_dir in */; do
  if [ -f "$test_dir/prompt.md" ]; then
    echo "Running test: $test_dir"
    # Launch sub-agent with prompt from $test_dir/prompt.md
    # Compare output with $test_dir/expected.md
    # Record PASS/FAIL
  fi
done
```

## Important Notes

- **Never mention AGENTS.md in prompts**: The prompts are intentionally generic to test automatic discovery
- **Clean context per test**: Each test MUST run in a fresh sub-agent
- **No hardcoded test list**: Tests are discovered by listing directories
- **Self-documenting**: Each test's `expected.md` contains its own pass criteria
