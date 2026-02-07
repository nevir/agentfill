# New Script Template

Read this when creating a new shell script from scratch.

## Help and Usage Functions

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

## Complete Script Skeleton

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
