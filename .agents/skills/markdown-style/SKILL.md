---
name: markdown-style
description: >-
  Enforce markdown formatting and structure conventions when writing or editing
  .md files. Use when creating markdown documents, editing AGENTS.md files,
  writing documentation, or reviewing markdown for consistency.
---

# Markdown Style Guide

Apply these conventions when writing or editing markdown files (`.md`).

When formatting tables or directory tree diagrams, read `references/tables-and-diagrams.md`.
When creating a new document from a standard template, read `references/document-templates.md`.

## Document Structure

- **One H1 per file** — the document title. Everything else is H2 or below.
- **Don't skip heading levels** — H1 then H2 then H3, never H1 then H3.
- **One blank line** between every block element (headings, paragraphs, lists, code blocks, tables).
- **Single newline** at end of file.
- **No multiple consecutive blank lines**.
- **No trailing whitespace** on any line — including blank lines, which must be truly empty.

## Headings

ATX-style only (`#`), never Setext (underlines). Blank line before and after every heading.

```markdown
# Document Title

## Major Section

### Subsection
```

Use H4 (`####`) sparingly — if you need it frequently, consider restructuring.

**Common mistakes:**

```markdown
# Bad — skipped heading level

### This subsection has no parent H2

# Bad — multiple H1s

# First Title

# Second Title
```

## Lists

- Use `-` for unordered lists, never `*` or `+`
- Use `1.` numbering for ordered lists (sequential: `1.`, `2.`, `3.`)
- Blank line before the first list item (after a paragraph or heading)
- No blank lines between list items in a simple list
- Indent nested lists with 2 spaces

```markdown
- Parent item
  - Child item
  - Another child
    - Grandchild
- Next parent
```

**Mixed content in list items** — indent continuations with spaces to align:

```markdown
1. **First step**: Do the initial setup.

   Additional details about this step that require a second paragraph.

2. **Second step**: Run the following command:

   ```sh
   ./install.sh
   ```

3. **Third step**: Verify the results.
```

**Lists after paragraphs** — always a blank line between a paragraph and a list:

```markdown
This project supports multiple agents:

- Claude Code
- Gemini CLI

Each agent has its own configuration format.
```

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

**Scoped callout labels** — bold the audience or context:

```markdown
**For AI Agents**: When you need context about agent configuration, read the docs first.
**Example workflow**:
```

**Emphasis in lists** — bold the key term at the start of each item:

```markdown
- **No file duplication**: No need for CLAUDE.md symlinks
- **Project and global modes**: Install per-project or user-wide
- **Portable shell scripts**: POSIX sh, works everywhere
```

## Links

- **Inline style** always: `[text](url)` — never reference-style `[text][ref]`
- **Descriptive link text** — never "click here" or bare URLs
- **Relative paths** for internal links: `[docs/AGENTS.md](docs/AGENTS.md)`
- **Bold links** for index/navigation entries: `**[Title](path)**`

**Internal documentation links:**

```markdown
See [docs/AGENTS.md](docs/AGENTS.md) for documentation guidelines.
Read [Agent Skills Best Practices](docs/Agent%20Skills.md) for skill writing guidance.
```

**External links:**

```markdown
See the [Agent Skills Specification](https://agentskills.io/specification) for the formal spec.
```

**Links in prose** — embed naturally in sentences:

```markdown
# Good
The [AGENTS.md standard](https://agents.md) provides a vendor-neutral format.

# Bad
For the AGENTS.md standard, see: https://agents.md
```

## Code

**Inline**: backticks for anything that is code — file names, commands, paths, variables, config values.

**Blocks**: fenced with triple backticks. Always specify the language:

| Language   | Identifier |
|------------|-----------|
| Shell      | `sh`      |
| JSON       | `json`    |
| YAML       | `yaml`    |
| Markdown   | `markdown` |
| TOML       | `toml`    |
| Python     | `python`  |
| JavaScript | `js`      |
| TypeScript | `ts`      |
| HTML       | `html`    |
| CSS        | `css`     |
| Plain text | (none — omit language) |

````markdown
```sh
echo "shell example"
```

```json
{"key": "value"}
```
````

**Nested code fences** — use four backticks for the outer fence when showing markdown that contains code blocks:

`````markdown
````markdown
```sh
echo "nested example"
```
````
`````

- Use `sh`, never `bash`, for shell code blocks
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

## Edge Cases

- **Escaping**: backticks inside inline code use double backticks; literal asterisks use `\*`; pipe in tables use `\|`
- **Long lines**: No hard wrapping — let lines be as long as needed. Break at sentence boundaries for very long prose.
- **HTML in markdown**: Avoid HTML tags. Use native markdown syntax (`**bold**` not `<b>bold</b>`).
- **Images**: `![Alt text](path/to/image.png)` — always include meaningful alt text.

## Content Principles

- **Challenge every paragraph**: Does this add information the reader doesn't already have?
- **Prefer examples over descriptions**: Show, don't just tell
- **One idea per paragraph**: Keep paragraphs focused
- **Front-load important information**: Put the key point in the first sentence
- **Use progressive disclosure**: Overview first, details in linked references
