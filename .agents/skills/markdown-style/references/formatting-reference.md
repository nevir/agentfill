# Markdown Formatting Reference

Complete reference for markdown conventions used in this project. This supplements the main SKILL.md with detailed examples and edge cases.

## Whitespace Rules

### Between Block Elements

One blank line between every block element. No exceptions.

```markdown
# Heading

Paragraph text.

- List item one
- List item two

Another paragraph.

```sh
code block
```

More text.
```

### Trailing Whitespace

Never leave trailing spaces or tabs on any line. This includes blank lines — they must be truly empty.

### End of File

Every file ends with exactly one newline character (single blank line at end of file). No trailing blank lines.

### Consecutive Blank Lines

Never use two or more consecutive blank lines. One blank line is always sufficient.

## Heading Patterns

### Correct Hierarchy

```markdown
# Document Title

## First Section

### Subsection

#### Deep Subsection (use sparingly)

## Second Section
```

### Common Mistakes

```markdown
# Bad — skipped heading level

### This subsection has no parent H2

# Bad — multiple H1s

# First Title

# Second Title
```

### Headings in Context

Headings always have a blank line before and after:

```markdown
Some text in the previous section.

## New Section

First paragraph of the new section.
```

## List Formatting

### Unordered Lists

```markdown
- First item
- Second item
- Third item
```

Not:

```markdown
* First item (wrong — use dash)
+ First item (wrong — use dash)
```

### Ordered Lists

Use sequential numbers:

```markdown
1. First step
2. Second step
3. Third step
```

### Nested Lists

Indent with 2 spaces:

```markdown
- Parent item
  - Child item
  - Another child
    - Grandchild
- Next parent
```

### Definition-Style Lists

Bold the term, follow with colon and description:

```markdown
- **Configuration files**: JSON files in `.claude/` and `.gemini/`
- **Polyfill scripts**: Shell scripts that add missing features
- **AGENTS.md**: Markdown files with instructions for AI agents
```

### Mixed Content in List Items

When a list item has multiple paragraphs or blocks, indent continuations:

```markdown
1. **First step**: Do the initial setup.

   Additional details about this step that require a second paragraph.

2. **Second step**: Run the following command:

   ```sh
   ./install.sh
   ```

3. **Third step**: Verify the results.
```

### Lists After Paragraphs

Always a blank line between a paragraph and the start of a list:

```markdown
This project supports multiple agents:

- Claude Code
- Gemini CLI

Each agent has its own configuration format.
```

## Link Patterns

### Internal Documentation Links

```markdown
See [docs/AGENTS.md](docs/AGENTS.md) for documentation guidelines.
Read [Agent Skills Best Practices](docs/Agent%20Skills.md) for skill writing guidance.
```

### Index-Style Navigation

Bold the link, add a dash and description:

```markdown
- **[docs/AGENTS.md](docs/AGENTS.md)** - Documentation index and formatting guidelines
- **[docs/Comparison.md](docs/Comparison.md)** - Comprehensive comparison with similar projects
- **[docs/agents/](docs/agents/)** - Per-agent configuration references
```

### External Links

```markdown
See the [Agent Skills Specification](https://agentskills.io/specification) for the formal spec.
```

### Links in Prose

Embed naturally in sentences:

```markdown
# Good
The [AGENTS.md standard](https://agents.md) provides a vendor-neutral format.

# Bad
For the AGENTS.md standard, see: https://agents.md
```

## Code Formatting

### Inline Code

Use backticks for:

- File names: `AGENTS.md`, `settings.json`
- File paths: `.claude/settings.json`, `docs/agents/`
- Commands: `./install.sh`, `git commit`
- Variable names: `project_dir`, `$HOME`
- Config keys: `hooks.SessionStart`, `context.fileName`
- Values: `true`, `"string value"`
- Tool names when referenced as code: `grep`, `jq`

### Fenced Code Blocks

Always specify the language identifier:

| Language | Identifier |
|----------|-----------|
| Shell    | `sh`      |
| JSON     | `json`    |
| YAML     | `yaml`    |
| Markdown | `markdown` |
| TOML     | `toml`    |
| Python   | `python`  |
| JavaScript | `js`    |
| TypeScript | `ts`    |
| HTML     | `html`    |
| CSS      | `css`     |
| Plain text | (none — omit language) |

