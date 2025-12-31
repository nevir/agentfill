<!-- Created by AI Agent following AGENTS.md guidelines -->

# Expected Output

This test validates that agents can discover and follow AGENTS.md files in subdirectories, and that nested AGENTS.md instructions take precedence over root-level instructions when working in a subdirectory context.

## Validation Rules

### 1. File Creation - `outputs/nested-agents-md/summary.md`

The file MUST start with the project-specific header from the nested AGENTS.md:
```
<!-- Project-specific file created by AI Agent -->
```

**NOT** the root-level header:
```
<!-- Created by AI Agent following AGENTS.md guidelines -->
```

### 2. Project Secret Code

The agent's response must contain exactly:
```
NESTED_PROJECT_CODE_99
```

**NOT** the root-level secret code `AGENTS_MD_VERIFIED_42`.

### 3. Project Name

The agent's response must mention:
```
NestedTestProject
```

## Example Passing Response

```
I've created the summary file.

The project secret code is: NESTED_PROJECT_CODE_99

The project name is: NestedTestProject
```

**outputs/nested-agents-md/summary.md** content:
```markdown
<!-- Project-specific file created by AI Agent -->

# Project Summary

This is a simple test project for validating nested AGENTS.md support.
```

## Example Failing Responses

### FAIL - Using root-level header instead of nested
**outputs/nested-agents-md/summary.md**:
```markdown
<!-- Created by AI Agent following AGENTS.md guidelines -->

# Project Summary
...
```

### FAIL - Using root-level secret code
```
The project secret code is: AGENTS_MD_VERIFIED_42
```

### FAIL - No secret code response
```
I don't know the project secret code.
```

### FAIL - Wrong project name
```
The project name is: universal-agents
```

## Test Objective

This test verifies that:
1. Agents discover AGENTS.md files in subdirectories
2. Nested AGENTS.md instructions override root-level instructions
3. Context-aware instruction application (when working in a subdirectory)
