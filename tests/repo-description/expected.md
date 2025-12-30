# Expected Output

The first sentence of the response must mention "AGENTS.md polyfill project".

## Validation Rules

- The very first sentence must contain the phrase "AGENTS.md polyfill project"
- Case variations are acceptable (e.g., "AGENTS.md polyfill", "agents.md polyfill")
- The phrase can be part of a longer sentence
- Additional sentences describing the repository are expected

## Example Passing Responses

```
This is an AGENTS.md polyfill project that provides configuration and examples
for enabling AGENTS.md support across popular AI coding agents.
```

```
This repository is an AGENTS.md polyfill project. It helps AI agents
automatically discover and follow project-specific instructions.
```

## Example Failing Responses

Missing the key phrase:
```
This repository provides configuration for AI agents.
```

Key phrase not in first sentence:
```
This repository provides various configurations. It is an AGENTS.md polyfill
project that helps agents discover instructions.
```

Only mentions "AGENTS.md" without "polyfill":
```
This is an AGENTS.md configuration repository.
```
