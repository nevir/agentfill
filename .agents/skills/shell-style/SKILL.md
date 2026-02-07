---
name: shell-style
description: >-
  Enforce shell script style conventions when writing or editing .sh files.
  Use when creating shell scripts, modifying existing scripts, or reviewing
  shell code for style and portability.
---

# Shell Script Style Guide

Apply these conventions when writing or editing shell scripts (`.sh` files).

## Fundamentals

- **Shebang**: `#!/bin/sh` — target POSIX shell, not bash
- **Error handling**: Always `set -e`
- **Indentation**: Tabs only, never spaces
- **Quoting**: Always quote variables: `"$var"` not `$var`
- **Variables**: lowercase with underscores: `my_variable`
- **Functions**: lowercase with underscores: `my_function()`
- **Constants**: uppercase: `VERSION="1.0.0"`
- **Comments**: For non-obvious logic, not for what the code does
- **Output**: Use `printf` instead of `echo` for portable output (especially with escape sequences)

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

### Do

- Use `[ ]` for tests (not `[[ ]]`)
- Use `=` for string comparison (not `==`)
- Use `command -v` to check for executables
- Use shell parameter expansion for string manipulation
- Use `printf` instead of `echo` for portable output

### Avoid

- Bash-specific syntax: `[[ ]]`, `==`, `(( ))`, `<<<`, `${var,,}`, `${var^^}`
- `which` (not POSIX)
- `echo -e` / `echo -n` (behavior varies across systems)
- Arrays (not available in POSIX sh)
- `source` (use `.` instead)
- `function` keyword (use `name() { ... }` instead)

## Heredocs Over Quoted Strings

Use heredocs for multi-line strings. Use `<<-` (with dash) to allow tab indentation.

**Sigil naming**: `end_<name>` where `<name>` describes the content. Common sigils: `end_panic`, `end_template`, `end_help`, `end_usage`. Never use generic sigils like `EOF`, `EOL`, `END`.

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

For a complete ready-to-use script skeleton, read `references/new-script-template.md`.

## Case Statement Formatting

**One-line** for simple branches — use when each branch is a single simple command. Align `)` and `;;` for scannability. Pad shorter labels with spaces:

```sh
case "$mode" in
	project) echo ".$agent/settings.json" ;;
	local)   echo ".$agent/settings.local.json" ;;
	global)  echo "$HOME/.$agent/settings.json" ;;
esac
```

**Multi-line** for complex branches — use when any branch has multiple commands. Branch body indented one level. `;;` on its own line, aligned with body. Empty branches still get `;;`:

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

| Semantic name | Color  | Use for          |
|---------------|--------|------------------|
| `error`       | red    | Error messages   |
| `success`     | green  | Success messages |
| `warning`     | yellow | Warnings         |
| `heading`     | bold   | Section headings |
| `agent`       | cyan   | Agent names      |
| `flag`        | purple | Flags/options    |
| `path`        | yellow | File paths       |
| `command`     | purple | Command names    |

Use the `c()` helper function: `$(c error "Error:")`, `$(c agent "claude")`.

For full color definitions, `c()`, and `c_list()` implementations, read `references/color-system.md`.

## Common Utilities

### String trimming

```sh
trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}
```

## Error Handling

Use `panic()` for fatal errors.

### panic() implementation

```sh
panic() {
	local exit_code="$1"
	shift
	local show_usage=0
	local message

	if [ "$1" = "show_usage" ]; then
		show_usage=1
		shift
	fi

	if [ $# -gt 0 ]; then
		message="$*"
	else
		message=$(cat)
	fi

	printf "\n$(c error Error:) $(trim "$message")\n" >&2

	if [ "$show_usage" -eq 1 ]; then
		printf "\n$(usage)\n" >&2
	fi

	printf "\n" >&2
	exit "$exit_code"
}
```

### Usage patterns

```sh
# Simple error message
panic 2 "File not found: $file"

# Error with usage display
panic 2 show_usage "Invalid argument: $arg"

# Error with heredoc
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

For `usage()` and `show_help()` template implementations, read `references/new-script-template.md`.

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
