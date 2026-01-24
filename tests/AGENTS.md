# Test Suite Overview

This directory contains all tests for the universal-agents project. Tests are organized into two main categories: **unit tests** and **agent integration tests**.

## Test Structure

```
tests/
├── test-all.sh              # Master test runner (runs all test suites)
├── test-unit.sh             # Unit test runner (shell script tests)
├── test-agents.sh           # Agent integration test runner
├── _common/                 # Shared test utilities
│   ├── colors.sh           # Color definitions and helpers
│   ├── utils.sh            # Common utility functions
│   └── output.sh           # Test output formatting
├── unit/                    # Unit tests (see tests/unit/AGENTS.md)
└── agents/                  # Agent integration tests (see tests/agents/AGENTS.md)
```

## Running Tests

### All Tests

```sh
./tests/test-all.sh           # Run all test suites
./tests/test-all.sh -v        # Verbose mode with detailed output
```

### Individual Test Suites

```sh
./tests/test-unit.sh          # Run only unit tests
./tests/test-unit.sh -v       # Verbose mode

./tests/test-agents.sh        # Run all agent integration tests (4 parallel by default)
./tests/test-agents.sh -j 1   # Sequential execution
./tests/test-agents.sh -j 8   # Run 8 tests at once
./tests/test-agents.sh -v     # Verbose mode (disables parallel)
./tests/test-agents.sh claude # Run tests for specific agent
```

## Shared Test Utilities

The `_common/` directory contains shared libraries used across test suites:

### colors.sh

Provides ANSI color codes and color helper functions. Defines both basic colors and semantic colors for consistent output.

**Key functions:**
- `c(color_name, text)` - Colorize text with specified color
- `c_list(color_type, items...)` - Colorize a comma-separated list

**Semantic colors:**
- `color_error` (red) - Error messages
- `color_success` (green) - Success messages
- `color_warning` (yellow) - Warnings
- `color_agent` (cyan) - Agent names
- `color_test` (yellow) - Test names
- `color_command` (purple) - Commands
- `color_heading` (bold) - Section headings
- `color_suite` (blue) - Test suite names

### utils.sh

Common utility functions for string manipulation and error handling.

**Key functions:**
- `trim(string)` - Remove leading/trailing whitespace
- `indent(spaces, text)` - Indent multiline text
- `panic(exit_code, [show_usage], message)` - Fatal error handler

### output.sh

Test output formatting functions for consistent test result display.

**Key functions:**
- `print_test_running(test_name)` - Show spinner for running test
- `print_test_pass(test_name)` - Show success checkmark
- `print_test_fail(test_name)` - Show failure X
- `print_test_header_verbose(test_name)` - Verbose test header
- `print_test_result_verbose(result)` - Verbose PASS/FAIL
- `print_section_header(section_name)` - Section dividers

## Test Categories

### Unit Tests (`tests/unit/`)

Fast, isolated tests that verify specific functionality without requiring external agents. These tests run the install script and polyfill scripts in controlled environments.

**See [tests/unit/AGENTS.md](tests/unit/AGENTS.md) for detailed unit test documentation.**

### Agent Integration Tests (`tests/agents/`)

Tests that verify AGENTS.md support works correctly with real AI agents (Claude, Gemini, etc.). These tests ensure agents properly load and honor AGENTS.md instructions.

**See [tests/agents/AGENTS.md](tests/agents/AGENTS.md) for detailed agent test documentation.**

## Exit Codes

Tests follow standard exit code conventions:

- `0` - All tests passed
- `1` - One or more tests failed
- `2` - Tests skipped (e.g., no agents available for agent tests)

## Test Output Modes

### Default Mode

Displays a progress spinner while tests run, then shows pass/fail status:

```
=== install:fresh-install ===
✓ all-agents
✓ claude-only
✓ gemini-only

5/5 passed
```

### Verbose Mode (`-v`)

Shows detailed output for each test as it runs:

```
=== install:fresh-install ===

Test: all-agents
  [full test output...]
  PASS

Test: claude-only
  [full test output...]
  PASS
```

## Writing Tests

When adding new tests, follow these guidelines:

1. **Choose the right category**: Unit tests for script functionality, agent tests for AGENTS.md behavior
2. **Use shared utilities**: Import from `_common/` for consistency
3. **Follow naming conventions**: `test_description_with_underscores()` function names
4. **Provide clear assertions**: Use descriptive assertion messages
5. **Clean up resources**: Tests should clean up temporary files on success
6. **Preserve on failure**: Failed tests should preserve state for debugging

## Isolation from AGENTS.md

**Critical**: This `tests/AGENTS.md` file should NOT influence test behavior. Tests run from the repository root and should only load the root `AGENTS.md` file, not this one.

- Unit tests verify script behavior in isolated temporary directories
- Agent tests verify that agents load the correct AGENTS.md files based on polyfill configuration
- Neither test category should be affected by instructions in `tests/AGENTS.md`

This isolation ensures tests accurately verify the production behavior of the polyfills.
