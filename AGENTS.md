# Universal Agents Project

This file provides context and instructions for AI coding agents working on this project. [Read the README](./README.md) to understand what this project is about.

## Documentation

This project maintains detailed documentation in the `docs/` directory:

- **[docs/AGENTS.md](docs/AGENTS.md)** - Documentation index and formatting guidelines
- **[docs/Comparison.md](docs/Comparison.md)** - Comprehensive comparison with similar projects (Ruler, OpenSkills, CCS, etc.)
- **[docs/agents/](docs/agents/)** - Per-agent configuration references

**For AI Agents**: When you need context about:
- Agent configuration formats and file locations
- How specific agents work
- Config file structures and hierarchies

Read the relevant documentation in `docs/agents/<Agent>.md` first.

**To understand the ecosystem**: Read [docs/Comparison.md](docs/Comparison.md) for analysis of similar projects, alternative approaches, and how this project compares to Ruler, OpenSkills, symlinks, and other solutions.

**When you learn new information** about agents or configuration:
- Update the relevant docs in `docs/agents/`
- Update [docs/Comparison.md](docs/Comparison.md) if you learn about competing/related projects
- Keep documentation accurate and up-to-date
- Add sources for new information

## Test Suite Context

When working on test files or testing-related code (anything in the `tests/` directory), you should read **[tests/AGENTS.md](tests/AGENTS.md)** to understand:

- Test suite organization and structure
- How to run different test categories (unit tests, agent integration tests)
- Shared test utilities in `tests/_common/`
- Test isolation principles and why they matter
- Guidelines for writing new tests

This applies when:
- Modifying existing test files
- Creating new tests
- Debugging test failures
- Working on test runner scripts
- Understanding test output or behavior

## Shell Script Style Guide

This project follows strict shell scripting conventions to ensure portability, readability, and maintainability.

### Indentation

- **Always use tabs for indentation**, never spaces
- This applies to all shell scripts (.sh files)

### Multi-line Strings

When passing multi-line strings to functions or commands, prefer heredocs over quoted strings.

**Heredoc naming convention:**

- Use the sigil pattern `end_<name>` where `<name>` clearly describes the content or context
- Common patterns: `end_panic` for panic messages, and `end_template` for templates
- The sigil should make it clear what kind of content is ending
- Use tab-aligned heredocs (`<<-`) to allow indentation in the source

**Examples:**

```sh
# Good - heredoc with matching sigil
panic 2 <<-end_panic
	Error message here
	with multiple lines
end_panic

# Good - heredoc for template functions
template_config() {
	cat <<-end_template
		config content here
		more content
	end_template
}

# Bad - multi-line quoted string
panic 2 "Error message here
with multiple lines"

# Bad - heredoc with non-matching sigil
panic 2 <<-EOF
	Error message here
	with multiple lines
EOF
```

### Portability

Scripts must be portable across all Unix-like systems:

- **Target shell**: `/bin/sh` (POSIX-compliant)
- **Supported systems**: Linux, macOS, BSD, Git Bash (Windows), WSL
- **Avoid bashisms**: Don't rely on bash-specific features
- **Minimize external dependencies**: Use shell built-ins when possible

**Examples:**

```sh
# Good - POSIX-compliant
if [ "$var" = "value" ]; then
	echo "match"
fi

# Bad - bash-specific
if [[ "$var" == "value" ]]; then
	echo "match"
fi

# Good - using shell parameter expansion
var="${var#prefix}"

# Bad - unnecessary external command
var=$(echo "$var" | sed 's/^prefix//')

# Good - command -v for checking executables
if command -v git >/dev/null 2>&1; then
	echo "git is available"
fi

# Bad - which is not POSIX
if which git >/dev/null 2>&1; then
	echo "git is available"
fi
```

### Ergonomic Output

All user-facing scripts should provide helpful, readable output:

#### Help and Usage

- **Always provide** `-h` / `--help` flag
- **Implement** `usage()` function for brief syntax summary
- **Implement** `show_help()` function for detailed help
- Display available options, arguments, and examples

#### Color Coding

Use ANSI color codes to improve scannability:

**Standard color definitions:**

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

**Semantic color mapping:**

Define semantic colors for consistency:

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

