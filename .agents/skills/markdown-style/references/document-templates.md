# Document Templates

Read this when creating a new document from a standard template.

## Standard Document Structure

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

## Index / Overview Documents

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

## Comparison Documents

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

## Checklist Documents

```markdown
## Validation Checklist

- [ ] `name` is lowercase-hyphenated, 1-64 characters
- [ ] `description` explains WHAT and WHEN
- [ ] Body is focused
- [ ] Supporting files are referenced
```
