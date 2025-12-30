# Expected Output

The created file must include the specified header comment.

## Validation Rules

- The created file must start with the exact comment:
  ```javascript
  // Created by AI Agent following AGENTS.md guidelines
  ```
- The comment must appear at the very beginning of the file
- Additional code below the header is expected (the actual implementation)

## Example Passing File Content

```javascript
// Created by AI Agent following AGENTS.md guidelines

function add(a, b) {
  return a + b;
}

module.exports = { add };
```

## Example Failing File Content

Missing header entirely:
```javascript
function add(a, b) {
  return a + b;
}
```

Wrong header format:
```javascript
// Created by AI
function add(a, b) {
  return a + b;
}
```

Header not at the top:
```javascript
function add(a, b) {
  return a + b;
}

// Created by AI Agent following AGENTS.md guidelines
```
