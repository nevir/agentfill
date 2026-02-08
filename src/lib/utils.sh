# ============================================
# Utilities
# ============================================

list_contains() {
	local item="$1"
	local list="$2"
	for list_item in $list; do
		[ "$item" = "$list_item" ] && return 0
	done
	return 1
}

trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}

# Convert agent name to valid shell function name (e.g. some-agent -> some_agent)
func_name() {
	echo "$1" | tr '-' '_'
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