**Color helper function:**

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

# Usage
printf "$(c error "Error:") Something went wrong\n"
printf "Install with $(c command "install.sh") $(c agent "claude")\n"
```

**Consistency rules:**

- **Agents**: Always cyan (`color_agent`)
- **Flags/Options**: Always purple (`color_flag`)
- **Paths**: Always yellow (`color_path`)
- **Errors**: Always red (`color_error`)
- **Success**: Always green (`color_success`)
- **Headings**: Always bold (`color_heading`)

Apply these colors consistently across:

- Help text
- Usage examples
- Error messages
- Status output
- Argument descriptions

### Error Handling

Use the `panic()` function for fatal errors:

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

**Usage:**

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

### Common Utility Functions

Include these functions in a script when needed:

**String trimming:**

```sh
trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}
```

**Indentation:**

```sh
indent() {
	local spaces="$1"
	local text="$2"
	echo "$text" | while IFS= read -r line; do
		printf "%${spaces}s%s\n" "" "$line"
	done
}
```

**Colored lists:**

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

### Case Statements

**One-line format for simple cases:**

Use one-line format when each branch is a single simple command:

```sh
# Good - simple value lookups
get_color() {
	case "$1" in
		error)   echo "$color_red" ;;
		success) echo "$color_green" ;;
		warning) echo "$color_yellow" ;;
	esac
}

# Good - simple actions
handle_result() {
	case "$1" in
		pass) return 0 ;;
		fail) return 1 ;;
		skip) return 2 ;;
	esac
}
```

**Multi-line format for complex cases:**

Use multi-line format when branches have multiple commands or complex logic:

```sh
# Good - complex logic per branch
apply_change() {
	case "$type" in
		create)
			mkdir -p "$(dirname "$file")"
			cat "$content" > "$file"
			chmod +x "$file"
			;;
		modify)
			cp "$file" "$file.backup"
			cat "$content" > "$file"
			;;
		skip)
			;;
	esac
}

# Good - long commands or heredocs
show_error() {
	case "$error_type" in
		missing_file)
			panic 2 <<-end_panic
				File not found: $file
				Please check the path and try again.
			end_panic
			;;
		invalid_arg)
			panic 2 show_usage "Invalid argument: $arg"
			;;
	esac
}
```

**Alignment:**

For one-line format, align the `)` and `;;` for readability:

```sh
# Good - aligned for easy scanning
case "$mode" in
	project) echo ".$agent/settings.json" ;;
	local)   echo ".$agent/settings.local.json" ;;
	global)  echo "$HOME/.$agent/settings.json" ;;
esac

# Bad - no alignment
case "$mode" in
	project) echo ".$agent/settings.json" ;;
	local) echo ".$agent/settings.local.json" ;;
	global) echo "$HOME/.$agent/settings.json" ;;
esac
```

### Script Structure

Organize scripts with clear sections using comment headers:

```sh
#!/bin/sh
set -e

VERSION="1.0.0"

# ============================================
# Colors
# ============================================

# ... color definitions ...

# ... color utility functions ...

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

usage() {
	# ...
}

show_help() {
	# ...
}

# ============================================
# Main
# ============================================

main() {
	# ... argument parsing and execution ...
}

main "$@"
```

### Argument Parsing

**Flags and options:**

```sh
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			show_help
			exit 0
			;;
		-v|--verbose)
			verbose=true
			shift
			;;
		--option)
			option_value="$2"
			shift 2
			;;
		-*)
			panic 2 show_usage "Unknown option: $1"
			;;
		*)
			# Positional arguments
			positional_args="$positional_args $1"
			shift
			;;
	esac
done
```

**Exit codes:**

- `0` - Success
- `1` - General failure (tests failed, operation incomplete)
- `2` - Invalid arguments or configuration error

### General Guidelines

- **Comments**: Add comments for non-obvious logic, not for what the code does
- **Variables**: Use lowercase with underscores: `my_variable`
- **Functions**: Use lowercase with underscores: `my_function()`
- **Constants**: Use uppercase: `VERSION="1.0.0"`
- **Quoting**: Always quote variables: `"$var"` not `$var`
- **Debugging**: Use `set -e` to exit on errors
- **Portability**: Test on multiple platforms when possible
