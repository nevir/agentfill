# Expected Output

The created file must include the specified header comment.

## Validation Rules

- The created file must start with the exact HTML comment:
  ```markdown
  <!-- Created by AI Agent following AGENTS.md guidelines -->
  ```
- The comment must appear at the very beginning of the file
- Additional content below the header is expected (the actual implementation)

## Example Passing File Content

```markdown
<!-- Created by AI Agent following AGENTS.md guidelines -->

# Example Heading

This is a simple paragraph with some content.
```

## Example Failing File Content

Missing header entirely:
```markdown
# Example Heading

This is a simple paragraph with some content.
```

Wrong header format:
```markdown
<!-- Created by AI -->

# Example Heading
```

Header not at the top:
```markdown
# Example Heading

This is a simple paragraph with some content.

<!-- Created by AI Agent following AGENTS.md guidelines -->
```
