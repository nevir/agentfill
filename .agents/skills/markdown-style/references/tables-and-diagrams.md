# Tables and Diagrams

Read this when formatting tables or directory tree diagrams.

## Table Formatting

### Basic Tables

```markdown
| Column A | Column B | Column C |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
| Value 4  | Value 5  | Value 6  |
```

Every table must have a header row and separator row.

### Aligned Columns

Align source columns for readability. This doesn't affect rendering but improves the markdown source:

```markdown
| Feature            | Status | Notes                        |
|--------------------|--------|------------------------------|
| Basic support      | Done   | Works on all platforms       |
| Nested hierarchy   | Done   | Proper precedence rules      |
| Selective loading  | Done   | Essential for monorepos      |
```

### Tables with Emoji or Icons

```markdown
| Feature | Claude Code | Gemini CLI |
|---------|-------------|------------|
| Basic   | ❌          | ⚠️         |
| Nested  | ❌          | ✅         |
```

### When Not to Use Tables

Avoid tables when:

- You have more than 5-6 columns (hard to read)
- Cells contain long text (use a list or sections instead)
- The data is a simple key-value pair (use a definition-style list)

Keep cell content concise — move details to footnotes or prose if needed.

## Directory Tree Diagrams

Use fenced code blocks with no language identifier and box-drawing characters:

```
project/
├── AGENTS.md              # Applies project-wide
├── .agents/
│   ├── polyfills/
│   │   └── claude/
│   │       └── agentsmd.sh
│   └── skills/
│       └── my-skill/
│           └── SKILL.md
├── docs/
│   ├── AGENTS.md
│   └── agents/
│       └── Claude.md
└── src/
    └── api/
        └── AGENTS.md      # Scoped to API work
```

### Tree Drawing Rules

- `├──` for items with siblings below
- `└──` for last item in a group
- `│` for continued depth lines
- Add inline `#` comments to explain purpose
- Keep trees focused — show relevant structure, not every file
