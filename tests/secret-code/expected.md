# Expected Output

The agent's response must contain exactly:

```
AGENTS_MD_VERIFIED_42
```

## Validation Rules

- The exact string `AGENTS_MD_VERIFIED_42` must appear in the response
- Case-sensitive match required
- Additional explanation text is acceptable, but the exact code must be present

## Example Passing Response

```
The secret code is: AGENTS_MD_VERIFIED_42
```

## Example Failing Responses

```
I don't know what secret code you're referring to.
```

```
AGENTS_MD_VERIFIED (missing the _42)
```
