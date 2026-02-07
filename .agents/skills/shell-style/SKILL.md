---
name: shell-style
description: >-
  Enforce shell script style conventions when writing or editing .sh files.
  Use when creating shell scripts, modifying existing scripts, or reviewing
  shell code for style and portability.
---

# Shell Script Style Guide

Apply these conventions when writing or editing shell scripts (`.sh` files).

For the complete guide with all examples, read `references/full-style-guide.md`.

## Fundamentals

- **Shebang**: `#!/bin/sh` — target POSIX shell, not bash
- **Error handling**: Always `set -e`
- **Indentation**: Tabs only, never spaces
- **Quoting**: Always quote variables: `"$var"` not `$var`
- **Variables**: lowercase with underscores: `my_variable`
- **Functions**: lowercase with underscores: `my_function()`
- **Constants**: uppercase: `VERSION="1.0.0"`

## POSIX Portability

No bashisms. Scripts must work on Linux, macOS, BSD, Git Bash, and WSL.

```sh
# Good
if [ "$var" = "value" ]; then
# Bad
if [[ "$var" == "value" ]]; then

# Good
command -v git >/dev/null 2>&1
# Bad
which git >/dev/null 2>&1

# Good — shell parameter expansion
var="${var#prefix}"
# Bad — unnecessary external command
var=$(echo "$var" | sed 's/^prefix//')
```

## Heredocs Over Quoted Strings

Use heredocs for multi-line strings. Sigil pattern: `end_<name>` describing the content.

```sh
# Good
panic 2 <<-end_panic
	Error message here
	with multiple lines
end_panic

# Good
template_config() {
	cat <<-end_template
		config content here
	end_template
}

# Bad — quoted multi-line string
panic 2 "Error message here
with multiple lines"
```

## Script Structure

Organize with clear section headers:

```sh
#!/bin/sh
set -e

VERSION="1.0.0"

# ============================================
# Colors
# ============================================

# ... color definitions, c(), c_list() ...

# ============================================
# Utilities
# ============================================

# ... utility functions ...

# ============================================
# Core logic
# ============================================

# ... main functionality ...

# ============================================
# Usage and help
# ============================================

usage() { ... }
show_help() { ... }

# ============================================
# Main
# ============================================

main() { ... }
main "$@"
```

## Case Statement Formatting

**One-line** for simple branches — align `)` and `;;`:

```sh
case "$mode" in
	project) echo ".$agent/settings.json" ;;
	local)   echo ".$agent/settings.local.json" ;;
	global)  echo "$HOME/.$agent/settings.json" ;;
esac
```

**Multi-line** for complex branches:

```sh
case "$type" in
	create)
		mkdir -p "$(dirname "$file")"
		cat "$content" > "$file"
		;;
	skip)
		;;
esac
```

## Color Conventions

Standard semantic color mapping — apply consistently across help text, errors, and status output:

| Semantic name | Color | Use for |
|--------------|-------|---------|
| `error` | red | Error messages |
| `success` | green | Success messages |
| `warning` | yellow | Warnings |
| `heading` | bold | Section headings |
| `agent` | cyan | Agent names |
| `flag` | purple | Flags/options |
| `path` | yellow | File paths |
| `command` | purple | Command names |

Use the `c()` helper function: `$(c error "Error:")`, `$(c agent "claude")`.

For full color definitions and helper functions, see `references/full-style-guide.md`.

## Error Handling

Use `panic()` for fatal errors:

```sh
# Simple
panic 2 "File not found: $file"

# With usage display
panic 2 show_usage "Invalid argument: $arg"

# With heredoc
panic 2 <<-end_panic
	Cannot proceed because:
	- Reason 1
	- Reason 2
end_panic
```

## User-Facing Scripts

All user-facing scripts must provide:

- `-h` / `--help` flags
- `usage()` — brief syntax summary
- `show_help()` — detailed help with examples
- Color-coded output using the semantic colors above

## Argument Parsing Pattern

```sh
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) show_help; exit 0 ;;
		-v|--verbose) verbose=true; shift ;;
		--option)     option_value="$2"; shift 2 ;;
		-*)           panic 2 show_usage "Unknown option: $1" ;;
		*)            positional_args="$positional_args $1"; shift ;;
	esac
done
```

## Exit Codes

- `0` — Success
- `1` — General failure (tests failed, operation incomplete)
- `2` — Invalid arguments or configuration error
