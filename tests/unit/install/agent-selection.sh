
test_multiple_agents_on_command_line() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude gemini

	assert_file_exists ".claude/settings.json" &&
	assert_file_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/agentsmd/claude.sh" &&
	assert_json_has_key ".claude/settings.json" "hooks.SessionStart" &&
	assert_json_has_key ".gemini/settings.json" "context.fileName"
}

test_multiple_agents_reversed_order() {
	local project_dir="$1"

	run_install "$project_dir" -y . gemini claude

	assert_file_exists ".claude/settings.json" &&
	assert_file_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/agentsmd/claude.sh" &&
	assert_json_has_key ".claude/settings.json" "hooks.SessionStart" &&
	assert_json_has_key ".gemini/settings.json" "context.fileName"
}

test_single_agent_explicit() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude

	assert_file_exists ".claude/settings.json" &&
	assert_file_not_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/agentsmd/claude.sh"
}

test_auto_confirm_uses_all_agents() {
	local project_dir="$1"

	# With -y and no agents specified, should use all supported agents
	run_install "$project_dir" -y .

	assert_file_exists ".claude/settings.json" &&
	assert_file_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/agentsmd/claude.sh"
}

test_invalid_agent_error() {
	local project_dir="$1"

	# Should fail with unknown agent
	if run_install "$project_dir" -y . invalidagent 2>&1; then
		echo "Expected command to fail for invalid agent"
		return 1
	fi

	# Should not create any files
	assert_file_not_exists ".claude/settings.json" &&
	assert_file_not_exists ".gemini/settings.json"
}

test_mixed_valid_invalid_agents() {
	local project_dir="$1"

	# Should fail when mixing valid and invalid agents
	if run_install "$project_dir" -y . claude invalidagent 2>&1; then
		echo "Expected command to fail for invalid agent"
		return 1
	fi

	# Should not create any files (fails before applying changes)
	assert_file_not_exists ".claude/settings.json"
}

test_global_mode_multiple_agents() {
	local project_dir="$1"

	# Save existing settings if present
	local claude_backup=""
	local gemini_backup=""
	local polyfill_backup=""
	[ -f "$HOME/.claude/settings.json" ] && claude_backup=$(cat "$HOME/.claude/settings.json")
	[ -f "$HOME/.gemini/settings.json" ] && gemini_backup=$(cat "$HOME/.gemini/settings.json")
	[ -f "$HOME/.agents/polyfills/agentsmd/claude.sh" ] && polyfill_backup=$(cat "$HOME/.agents/polyfills/agentsmd/claude.sh")

	run_install "$project_dir" -y --global claude gemini

	local result=0
	assert_file_exists "$HOME/.claude/settings.json" &&
	assert_file_exists "$HOME/.gemini/settings.json" &&
	assert_file_exists "$HOME/.agents/polyfills/agentsmd/claude.sh" || result=1

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
		mkdir -p "$HOME/.agents/polyfills/agentsmd"
		echo "$polyfill_backup" > "$HOME/.agents/polyfills/agentsmd/claude.sh"
	else
		rm -f "$HOME/.agents/polyfills/agentsmd/claude.sh"
	fi

	return $result
}
