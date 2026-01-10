# Unit Test Suite

Unit tests verify the core functionality of the install script and polyfill scripts. These tests run in isolated temporary directories and do not require external AI agents.

## Test Organization

```
tests/unit/
├── install/                 # Install script tests
│   ├── fresh-install.sh    # New project installation
│   ├── idempotency.sh      # Rerun behavior
│   ├── merging.sh          # Merging with existing configs
│   └── special-cases.sh    # Edge cases (dry-run, polyfill updates)
└── polyfills/
    └── claude-agentsmd.sh  # Claude polyfill script tests
```

## Running Unit Tests

```sh
# From repository root
./tests/test-unit.sh          # Run all unit tests
./tests/test-unit.sh -v       # Verbose mode with full output
```

## Test Infrastructure

### Test Runner (`test-unit.sh`)

The test runner provides:

1. **Test discovery**: Automatically finds all `test_*()` functions in `*.sh` files
2. **Isolated execution**: Each test runs in a fresh temporary directory
3. **Assertion helpers**: Built-in functions for common test assertions
4. **Debug preservation**: Failed tests preserve their temp directories for inspection
5. **Pretty output**: Colored, formatted test results with progress indicators

### Test Function Signature

All test functions follow this pattern:

```sh
test_descriptive_name() {
	local project_dir="$1"

	# Test setup and execution
	# ...

	# Assertions
	assert_file_exists "path/to/file" &&
	assert_file_contains "path/to/file" "expected content"
}
```

**Important**: Test functions receive a `project_dir` argument pointing to a temporary directory. Tests should:
- Use relative paths within `project_dir`
- Return 0 (success) or non-zero (failure)
- Chain assertions with `&&` to fail fast

### Assertion Helpers

The test runner provides these assertion functions:

#### `assert_file_exists(file, [description])`

Verify a file exists.

```sh
assert_file_exists "AGENTS.md"
assert_file_exists ".claude/settings.json" "Claude config should exist"
```

#### `assert_file_not_exists(file, [description])`

Verify a file does not exist.

```sh
assert_file_not_exists ".gemini/settings.json"
```

#### `assert_file_contains(file, pattern, [description])`

Verify a file contains a pattern (uses `grep -q`).

```sh
assert_file_contains ".claude/settings.json" "claude/agentsmd.sh"
assert_file_contains "AGENTS.md" "My custom instructions"
```

#### `assert_json_has_key(file, key, [description])`

Verify a JSON file has a specific key path.

```sh
assert_json_has_key ".claude/settings.json" "hooks.SessionStart"
assert_json_has_key ".gemini/settings.json" "context.fileName"
```

**Note**: Key paths use dot notation (`parent.child.grandchild`).

### Helper Functions

#### `create_temp_project()`

Creates a temporary directory for test execution.

```sh
temp_dir=$(create_temp_project)
```

**Note**: The test runner automatically creates and manages temp directories. Tests should use the `project_dir` parameter instead of calling this directly.

#### `run_install(project_dir, args...)`

Runs the install script in the specified directory with given arguments.

```sh
run_install "$project_dir" -y .              # Install all agents
run_install "$project_dir" -y . claude       # Install Claude only
run_install "$project_dir" -n .              # Dry run
```

## Test Suites

### install/fresh-install.sh

Tests installation into fresh projects with no existing configuration.

**Test cases:**
- `test_fresh_install_all_agents` - Install all supported agents
- `test_fresh_install_claude_only` - Install only Claude support
- `test_fresh_install_gemini_only` - Install only Gemini support

**What's verified:**
- Correct files are created
- AGENTS.md template is created
- Agent-specific config files are created
- Polyfill scripts are installed (when needed)
- JSON configs have correct structure

### install/idempotency.sh

Tests that rerunning the install script is safe and idempotent.

**Test cases:**
- `test_idempotent_rerun` - Rerun shows SKIP status for existing files
- `test_skip_when_already_configured` - Existing configs are preserved
- `test_existing_agents_md_preserved` - Custom AGENTS.md content is not overwritten

**What's verified:**
- Rerun detects existing installations
- Output shows "SKIP" for already-configured items
- Existing content is preserved
- No duplicate configuration entries

### install/merging.sh

Tests merging of universal-agents configuration with existing project configs.

**Test cases:**
- `test_merge_claude_existing_permissions` - Merge with existing Claude permissions
- `test_merge_gemini_existing_context` - Merge with existing Gemini context

**What's verified:**
- Existing config values are preserved
- New universal-agents config is added
- Custom fields remain intact
- JSON structure is valid after merge

### install/special-cases.sh

Tests edge cases and special installation scenarios.

**Test cases:**
- `test_polyfill_update` - Outdated polyfill scripts are updated
- `test_dry_run_no_changes` - Dry-run mode makes no filesystem changes

**What's verified:**
- Polyfill scripts are updated when needed
- Dry-run output shows intended actions
- Dry-run creates no files
- Update detection works correctly

### polyfills/claude-agentsmd.sh

Tests the Claude AGENTS.md polyfill script that runs at session start.

**Test cases:**
- `test_no_agentsmd_files` - No output when no AGENTS.md files exist
- `test_single_root_agentsmd` - Single root file loads correctly
- `test_multiple_nested_agentsmd` - Multiple AGENTS.md files are discovered
- `test_nested_agentsmd_without_root` - Nested files work without root
- `test_output_format_structure` - Output has correct XML-like structure
- `test_special_characters_in_agentsmd` - Special characters are preserved
- `test_empty_agentsmd_file` - Empty files don't cause errors

