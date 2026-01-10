
test_global_mode_creates_home_settings() {
	local project_dir="$1"

	# Save existing settings if present
	local claude_backup=""
	local gemini_backup=""
	local polyfill_backup=""
	[ -f "$HOME/.claude/settings.json" ] && claude_backup=$(cat "$HOME/.claude/settings.json")
	[ -f "$HOME/.gemini/settings.json" ] && gemini_backup=$(cat "$HOME/.gemini/settings.json")
	[ -f "$HOME/.agents/polyfills/claude/agentsmd.sh" ] && polyfill_backup=$(cat "$HOME/.agents/polyfills/claude/agentsmd.sh")

	run_install "$project_dir" -y --global

	local result=0
	assert_file_exists "$HOME/.claude/settings.json" &&
	assert_file_exists "$HOME/.gemini/settings.json" &&
	assert_file_exists "$HOME/.agents/polyfills/claude/agentsmd.sh" &&
	assert_file_not_exists ".claude/settings.json" &&
	assert_file_not_exists ".gemini/settings.json" &&
	assert_file_not_exists "AGENTS.md" || result=1

	# Restore backups
	if [ -n "$claude_backup" ]; then
		mkdir -p "$HOME/.claude"
		echo "$claude_backup" > "$HOME/.claude/settings.json"
	else
		rm -f "$HOME/.claude/settings.json"
	fi
	if [ -n "$gemini_backup" ]; then
		mkdir -p "$HOME/.gemini"
		echo "$gemini_backup" > "$HOME/.gemini/settings.json"
	else
		rm -f "$HOME/.gemini/settings.json"
	fi
	if [ -n "$polyfill_backup" ]; then
		mkdir -p "$HOME/.agents/polyfills"
		echo "$polyfill_backup" > "$HOME/.agents/polyfills/claude/agentsmd.sh"
	else
		rm -f "$HOME/.agents/polyfills/claude/agentsmd.sh"
	fi

	return $result
}

test_global_mode_polyfill_reference() {
	local project_dir="$1"

	# Save existing settings if present
	local claude_backup=""
	[ -f "$HOME/.claude/settings.json" ] && claude_backup=$(cat "$HOME/.claude/settings.json")

	run_install "$project_dir" -y --global claude

	local result=0
	# Polyfill should reference absolute home path
	assert_file_contains "$HOME/.claude/settings.json" "$HOME/.agents/polyfills/claude/agentsmd.sh" || result=1

	# Restore backup
	if [ -n "$claude_backup" ]; then
		mkdir -p "$HOME/.claude"
		echo "$claude_backup" > "$HOME/.claude/settings.json"
	else
		rm -f "$HOME/.claude/settings.json"
	fi

	return $result
}

test_global_mode_single_agent() {
	local project_dir="$1"

	# Save existing settings if present
	local gemini_backup=""
	local claude_backup=""
	local polyfill_backup=""
	local claude_existed=0
	local polyfill_existed=0
	[ -f "$HOME/.gemini/settings.json" ] && gemini_backup=$(cat "$HOME/.gemini/settings.json")
	if [ -f "$HOME/.claude/settings.json" ]; then
		claude_backup=$(cat "$HOME/.claude/settings.json")
		claude_existed=1
	fi
	if [ -f "$HOME/.agents/polyfills/claude/agentsmd.sh" ]; then
		polyfill_backup=$(cat "$HOME/.agents/polyfills/claude/agentsmd.sh")
		polyfill_existed=1
	fi

	run_install "$project_dir" -y --global gemini

	local result=0
	# Note: We can't assert files don't exist if they existed before this test
	assert_file_exists "$HOME/.gemini/settings.json" || result=1

	# Only check that claude-specific files weren't created if they didn't exist before
	if [ $claude_existed -eq 0 ]; then
		assert_file_not_exists "$HOME/.claude/settings.json" || result=1
	fi
	if [ $polyfill_existed -eq 0 ]; then
		assert_file_not_exists "$HOME/.agents/polyfills/claude/agentsmd.sh" || result=1
	fi

	# Restore backups
	if [ -n "$gemini_backup" ]; then
		mkdir -p "$HOME/.gemini"
		echo "$gemini_backup" > "$HOME/.gemini/settings.json"
	else
		rm -f "$HOME/.gemini/settings.json"
	fi
	if [ -n "$claude_backup" ]; then
		mkdir -p "$HOME/.claude"
		echo "$claude_backup" > "$HOME/.claude/settings.json"
	elif [ $claude_existed -eq 0 ]; then
		rm -f "$HOME/.claude/settings.json"
	fi
	if [ -n "$polyfill_backup" ]; then
		mkdir -p "$HOME/.agents/polyfills"
		echo "$polyfill_backup" > "$HOME/.agents/polyfills/claude/agentsmd.sh"
	elif [ $polyfill_existed -eq 0 ]; then
		rm -f "$HOME/.agents/polyfills/claude/agentsmd.sh"
	fi

	return $result
}

test_default_mode_unchanged() {
	local project_dir="$1"

	run_install "$project_dir" -y .

	assert_file_exists ".claude/settings.json" &&
	assert_file_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/claude/agentsmd.sh" &&
	assert_file_not_exists "AGENTS.md"
}

test_default_mode_polyfill_reference() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude

	# Polyfill should reference project directory path
	assert_file_contains ".claude/settings.json" "\$CLAUDE_PROJECT_DIR/.agents/polyfills/claude/agentsmd.sh"
}
