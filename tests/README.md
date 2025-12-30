# AGENTS.md Test Suite

This directory contains test cases to verify that AI coding agents correctly read and follow instructions in `AGENTS.md`.

## Test Cases

1. **Secret Response Code** (`test-case-1-secret-code.md`)
   - Tests: Basic AGENTS.md file loading
   - Method: Ask for a secret code defined in AGENTS.md

2. **Preferred Build Tool** (`test-case-2-build-tool.md`)
   - Tests: Following tool preferences over detected files
   - Method: Request dependency installation

3. **File Creation Convention** (`test-case-3-file-creation.md`)
   - Tests: Following coding conventions
   - Method: Create a new file and verify header

4. **Priority Check** (`test-case-4-priority-check.md`)
   - Tests: AGENTS.md priority over other documentation
   - Method: Ask for repository description

5. **Color Preference** (`test-case-5-color-preference.md`)
   - Tests: Following project-specific preferences
   - Method: Ask for UI color recommendations

## Running Tests

### Manual Testing

For each test case:
1. Start a fresh session with your AI agent
2. Follow the procedure in the test case file
3. Compare the result against expected outcomes
4. Mark as pass/fail based on criteria

### Automated Testing

See `run-tests.md` for instructions on running automated test verification.

## Test Results Template

```markdown
## Test Results - [Agent Name] - [Date]

| Test Case | Result | Notes |
|-----------|--------|-------|
| Test 1: Secret Code | ✅/❌ | |
| Test 2: Build Tool | ✅/❌ | |
| Test 3: File Creation | ✅/❌ | |
| Test 4: Priority Check | ✅/❌ | |
| Test 5: Color Preference | ✅/❌ | |

Overall: X/5 tests passed
```

## Agent-Specific Notes

### Aider
- Configured via `.aider.conf.yml`
- Should automatically read AGENTS.md

### Gemini CLI
- Configured via `.gemini/settings.json`
- Should automatically read AGENTS.md

### Claude Code
- Configured via `CLAUDE.md` (workaround)
- May need explicit reference to AGENTS.md

### Cursor/Codex
- Native AGENTS.md support
- No additional configuration needed
