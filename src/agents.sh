# ============================================
# Agent detection and selection
# ============================================

# User input FD for interactive prompts.
# Allows reading user input even when stdin is a pipe (curl | sh).
USER_INPUT_FD=""

open_user_input() {
	if [ -t 0 ]; then
		exec 3<&0
		USER_INPUT_FD=3
	elif (exec </dev/tty) 2>/dev/null; then
		exec 3</dev/tty
		USER_INPUT_FD=3
	else
		USER_INPUT_FD=""
	fi
}

is_interactive() {
	[ -n "$USER_INPUT_FD" ]
}

# Get the CLI binary name for detecting an agent
agent_detect_binary() {
	echo "$1"
}

detect_installed_agents() {
	local installed=""
	for agent in $SUPPORTED_AGENTS; do
		local binary
		binary=$(agent_detect_binary "$agent")
		if command -v "$binary" >/dev/null 2>&1; then
			installed="$installed $agent"
		fi
	done
	trim "$installed"
}

# Agent display labels
agent_label() {
	case "$1" in
		claude) echo "Claude Code" ;;
		cursor) echo "Cursor" ;;
		gemini) echo "Gemini CLI" ;;
		*)      echo "$1" ;;
	esac
}

# ── Checkbox TUI ─────────────────────────────────────────────
# Interactive checkbox selector with arrow keys + space/enter.
# Falls back to a simple numbered prompt if raw mode fails.

_saved_tty=""

_tui_setup() {
	_saved_tty=$(stty -g <&3 2>/dev/null) || true
	stty raw -echo <&3 2>/dev/null
}

_tui_teardown() {
	if [ -n "$_saved_tty" ]; then
		stty "$_saved_tty" <&3 2>/dev/null || true
		_saved_tty=""
	fi
}

# Read a single byte from the user input FD
_read_char() {
	dd bs=1 count=1 2>/dev/null <&3
}

# Read a keypress, handling multi-byte escape sequences.
# Sets _KEY to one of: UP DOWN SPACE ENTER QUIT OTHER
_read_key() {
	local ch
	ch=$(_read_char)
	case "$ch" in
		"$(printf '\033')")
			# Escape sequence — read two more bytes
			local seq1 seq2
			seq1=$(_read_char)
			seq2=$(_read_char)
			case "$seq1$seq2" in
				"[A") _KEY=UP ;;
				"[B") _KEY=DOWN ;;
				*)    _KEY=OTHER ;;
			esac
			;;
		" ")       _KEY=TOGGLE ;;
		"$(printf '\r')" | "$(printf '\n')" | "") _KEY=TOGGLE ;;
		y|Y)       _KEY=CONFIRM ;;
		q|Q)       _KEY=QUIT ;;
		"$(printf '\003')") _KEY=QUIT ;;  # Ctrl+C
		*)         _KEY=OTHER ;;
	esac
}

# Render the checkbox list. Writes to stderr.
# Uses _cb_cur (cursor index), _cb_sel_N (selected state), _cb_det_N (detected)
_cb_render() {
	local i=0
	for agent in $SUPPORTED_AGENTS; do
		local sel det label pointer check
		eval "sel=\$_cb_sel_$i"
		eval "det=\$_cb_det_$i"
		label=$(agent_label "$agent")

		if [ "$i" = "$_cb_cur" ]; then
			pointer="$(c heading '>')"
		else
			pointer=" "
		fi

		if [ "$sel" = 1 ]; then
			check="$(c success '[✓]')"
		else
			check="[ ]"
		fi

		local suffix=""
		[ "$det" = 1 ] && suffix=" $(c blue '(detected)')"

		printf "\r  %b %b %-12s%b\r\n" "$pointer" "$check" "$label" "$suffix" >&2
		i=$((i + 1))
	done
	printf "\r\n\r  ⇅ $(c dim navigate)  ⏎ $(c dim toggle)  y $(c dim confirm)\r\n" >&2
}

# Move cursor up N lines (for redrawing)
_cb_cursor_up() {
	local n=$1
	printf "\033[%dA" "$n" >&2
}

# Clear current line
_cb_clear_line() {
	printf "\033[2K\r" >&2
}

