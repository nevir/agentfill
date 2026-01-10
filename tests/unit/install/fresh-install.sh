
test_fresh_install_all_agents() {
	local project_dir="$1"

	run_install "$project_dir" -y .

	assert_file_exists ".claude/settings.json" &&
	assert_file_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/claude/agentsmd.sh" &&
	assert_json_has_key ".claude/settings.json" "hooks.SessionStart" &&
	assert_json_has_key ".gemini/settings.json" "context.fileName"
}

test_fresh_install_claude_only() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude

	assert_file_exists ".claude/settings.json" &&
	assert_file_not_exists ".gemini/settings.json" &&
	assert_file_exists ".agents/polyfills/claude/agentsmd.sh"
}

test_fresh_install_gemini_only() {
	local project_dir="$1"

	run_install "$project_dir" -y . gemini

	assert_file_not_exists ".claude/settings.json" &&
	assert_file_exists ".gemini/settings.json" &&
	assert_file_not_exists ".agents/polyfills/claude/agentsmd.sh"
}
