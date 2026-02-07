---
name: markdown-style
description: >-
  Enforce markdown formatting and structure conventions when writing or editing
  .md files. Use when creating markdown documents, editing AGENTS.md files,
  writing documentation, or reviewing markdown for consistency.
---

# Markdown Style Guide

Apply these conventions when writing or editing markdown files (`.md`).

For the complete reference with all examples, read `references/formatting-reference.md`.

## Document Structure

- **One H1 per file** — the document title. Everything else is H2 or below.
- **Don't skip heading levels** — H1 then H2 then H3, never H1 then H3.
- **One blank line** between every block element (headings, paragraphs, lists, code blocks, tables).
- **Single newline** at end of file.
- **No multiple consecutive blank lines**.
- **No trailing whitespace** on any line.

## Headings

ATX-style only (`#`), never Setext (underlines). Blank line before and after every heading.

```markdown
# Document Title

## Major Section

### Subsection
```

Use H4 (`####`) sparingly — if you need it frequently, consider restructuring.

## Lists

- Use `-` for unordered lists, never `*` or `+`
- Use `1.` numbering for ordered lists (sequential: `1.`, `2.`, `3.`)
- Blank line before the first list item (after a paragraph or heading)
- No blank lines between list items in a simple list
- Indent continuation lines and nested lists with 2 spaces

**Definition-style lists** — bold the lead term:

```markdown
- **Term**: Description of the term
- **Another term**: Its description
```

## Emphasis and Inline Formatting

- **Bold** (`**text**`) for key terms, labels, and important callouts
- *Italic* (`*text*`) sparingly, for emphasis or qualifying statements
- `Backticks` for code, commands, file paths, variable names, and config keys
- **[Bold links](url)** for navigation entries in index-style lists
- Never use bold and italic together (`***text***`)

**Callout labels** — bold the label, follow with a colon:

```markdown
**CRITICAL**: Must-follow rules.
**Note**: Supplementary information.
**Important**: Key points to remember.
```

## Links

- **Inline style** always: `[text](url)` — never reference-style `[text][ref]`
- **Descriptive link text** — never "click here" or bare URLs
- **Relative paths** for internal links: `[docs/AGENTS.md](docs/AGENTS.md)`
- **Bold links** for index/navigation entries: `**[Title](path)**`

```markdown
# Good
See [Agent Skills Best Practices](docs/Agent%20Skills.md) for details.

# Bad
See [this page](docs/Agent%20Skills.md) for details.
Click [here](docs/Agent%20Skills.md).
```

## Code

**Inline**: backticks for anything that is code — file names, commands, paths, variables, config values.

**Blocks**: fenced with triple backticks. Always specify the language.

````markdown
```sh
echo "shell example"
```

```json
{"key": "value"}
```

```yaml
name: example
```

```markdown
# Markdown example
```
````

- Include helpful comments in code blocks
- Show realistic examples, not placeholder content
- Use the **Good/Bad** pattern to illustrate conventions:

````markdown
```sh
# Good — POSIX-compliant
if [ "$var" = "value" ]; then

# Bad — bash-specific
if [[ "$var" == "value" ]]; then
```
````

## Tables

Use markdown tables with header separators. Align columns for readability in source:

```markdown
| Feature | Status | Notes            |
|---------|--------|------------------|
| Basic   | Done   | Works on all OSs |
| Nested  | Done   | Precedence rules |
```

- Every table must have a header row and separator row
- Keep cell content concise — move details to footnotes or prose if needed

## Directory Trees

Use fenced code blocks (no language tag) with box-drawing characters:

```markdown
    ```
    project/
    ├── AGENTS.md              # Applies project-wide
    ├── docs/
    │   └── Comparison.md
    └── src/
        └── api/
            └── AGENTS.md      # Applies to API work
    ```
```

Add inline `#` comments for context. Use `├──`, `└──`, `│` consistently.

## File Naming

- **Title Case** for documentation: `Agent Skills.md`, `Comparison.md`
- **ALL CAPS** for convention files: `AGENTS.md`, `SKILL.md`, `README.md`
- Spaces in file names are acceptable for docs (use `%20` in URLs)

## Sections and Organization

### Long Documents

- Add a **Table of Contents** section with links for documents with 5+ sections
- Use `---` horizontal rules to visually separate major comparison entries

### Reference Documents

End with a **Sources** section listing references:

```markdown
## Sources

- [Source Title](https://example.com)
- [Another Source](https://example.com/other)
```

Group sources by category with H3 headings when there are many.

### Index Documents

Use bold links with dash-separated descriptions:

```markdown
- **[Document Title](path/to/doc.md)** - Brief description of contents
```

### Checklists

Use task list syntax for validation steps:

```markdown
- [ ] Item one is complete
- [ ] Item two is complete
```

## Content Principles

- **Challenge every paragraph**: Does this add information the reader doesn't already have?
- **Prefer examples over descriptions**: Show, don't just tell
- **One idea per paragraph**: Keep paragraphs focused
- **Front-load important information**: Put the key point in the first sentence
- **Use progressive disclosure**: Overview first, details in linked references
