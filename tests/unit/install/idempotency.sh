
test_idempotent_rerun() {
	local project_dir="$1"

	run_install "$project_dir" -y .

	local output=$(run_install "$project_dir" -y -n . 2>&1)

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

	local output=$(run_install "$project_dir" -y -n . claude 2>&1)

	echo "$output" | grep -q "SKIP.*claude" &&
	assert_file_contains ".claude/settings.json" "agentsmd/claude.sh"
}