# Redraw the checkbox UI (clear then re-render)
_cb_redraw() {
	# Total lines: agent_count + 1 (blank) + 1 (hint) = agent_count + 2
	local total_lines=$(( _cb_count + 2 ))
	_cb_cursor_up "$total_lines"
	local i=0
	while [ "$i" -lt "$total_lines" ]; do
		_cb_clear_line
		printf "\n" >&2
		i=$((i + 1))
	done
	_cb_cursor_up "$total_lines"
	_cb_render
}

# Main checkbox selection UI.
# Pre-selects detected agents. Sets SELECTED_AGENTS to space-separated list.
# Must be called directly (not in a subshell) so stty changes affect the terminal.
select_agents_checkbox() {
	local installed
	installed=$(detect_installed_agents)

	# Count agents and initialize state
	_cb_count=0
	_cb_cur=0
	for agent in $SUPPORTED_AGENTS; do
		eval "_cb_sel_$_cb_count=0"
		eval "_cb_det_$_cb_count=0"
		if list_contains "$agent" "$installed"; then
			eval "_cb_sel_$_cb_count=1"
			eval "_cb_det_$_cb_count=1"
		fi
		_cb_count=$((_cb_count + 1))
	done

	printf "\n$(c heading 'Select agents to configure:')\n\n" >&2
	_cb_render

	if ! _tui_setup; then
		# Raw mode failed — fall back to simple prompt
		select_agents_simple
		return
	fi

	trap '_tui_teardown; printf "\n" >&2; exit 130' INT

	while true; do
		_read_key
		case "$_KEY" in
			UP)
				_cb_cur=$(( (_cb_cur - 1 + _cb_count) % _cb_count ))
				_cb_redraw
				;;
			DOWN)
				_cb_cur=$(( (_cb_cur + 1) % _cb_count ))
				_cb_redraw
				;;
			TOGGLE)
				local cur_sel
				eval "cur_sel=\$_cb_sel_$_cb_cur"
				if [ "$cur_sel" = 1 ]; then
					eval "_cb_sel_$_cb_cur=0"
				else
					eval "_cb_sel_$_cb_cur=1"
				fi
				_cb_redraw
				;;
			CONFIRM)
				_tui_teardown
				trap - INT
				# Collect selected agents
				local result="" i=0
				for agent in $SUPPORTED_AGENTS; do
					local sel
					eval "sel=\$_cb_sel_$i"
					[ "$sel" = 1 ] && result="$result $agent"
					i=$((i + 1))
				done
				SELECTED_AGENTS=$(trim "$result")
				if [ -z "$SELECTED_AGENTS" ]; then
					printf "\n$(c warning 'No agents selected.')\n" >&2
					exit 0
				fi
				return
				;;
			QUIT)
				_tui_teardown
				trap - INT
				printf "\n" >&2
				exit 130
				;;
		esac
	done
}

# Fallback: simple numbered prompt for when raw mode is not available.
# Sets SELECTED_AGENTS to space-separated list.
select_agents_simple() {
	printf "\n$(c heading 'Select agents to configure:')\n\n" >&2
	local i=1
	for agent in $SUPPORTED_AGENTS; do
		printf "  %d) %s\n" "$i" "$(agent_label "$agent")" >&2
		i=$((i + 1))
	done
	printf "  %d) All agents\n" "$i" >&2
	printf "\nEnter numbers (space-separated): " >&2
	read -r response <&3

	response=$(trim "$response")
	if [ -z "$response" ] || [ "$response" = "$i" ]; then
		SELECTED_AGENTS="$SUPPORTED_AGENTS"
		return
	fi

	local result=""
	for num in $response; do
		local j=1
		for agent in $SUPPORTED_AGENTS; do
			if [ "$j" = "$num" ]; then
				result="$result $agent"
			fi
			j=$((j + 1))
		done
	done
	result=$(trim "$result")
	if [ -z "$result" ]; then
		SELECTED_AGENTS="$SUPPORTED_AGENTS"
	else
		SELECTED_AGENTS="$result"
	fi
}

# Main entry point for agent selection (interactive).
# Sets SELECTED_AGENTS — must be called directly, not in a subshell.
select_agents() {
	if _tui_available; then
		select_agents_checkbox
	else
		select_agents_simple
	fi
}

# Check whether the TUI can be used (stty raw works on our input FD)
_tui_available() {
	local saved
	saved=$(stty -g <&3 2>/dev/null) || return 1
	stty raw -echo <&3 2>/dev/null || return 1
	stty "$saved" <&3 2>/dev/null
	return 0
}
