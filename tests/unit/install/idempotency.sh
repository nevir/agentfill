
test_idempotent_rerun() {
	local project_dir="$1"

	run_install "$project_dir" -y .

	local output=$(run_install "$project_dir" -n . 2>&1)

	echo "$output" | grep -q "SKIP.*AGENTS.md" &&
	echo "$output" | grep -q "SKIP.*claude" &&
	echo "$output" | grep -q "SKIP.*gemini"
}

test_skip_when_already_configured() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude

	mkdir -p ".claude"
	cat > ".claude/settings.json" <<'EOF'
{
  "permissions": {
    "allow": ["Bash(*)"]
  }
}
EOF

	run_install "$project_dir" -y . claude

	local output=$(run_install "$project_dir" -n . claude 2>&1)

	echo "$output" | grep -q "SKIP.*claude" &&
	assert_file_contains ".claude/settings.json" "claude_agentsmd.sh"
}

test_existing_agents_md_preserved() {
	local project_dir="$1"

	echo "# My custom instructions" > "AGENTS.md"

	run_install "$project_dir" -y .

	assert_file_contains "AGENTS.md" "My custom instructions"
}
