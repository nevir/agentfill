
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

# Semantic colors
color_error="$color_red"
color_success="$color_green"
color_warning="$color_yellow"
color_agent="$color_cyan"
color_test="$color_yellow"
color_command="$color_purple"
color_heading="$color_bold"
color_suite="$color_blue"

c() {
	local color_name="$1"; shift
	local text="$*"
	local var_name
	local color_code

	var_name="color_$color_name"
	eval "color_code=\$$var_name"

	printf "%s%s%s" "$color_code" "$text" "$color_reset"
}

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
