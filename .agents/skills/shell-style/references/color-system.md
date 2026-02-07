# Color System

Read this when writing scripts with colored output.

## Standard Color Definitions

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

## Semantic Color Mapping

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

## Color Helper Functions

### c() — colorize text

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

### c_list() — colorize a comma-separated list

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
```

Usage:

```sh
printf "Available agents: $(c_list agent claude gemini)\n"
```

## Indentation Helper

```sh
indent() {
	local spaces="$1"
	local text="$2"
	echo "$text" | while IFS= read -r line; do
		printf "%${spaces}s%s\n" "" "$line"
	done
}
```
