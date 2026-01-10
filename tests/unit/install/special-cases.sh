
test_polyfill_update() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude

	local polyfill=".agents/polyfills/claude/agentsmd.sh"
	echo "# old version" > "$polyfill"

	local output=$(run_install "$project_dir" -y -n . claude 2>&1)

	echo "$output" | grep -q "MODIFY.*polyfill"
}

test_dry_run_no_changes() {
	local project_dir="$1"

	local output=$(run_install "$project_dir" -y -n . 2>&1)

	echo "$output" | grep -q "Dry-run mode" &&
	assert_file_not_exists "AGENTS.md" &&
	assert_file_not_exists ".claude/settings.json"
}
