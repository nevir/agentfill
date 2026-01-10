
test_merge_claude_existing_permissions() {
	local project_dir="$1"

	mkdir -p ".claude"
	cat > ".claude/settings.json" <<'EOF'
{
  "permissions": {
    "allow": ["Bash(npm *)"]
  }
}
EOF

	run_install "$project_dir" -y . claude

	assert_file_contains ".claude/settings.json" "npm" &&
	assert_file_contains ".claude/settings.json" "claude/agentsmd.sh"
}

test_merge_gemini_existing_context() {
	local project_dir="$1"

	mkdir -p ".gemini"
	cat > ".gemini/settings.json" <<'EOF'
{
  "context": {
    "fileName": ["README.md"]
  },
  "customField": true
}
EOF

	run_install "$project_dir" -y . gemini

	assert_file_contains ".gemini/settings.json" "README.md" &&
	assert_file_contains ".gemini/settings.json" "AGENTS.md" &&
	assert_file_contains ".gemini/settings.json" "customField"
}
