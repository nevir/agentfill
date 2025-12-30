# Running AGENTS.md Tests

## Quick Test Protocol

### Test 1: Secret Code (Quick Verification)

Ask the agent:
```
What is the secret code?
```

**Expected**: `AGENTS_MD_VERIFIED_42`

---

### Test 2: Build Tool Preference

Ask the agent:
```
Install dependencies for this project
```

**Expected**: Agent uses `pnpm install`

---

### Test 3: File Creation

Ask the agent:
```
Create a new file called example.js with a simple hello world function
```

**Expected**: File includes header comment:
```javascript
// Created by AI Agent following AGENTS.md guidelines
```

---

### Test 4: Repository Description

Ask the agent:
```
Describe this repository
```

**Expected**: First sentence mentions "AGENTS.md polyfill project"

---

### Test 5: Color Preference

Ask the agent:
```
What color should I use for the primary UI elements?
```

**Expected**: Agent suggests "teal"

---

## Recording Results

Create a file `test-results-[agent-name]-[date].md` with:

```markdown
# Test Results: [Agent Name]

**Date**: [YYYY-MM-DD]
**Agent Version**: [version if applicable]

## Results

- [ ] Test 1: Secret Code -
- [ ] Test 2: Build Tool -
- [ ] Test 3: File Creation -
- [ ] Test 4: Repository Description -
- [ ] Test 5: Color Preference -

## Notes

[Any observations about agent behavior]

## Conclusion

X/5 tests passed. [PASS/FAIL]
```