### Good/Bad Examples Pattern

A recurring pattern in this project for showing conventions:

````markdown
```sh
# Good — descriptive comment
if [ "$var" = "value" ]; then

# Bad — explains what's wrong
if [[ "$var" == "value" ]]; then
```
````

Or as separate labeled blocks:

````markdown
**Good:**

```sh
command -v git >/dev/null 2>&1
```

**Bad:**

```sh
which git >/dev/null 2>&1
```
````

### Nested Code Fences

When showing markdown examples that contain code blocks, use four backticks for the outer fence:

`````markdown
````markdown
```sh
echo "This is a shell example inside a markdown example"
```
````
`````

## Table Formatting

### Basic Tables

```markdown
| Column A | Column B | Column C |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
| Value 4  | Value 5  | Value 6  |
```

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

## Callout and Emphasis Patterns

### Callout Labels

Bold the label word, follow with colon. The label goes at the start of the paragraph:

```markdown
**CRITICAL**: This rule must always be followed. Breaking it will cause failures.

**Note**: This is supplementary information that provides additional context.

**Important**: This point deserves special attention but isn't critical.
```

### Scoped Callout Labels

Bold the audience or context:

```markdown
**For AI Agents**: When you need context about agent configuration, read the docs first.

**Example workflow**:
```

### Emphasis in Lists

Bold the key term at the start of each item:

```markdown
- **No file duplication**: No need for CLAUDE.md symlinks
- **Project and global modes**: Install per-project or user-wide
- **Portable shell scripts**: POSIX sh, works everywhere
```

## Directory Tree Diagrams

Use no language identifier and box-drawing characters:

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

Rules:

- `├──` for items with siblings below
- `└──` for last item in a group
- `│` for continued depth lines
- Add inline `#` comments to explain purpose
- Keep trees focused — don't show every file, show the relevant structure

## Document Patterns

### Standard Document Structure

```markdown
# Document Title

Brief overview — 1-2 sentences describing the document.

## Table of Contents

(For long documents with 5+ sections)

- [Section One](#section-one)
- [Section Two](#section-two)

## Section One

Content...

## Section Two

Content...

## Sources

- [Source Title](url)
```

### Index/Overview Documents

Pattern used in `docs/AGENTS.md` and similar:

```markdown
# Index Title

Brief description of what this directory contains.

## Directory Structure

    ```
    docs/
    ├── AGENTS.md
    ├── Comparison.md
    └── agents/
        └── Claude.md
    ```

## Documentation

- **[Document Title](path)** - Brief description
- **[Another Document](path)** - Brief description

## Guidelines

Instructions for maintaining the documentation...
```

### Comparison Documents

Pattern used in `docs/Comparison.md`:

```markdown
## Project Name

**Repository**: [github.com/org/repo](url)

**Approach**: Brief description of the approach.

**Key Features**:
- Feature one
- Feature two

**Strengths**:
- Strength one

**Limitations**:
- Limitation one

---
```

Use `---` horizontal rules between comparison entries.

### Checklist Documents

```markdown
## Validation Checklist

- [ ] `name` is lowercase-hyphenated, 1-64 characters
- [ ] `description` explains WHAT and WHEN
- [ ] Body is focused
- [ ] Supporting files are referenced
```

## Edge Cases

### Escaping Special Characters

- Backticks inside inline code: use double backticks ``` `` `code` `` ```
- Literal asterisks: `\*not bold\*`
- Pipe characters in tables: `\|`

### Long Lines

- No hard wrapping at a specific column width
- Let lines be as long as needed for readability
- Break naturally at sentence boundaries when prose is very long

### HTML in Markdown

Avoid HTML tags in markdown. Use native markdown syntax instead:

```markdown
# Good
**bold text**

# Bad
<b>bold text</b>

# Good
> Blockquote text

# Bad
<blockquote>Blockquote text</blockquote>
```

### Images

If images are needed (rare in this project):

```markdown
![Alt text describing the image](path/to/image.png)
```

Always include meaningful alt text.
