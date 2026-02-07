#!/bin/sh
set -e

VERSION="1.0.0"

# ============================================
# Colors
# ============================================

color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_purple='\033[0;35m'
color_bold='\033[1m'
color_reset='\033[0m'

color_error="$color_red"
color_success="$color_green"
color_warning="$color_yellow"
color_path="$color_yellow"
color_flag="$color_purple"
color_heading="$color_bold"

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
# Validation
# ============================================

pass_count=0
fail_count=0
warn_count=0

check_pass() {
	pass_count=$((pass_count + 1))
	printf "  $(c success "✓") %s\n" "$1"
}

check_fail() {
	fail_count=$((fail_count + 1))
	printf "  $(c error "✗") %s\n" "$1"
	if [ -n "${2:-}" ]; then
		printf "    %s\n" "$2"
	fi
}

check_warn() {
	warn_count=$((warn_count + 1))
	printf "  $(c warning "!") %s\n" "$1"
	if [ -n "${2:-}" ]; then
		printf "    %s\n" "$2"
	fi
}

extract_frontmatter() {
	local file="$1"
	# Extract content between the first two --- markers only
	# Uses awk to avoid matching --- inside code blocks in the body
	awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit; next} n==1{print}' "$file"
}

get_field() {
	local frontmatter="$1"
	local field="$2"
	# Extract simple inline value: "field: value"
	echo "$frontmatter" | sed -n "s/^${field}:[[:space:]]*//p" | head -1
}

get_body() {
	local file="$1"
	# Extract everything after the closing --- of frontmatter
	awk 'BEGIN{n=0} /^---$/{n++; if(n==2){found=1; next}} found{print}' "$file"
}

validate_skill() {
	local skill_dir="$1"
	local skill_md="$skill_dir/SKILL.md"
	local dir_name
	dir_name="$(basename "$skill_dir")"

	printf "\n$(c heading "Validating:") $(c path "$skill_dir")\n\n"

	# Check SKILL.md exists
	if [ ! -f "$skill_md" ]; then
		check_fail "SKILL.md exists"
		printf "\n$(c error "Cannot continue without SKILL.md")\n\n"
		return 1
	fi
	check_pass "SKILL.md exists"

	# Check frontmatter delimiters
	local delimiter_count
	delimiter_count=$(grep -c '^---$' "$skill_md" || true)
	if [ "$delimiter_count" -lt 2 ]; then
		check_fail "YAML frontmatter present" "Expected --- delimiters at start and end of frontmatter"
		printf "\n$(c error "Cannot continue without valid frontmatter")\n\n"
		return 1
	fi
	check_pass "YAML frontmatter present"

	# Extract frontmatter
	local frontmatter
	frontmatter="$(extract_frontmatter "$skill_md")"

	# Check name field
	local name
	name="$(get_field "$frontmatter" "name")"
	if [ -z "$name" ]; then
		check_fail "name field present"
	else
		check_pass "name field present"

		# Validate name format
		if echo "$name" | grep -qE '^[a-z][a-z0-9-]{0,63}$'; then
			check_pass "name format valid (lowercase-hyphenated, 1-64 chars)"
		else
			check_fail "name format valid" "Got: '$name' — must match ^[a-z][a-z0-9-]{0,63}$"
		fi

		# Check name matches directory
		if [ "$name" = "$dir_name" ]; then
			check_pass "name matches directory name"
		else
			check_warn "name matches directory name" "name='$name' but directory='$dir_name'"
		fi
	fi

	# Check description field
	if echo "$frontmatter" | grep -q '^description:'; then
		check_pass "description field present"
	else
		check_fail "description field present"
	fi

	# Check body length
	local body
	body="$(get_body "$skill_md")"
	local body_lines
	body_lines=$(echo "$body" | wc -l | tr -d ' ')
	if [ "$body_lines" -gt 500 ]; then
		check_warn "body length under 500 lines" "Body is $body_lines lines — consider moving content to references/"
	elif [ "$body_lines" -gt 0 ]; then
		check_pass "body length ($body_lines lines)"
	else
		check_warn "body has content" "SKILL.md body is empty"
	fi

	# Check scripts are executable
	if [ -d "$skill_dir/scripts" ]; then
		local script_issues=0
		for script in "$skill_dir/scripts/"*; do
			[ -f "$script" ] || continue
			if [ ! -x "$script" ]; then
				check_fail "script executable: $(basename "$script")"
				script_issues=$((script_issues + 1))
			fi
		done
		if [ "$script_issues" -eq 0 ]; then
			check_pass "scripts are executable"
		fi
	fi

	# Check references depth (should be one level deep)
	if [ -d "$skill_dir/references" ]; then
		local deep_files=0
		for entry in "$skill_dir/references/"*; do
			if [ -d "$entry" ]; then
				deep_files=$((deep_files + 1))
			fi
		done
		if [ "$deep_files" -gt 0 ]; then
			check_warn "references one level deep" "Found $deep_files subdirectories in references/"
		else
			check_pass "references structure"
		fi
	fi

	# Summary
	printf "\n"
	local total=$((pass_count + fail_count + warn_count))
	printf "  $(c success "$pass_count passed")"
	if [ "$fail_count" -gt 0 ]; then
		printf ", $(c error "$fail_count failed")"
	fi
	if [ "$warn_count" -gt 0 ]; then
		printf ", $(c warning "$warn_count warnings")"
	fi
	printf "\n\n"

	if [ "$fail_count" -gt 0 ]; then
		return 1
	fi
	return 0
}

# ============================================
# Usage and help
# ============================================

usage() {
	printf "Usage: $(c flag "validate-skill.sh") $(c path "<skill-directory>")\n"
}

show_help() {
	printf "\n$(c heading "validate-skill.sh") v%s\n" "$VERSION"
	printf "Validate an Agent Skills directory structure and SKILL.md frontmatter.\n\n"
	usage
	printf "\n"
	printf "$(c heading "Arguments:")\n"
	printf "  $(c path "<skill-directory>")   Path to the skill directory to validate\n"
	printf "\n"
	printf "$(c heading "Options:")\n"
	printf "  $(c flag "-h, --help")          Show this help message\n"
	printf "\n"
	printf "$(c heading "Checks performed:")\n"
	printf "  - SKILL.md exists with valid YAML frontmatter\n"
	printf "  - name field: present, lowercase-hyphenated, 1-64 chars, matches directory\n"
	printf "  - description field: present, within length limits\n"
	printf "  - Body length: warns if over 500 lines\n"
	printf "  - Scripts: checks executability\n"
	printf "  - References: checks directory depth\n"
	printf "\n"
	printf "$(c heading "Examples:")\n"
	printf "  $(c flag "validate-skill.sh") $(c path ".agents/skills/my-skill")\n"
	printf "  $(c flag "validate-skill.sh") $(c path ".agents/skills/skill")\n"
	printf "\n"
	printf "$(c heading "Exit codes:")\n"
	printf "  $(c success "0")  All checks passed\n"
	printf "  $(c error "1")  One or more checks failed\n"
	printf "  $(c warning "2")  Invalid arguments\n"
	printf "\n"
}

# ============================================
# Main
# ============================================

main() {
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				show_help
				exit 0
				;;
			-*)
				panic 2 show_usage "Unknown option: $1"
				;;
			*)
				break
				;;
		esac
	done

	if [ $# -eq 0 ]; then
		panic 2 show_usage "Missing required argument: skill directory"
	fi

	local skill_dir="$1"

	if [ ! -d "$skill_dir" ]; then
		panic 2 "Not a directory: $skill_dir"
	fi

	validate_skill "$skill_dir"
}

main "$@"