**What's verified:**
- AGENTS.md file discovery
- Output format structure (XML-like tags)
- File listing in `<available_agentsmd_files>`
- Root content in `<root_agentsmd>` section
- Special character handling
- Edge case robustness

**Note**: These tests run the polyfill script directly with `CLAUDE_PROJECT_DIR` environment variable set.

## Writing New Unit Tests

### 1. Choose the Right Test File

Add tests to existing files based on what you're testing:
- **Installation behavior** → `install/fresh-install.sh`
- **Rerun/idempotency** → `install/idempotency.sh`
- **Config merging** → `install/merging.sh`
- **Edge cases** → `install/special-cases.sh`
- **Polyfill scripts** → `polyfills/<agent>-<feature>.sh`

Or create a new file if testing a new category.

### 2. Follow the Test Function Pattern

```sh
test_my_new_test_case() {
	local project_dir="$1"

	# Setup: Create any needed files
	echo "content" > "test-file.txt"

	# Execute: Run the code under test
	run_install "$project_dir" -y .

	# Assert: Verify expected behavior
	assert_file_exists "AGENTS.md" &&
	assert_file_contains "AGENTS.md" "expected content" &&
	assert_json_has_key ".claude/settings.json" "hooks.SessionStart"
}
```

### 3. Test Naming Convention

- Function name: `test_description_with_underscores`
- Converts to display name: `description-with-underscores`
- Use descriptive names that explain what's being tested

### 4. Assertion Chaining

Chain assertions with `&&` to fail fast:

```sh
# Good - stops at first failure
assert_file_exists "file1" &&
assert_file_exists "file2" &&
assert_file_contains "file1" "content"

# Bad - continues after failures
assert_file_exists "file1"
assert_file_exists "file2"
assert_file_contains "file1" "content"
```

### 5. Custom Descriptions

Provide clear descriptions for assertions:

```sh
assert_file_exists ".claude/settings.json" "Claude should be configured"
assert_file_contains "AGENTS.md" "# Project" "Template should be created"
```

### 6. Testing Output

Capture command output to test it:

```sh
local output=$(run_install "$project_dir" -n . 2>&1)
echo "$output" | grep -q "Dry-run mode"
echo "$output" | grep -q "SKIP.*AGENTS.md"
```

### 7. Cleanup

The test runner automatically cleans up successful tests. Failed tests preserve their temp directory for debugging.

```
Debug: Project preserved at: /tmp/install_test_ABC123
```

You can inspect the preserved directory to debug test failures.

## Test Execution Flow

1. **Discovery**: Test runner finds all `test_*()` functions
2. **Grouping**: Groups tests by file into suites (e.g., `install:fresh-install`)
3. **Isolation**: Creates fresh temp directory for each test
4. **Execution**: Runs test function in temp directory
5. **Assertion**: Test returns 0 (pass) or non-zero (fail)
6. **Cleanup**: Successful tests cleaned up, failures preserved
7. **Summary**: Final pass/fail count displayed

## Debugging Failed Tests

When a test fails:

1. **Check the output**: The test runner shows assertion failures
2. **Inspect the directory**: Failed tests preserve their temp directory
3. **Examine files**: Look at generated configs, AGENTS.md, etc.
4. **Re-run verbose**: Use `-v` flag to see full output
5. **Run manually**: Change to temp directory and run commands manually

### Verbose Mode Example

```sh
./tests/test-unit.sh -v

=== install:fresh-install ===

Test: all-agents
  [full install script output]
  [all assertions and their results]
  PASS
```

## Common Test Patterns

### Testing File Creation

```sh
run_install "$project_dir" -y . claude
assert_file_exists ".claude/settings.json"
assert_file_exists "AGENTS.md"
```

### Testing File Content

```sh
echo "# Custom" > "AGENTS.md"
run_install "$project_dir" -y .
assert_file_contains "AGENTS.md" "# Custom"
```

### Testing JSON Structure

```sh
run_install "$project_dir" -y . claude
assert_json_has_key ".claude/settings.json" "hooks.SessionStart"
assert_json_has_key ".claude/settings.json" "permissions.allow"
```

### Testing Dry Run

```sh
local output=$(run_install "$project_dir" -n . 2>&1)
echo "$output" | grep -q "CREATE.*AGENTS.md"
assert_file_not_exists "AGENTS.md"
```

### Testing Merging

```sh
mkdir -p ".claude"
cat > ".claude/settings.json" <<'EOF'
{"permissions": {"allow": ["Bash(npm *)"]}}
EOF

run_install "$project_dir" -y . claude

assert_file_contains ".claude/settings.json" "npm" &&
assert_file_contains ".claude/settings.json" "claude/agentsmd.sh"
```

### Testing Polyfill Scripts

```sh
cat > "$project_dir/AGENTS.md" <<-end_agentsmd
	# Test Content
end_agentsmd

local output
output=$(CLAUDE_PROJECT_DIR="$project_dir" sh "$REPO_ROOT/.agents/polyfills/claude/agentsmd.sh")

echo "$output" | grep -q "<root_agentsmd>" &&
echo "$output" | grep -q "# Test Content"
```

## Performance Considerations

Unit tests should be fast since they run in isolated environments:

- Each test creates/destroys a temp directory
- No network calls
- No external agent dependencies
- Typical full suite run: < 10 seconds

If a test is slow, consider:
- Are you doing unnecessary file operations?
- Can you test the same thing more efficiently?
- Should this be split into multiple focused tests?
