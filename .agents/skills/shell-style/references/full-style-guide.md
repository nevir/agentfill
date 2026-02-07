# Shell Script Style Guide — Full Reference

Complete style conventions for writing portable, readable shell scripts.

## Color Definitions

### Standard colors

```sh
color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_blue='\033[0;34m'
color_purple='\033[0;35m'
color_cyan='\033[0;36m'
color_bold='\033[1m'
color_reset='\033[0m'
```

### Semantic color mapping

```sh
# Status colors
color_error="$color_red"
color_success="$color_green"
color_warning="$color_yellow"
color_heading="$color_bold"

# Argument type colors
color_agent="$color_cyan"      # Agent names
color_flag="$color_purple"     # Flags/options
color_path="$color_yellow"     # File paths
color_test="$color_yellow"     # Test names
color_command="$color_purple"  # Command names
```

### Color helper functions

```sh
c() {
	local color_name="$1"; shift
	local text="$*"
	local var_name
	local color_code

	var_name="color_$color_name"
	eval "color_code=\$$var_name"

	printf "%s%s%s" "$color_code" "$text" "$color_reset"
}
```

Usage:

```sh
printf "$(c error "Error:") Something went wrong\n"
printf "Install with $(c command "install.sh") $(c agent "claude")\n"
```

### Colored lists

```sh
c_list() {
	local color_type="$1"
	shift
	local result=""
	local first=1

	for item in "$@"; do
		[ $first -eq 0 ] && result="$result, "
		result="$result$(c "$color_type" "$item")"
		first=0
	done

	echo "$result"
}

# Usage
printf "Available agents: $(c_list agent claude gemini)\n"
```

## Common Utility Functions

### String trimming

```sh
trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}
```

### Indentation

```sh
indent() {
	local spaces="$1"
	local text="$2"
	echo "$text" | while IFS= read -r line; do
		printf "%${spaces}s%s\n" "" "$line"
	done
}
```

## Error Handling

### panic() function

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

Usage patterns:

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

## Help and Usage

```sh
usage() {
	printf "Usage: $(c command "script.sh") [$(c flag "options")] [$(c path "args...")]\n"
}

show_help() {
	printf "\n$(c heading "Script Name") v$VERSION\n\n"
	usage
	printf "\n$(c heading "Options:")\n"
	printf "  $(c flag "-h, --help")      Show this help message\n"
	printf "  $(c flag "-v, --verbose")   Enable verbose output\n"
	printf "\n$(c heading "Examples:")\n"
	printf "  $(c command "script.sh") $(c path "file.txt")\n"
	printf "\n"
}
```

## Complete Script Template

```sh
#!/bin/sh
set -e

VERSION="1.0.0"

# ============================================
# Colors
# ============================================

color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_blue='\033[0;34m'
color_purple='\033[0;35m'
color_cyan='\033[0;36m'
color_bold='\033[1m'
color_reset='\033[0m'

color_error="$color_red"
color_success="$color_green"
color_warning="$color_yellow"
color_heading="$color_bold"
color_flag="$color_purple"
color_path="$color_yellow"
color_command="$color_purple"

c() {
	local color_name="$1"; shift
	local text="$*"
	local var_name
	local color_code

	var_name="color_$color_name"
	eval "color_code=\$$var_name"

	printf "%s%s%s" "$color_code" "$text" "$color_reset"
}

# ============================================
# Utilities
# ============================================

trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}

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

# ============================================
# Core logic
# ============================================

# ... main functionality ...

# ============================================
# Usage and help
# ============================================

usage() {
	printf "Usage: $(c command "script.sh") [$(c flag "options")] [$(c path "args...")]\n"
}

show_help() {
	printf "\n$(c heading "Script Name") v$VERSION\n\n"
	usage
	printf "\n$(c heading "Options:")\n"
	printf "  $(c flag "-h, --help")      Show this help message\n"
	printf "\n"
}

# ============================================
# Main
# ============================================

main() {
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help) show_help; exit 0 ;;
			-*)        panic 2 show_usage "Unknown option: $1" ;;
			*)         break ;;
		esac
	done

	# ... main logic ...
}

main "$@"
```

## POSIX Portability Rules

### Do

- Use `[ ]` for tests (not `[[ ]]`)
- Use `=` for string comparison (not `==`)
- Use `command -v` to check for executables
- Use shell parameter expansion for string manipulation
- Use `printf` instead of `echo` for portable output (especially with escape sequences)

### Avoid

- Bash-specific syntax: `[[ ]]`, `==`, `(( ))`, `<<<`, `${var,,}`, `${var^^}`
- `which` (not POSIX)
- `echo -e` / `echo -n` (behavior varies across systems)
- Arrays (not available in POSIX sh)
- `source` (use `.` instead)
- `function` keyword (use `name() { ... }` instead)

## Heredoc Conventions

- Use `<<-` (with dash) to allow tab indentation in the source
- Sigil pattern: `end_<name>` where `<name>` describes the content
- Common sigils: `end_panic`, `end_template`, `end_help`, `end_usage`
- Never use generic sigils like `EOF`, `EOL`, `END`

## Case Statement Details

### One-line format rules

- Use when each branch is a single simple command
- Align the `)` delimiters and `;;` terminators for scannability
- Use spaces to pad shorter labels

```sh
case "$severity" in
	error)   echo "$color_red" ;;
	warning) echo "$color_yellow" ;;
	info)    echo "$color_blue" ;;
	*)       echo "$color_reset" ;;
esac
```

### Multi-line format rules

- Use when any branch has multiple commands or complex logic
- Each branch body is indented one level from the case label
- `;;` goes on its own line, aligned with the branch body
- Empty branches still get `;;`

```sh
case "$action" in
	install)
		check_prerequisites
		download_files
		run_install
		;;
	uninstall)
		confirm_uninstall
		remove_files
		;;
	*)
		panic 2 show_usage "Unknown action: $action"
		;;
esac
```
