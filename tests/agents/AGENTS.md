# Test Design Guidelines for AGENTS.md

When creating tests for AGENTS.md support, follow these principles to ensure tests are reliable, portable, and maintainable.

## Core Principles

### 1. Deterministic Tests

Tests must have exactly one correct answer. Avoid any ambiguity in what constitutes a passing response.

**Good:**

```markdown
# prompt.md

What is the magic word?

# expected.md

XYZZY
```

**Bad:**

```markdown
# prompt.md

Can you describe this repository?

# expected.md

(any natural language description could vary)
```

### 2. Exact String Matching

Expected outputs should use exact string matching with whitespace trimming. This keeps validation simple and unambiguous.

- Use precise, literal expected values
- Avoid patterns, regex, or fuzzy matching
- Keep expected outputs as short as possible

### 3. No Privileged Operations

Tests should only verify agent text output. Never require:

- File creation or modification
- Shell command execution
- Network requests
- Any tools beyond basic text response

This ensures tests can run safely in any environment.

**Bad - Requires file writing:**

```markdown
# prompt.md

Create a file called test.txt with "hello" in it.
```

_Problem: Test depends on privileged file operations_

### 4. Clear Prompts

Prompts should be direct and unambiguous about what response is expected.

**Good:**

```markdown
What is the verification code?
```

**Bad:**

```markdown
Tell me about the verification process and what codes might be involved.
```

### 5. Test Scope

Focus tests on verifying AGENTS.md loading and polyfill behavior, not general agent capabilities.

Don't test:

- Agent reasoning ability
- General instruction-following capability (varies by agent)
- Complex multi-step interactions
- Agent-specific behavior quirks

Do test:

- Whether AGENTS.md was loaded
- Specific polyfill features (nested AGENTS.md, scoped instructions, etc.)
- Configuration correctness
- Edge cases in AGENTS.md loading behavior

**Bad - Testing agent capability, not AGENTS.md loading:**

```markdown
# prompt.md

What is 2+2?

# expected.md

4
```

_Problem: Doesn't verify AGENTS.md was read_

### 6. Avoid Codebase Searches

**Critical:** Tests must not be answerable by searching the codebase. Agents often search for answers when they don't know them, which defeats the purpose of testing AGENTS.md loading.

**Bad - Agent can find answer by searching:**

```markdown
# prompt.md

What is the verification code?

# expected.md

XYZZY
```

_Problem: Agent can grep the codebase for "verification code" and find the answer in AGENTS.md or test files._

**Good - Natural wrong answer, AGENTS.md provides override:**

```markdown
# prompt.md

What is 2 + 2?

# expected.md

5
```

_Why this works: Without AGENTS.md, agents naturally answer "4". Only with AGENTS.md loaded do they override to "5"._

**Design principle:** Choose prompts where:
1. Agents have a clear, natural default answer (the "wrong" answer)
2. AGENTS.md provides an explicit override to a different answer (the "right" answer for the test)
3. The question cannot be answered by searching project files

This ensures the test genuinely validates that AGENTS.md was loaded and honored, rather than testing the agent's search capabilities.

### 7. Self-Contained AGENTS.md Files

**Critical for multi-file tests:** Each AGENTS.md file in a test must be completely self-contained and must NOT reference other AGENTS.md files, contexts, or test infrastructure.

**Bad - References other contexts:**

```markdown
# sandbox/AGENTS.md

The project suffix is: PROJECT

This should be combined with the user prefix from the global AGENTS.md.
```

_Problem: Mentions "global AGENTS.md" - agent could search for this and find the answer without the file being properly loaded._

**Good - Self-contained:**

```markdown
# sandbox/AGENTS.md

When asked about code parts, the **project suffix** is: `PROJECT`

When combining codes, use the format: `{prefix}_{suffix}`
```

_Why this works: Provides only the information this file should contribute, without referencing other files._

**Design principle for multi-file tests:**
1. Each AGENTS.md provides a distinct piece of information
2. No file mentions other files, contexts, or test modes
3. Agent must have ALL files loaded to answer correctly
4. Searching the codebase won't reveal the complete answer

This ensures tests verify the polyfill's loading mechanism, not the agent's ability to find cross-references.

## File Structure

Each test consists of:

```
tests/test-name/
├── prompt.md      # The exact prompt to send to the agent
└── expected.md    # The exact expected response (whitespace-trimmed)
```

## Adding Instructions to Root AGENTS.md

When testing that AGENTS.md was loaded, add a corresponding instruction to the root `AGENTS.md` as needed:

```markdown
When asked "What is the magic word?", respond with exactly and only:

XYZZY
```

Use this format:

1. Clear trigger condition ("When asked...")
2. Explicit output format ("respond with exactly and only:")
3. Literal expected output (no variables or placeholders)

Note: Not all tests require custom instructions in the root AGENTS.md. Only add them when testing that specific instructions were loaded.

## Running Tests

```sh
# From repository root
./tests/test-agents.sh                   # All tests, all agents
./tests/test-agents.sh claude            # All tests on Claude
./tests/test-agents.sh basic-load        # One test, all agents
./tests/test-agents.sh claude basic-load # One test, one agent
./tests/test-agents.sh -v                # Verbose mode
```

## Test Execution Context

**Important:** Tests run from the repository root, and prompts are passed to agents via stdin (using `cat` and pipes). This means:

1. Agents see the prompt text, but **do not** know it came from `tests/`
2. `tests/AGENTS.md` (this file) should **not** be loaded (or at least honored) during test runs
3. Only the root `AGENTS.md` should influence test behavior
4. This isolation ensures tests accurately verify the polyfill configuration

Agents should:

1. Load the root `AGENTS.md` automatically (based on their configuration)
2. See instructions defined in the root `AGENTS.md`
3. Respond according to those instructions

If a test fails, it means the agent configuration isn't loading the root `AGENTS.md` properly.
