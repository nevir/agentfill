
# Skills symlink tests for project install

test_skills_symlink_created_when_agents_skills_exists() {
	local project_dir="$1"

	# Create .agents/skills directory with a test skill
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	run_install "$project_dir" -y . claude

	# Verify symlink was created
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink"
		return 1
	fi

	local link_target=$(readlink ".claude/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to point to ../.agents/skills, got: $link_target"
		return 1
	fi

	return 0
}

test_skills_symlink_skipped_when_no_agents_skills() {
	local project_dir="$1"

	# Do NOT create .agents/skills directory
	run_install "$project_dir" -y . claude

	# Verify symlink was NOT created
	if [ -e ".claude/skills" ]; then
		echo ".claude/skills should not exist when .agents/skills/ doesn't exist"
		return 1
	fi

	return 0
}

test_skills_symlink_warns_on_existing_directory() {
	local project_dir="$1"

	# Create .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Create existing non-symlink .claude/skills directory (user's skills)
	mkdir -p ".claude/skills"
	echo "# User skill" > ".claude/skills/user-skill.md"

	# Run install and capture output
	local output=$(run_install "$project_dir" -y . claude 2>&1)

	# Verify warning was printed
	if ! echo "$output" | grep -q "Warning"; then
		echo "Expected warning about existing directory"
		echo "Output: $output"
		return 1
	fi

	# Verify existing directory was not replaced
	if [ -L ".claude/skills" ]; then
		echo ".claude/skills should remain a directory, not a symlink"
		return 1
	fi

	# Verify user's content preserved
	if [ ! -f ".claude/skills/user-skill.md" ]; then
		echo "User's skills should be preserved"
		return 1
	fi

	return 0
}

test_skills_symlink_idempotent() {
	local project_dir="$1"

	# Create .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# First install
	run_install "$project_dir" -y . claude

	# Second install - should succeed silently
	local output=$(run_install "$project_dir" -y . claude 2>&1)

	# Verify symlink still exists and is correct
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink after second install"
		return 1
	fi

	local link_target=$(readlink ".claude/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to still point to ../.agents/skills, got: $link_target"
		return 1
	fi

	return 0
}

test_skills_symlink_updates_wrong_target() {
	local project_dir="$1"

	# Create .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Create .claude directory and wrong symlink
	mkdir -p ".claude"
	ln -s "/wrong/target" ".claude/skills"

	# Run install
	run_install "$project_dir" -y . claude

	# Verify symlink was updated to correct target
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink"
		return 1
	fi

	local link_target=$(readlink ".claude/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to be updated to ../.agents/skills, got: $link_target"
		return 1
	fi

	return 0
}

test_skills_symlink_multiple_agents() {
	local project_dir="$1"

	# Create .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Install for both claude and gemini
	run_install "$project_dir" -y . claude gemini

	# Verify both symlinks created
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink"
		return 1
	fi

	if [ ! -L ".gemini/skills" ]; then
		echo "Expected .gemini/skills to be a symlink"
		return 1
	fi

	# Verify both point to correct target
	local claude_target=$(readlink ".claude/skills")
	local gemini_target=$(readlink ".gemini/skills")

	if [ "$claude_target" != "../.agents/skills" ]; then
		echo "Expected .claude/skills to point to ../.agents/skills, got: $claude_target"
		return 1
	fi

	if [ "$gemini_target" != "../.agents/skills" ]; then
		echo "Expected .gemini/skills to point to ../.agents/skills, got: $gemini_target"
		return 1
	fi

	return 0
}

test_skills_symlink_global_mode_skips() {
	local project_dir="$1"

	# Create .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Verify NO symlink was created in project (global mode uses hooks instead)
	if [ -L ".claude/skills" ]; then
		echo ".claude/skills symlink should not be created in global mode"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

# ============================================
# Global skills hook tests
# ============================================

test_global_mode_creates_skills_hook() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Verify skills hook was created
	if [ ! -f "$fake_home/.agents/polyfills/claude/skills.sh" ]; then
		echo "Expected skills.sh hook to be created at $fake_home/.agents/polyfills/claude/skills.sh"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify it's executable
	if [ ! -x "$fake_home/.agents/polyfills/claude/skills.sh" ]; then
		echo "Expected skills.sh to be executable"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_mode_settings_include_skills_hook() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Verify settings.json contains skills hook reference
	if ! grep -q "skills.sh" "$fake_home/.claude/settings.json"; then
		echo "Expected settings.json to reference skills.sh"
		cat "$fake_home/.claude/settings.json"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_creates_symlink_with_project_skills() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Run the skills hook directly
	CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh"

	# Verify symlink was created
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink after hook runs"
		rm -rf "$fake_home"
		return 1
	fi

	local link_target=$(readlink ".claude/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to point to ../.agents/skills, got: $link_target"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_fallback_to_global_skills() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Create global .agents/skills directory (not project)
	mkdir -p "$fake_home/.agents/skills/global-skill"
	echo "# Global skill" > "$fake_home/.agents/skills/global-skill/SKILL.md"

	# Run the skills hook directly
	CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh"

	# Verify symlink was created and points to global skills
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink after hook runs"
		rm -rf "$fake_home"
		return 1
	fi

	local link_target=$(readlink ".claude/skills")
	if [ "$link_target" != "$fake_home/.agents/skills" ]; then
		echo "Expected symlink to point to $fake_home/.agents/skills, got: $link_target"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_prefers_project_over_global() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Create both project and global .agents/skills directories
	mkdir -p ".agents/skills/project-skill"
	echo "# Project skill" > ".agents/skills/project-skill/SKILL.md"
	mkdir -p "$fake_home/.agents/skills/global-skill"
	echo "# Global skill" > "$fake_home/.agents/skills/global-skill/SKILL.md"

	# Run the skills hook directly
	CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh"

	# Verify symlink points to project skills (preferred)
	if [ ! -L ".claude/skills" ]; then
		echo "Expected .claude/skills to be a symlink after hook runs"
		rm -rf "$fake_home"
		return 1
	fi

	local link_target=$(readlink ".claude/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to point to ../.agents/skills (project), got: $link_target"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_silent_without_skills() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Do NOT create any skills directories

	# Run the skills hook directly - should exit silently
	local output=$(CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh" 2>&1)

	# Verify no symlink created
	if [ -e ".claude/skills" ]; then
		echo ".claude/skills should not exist when no skills directories exist"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify no output
	if [ -n "$output" ]; then
		echo "Expected no output when no skills exist, got: $output"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_warns_on_existing_directory() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Create existing non-symlink .claude/skills directory
	mkdir -p ".claude/skills"
	echo "# User skill" > ".claude/skills/user-skill.md"

	# Run the skills hook and capture stderr
	local output=$(CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh" 2>&1)

	# Verify warning was printed
	if ! echo "$output" | grep -q "Warning"; then
		echo "Expected warning about existing directory"
		echo "Output: $output"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify existing directory was not replaced
	if [ -L ".claude/skills" ]; then
		echo ".claude/skills should remain a directory, not a symlink"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify user's content preserved
	if [ ! -f ".claude/skills/user-skill.md" ]; then
		echo "User's skills should be preserved"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_outputs_restart_message() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Run the skills hook and capture output
	local output=$(CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh" 2>&1)

	# Verify restart message was output with XML tags
	if ! echo "$output" | grep -q "<skills_setup>"; then
		echo "Expected <skills_setup> tag in output"
		echo "Output: $output"
		rm -rf "$fake_home"
		return 1
	fi

	if ! echo "$output" | grep -q "restart"; then
		echo "Expected restart instruction in output"
		echo "Output: $output"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_global_skills_hook_silent_when_symlink_exists() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . claude

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Create symlink manually first
	mkdir -p ".claude"
	ln -s "../.agents/skills" ".claude/skills"

	# Run the skills hook and capture output
	local output=$(CLAUDE_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/claude/skills.sh" 2>&1)

	# Verify no output (symlink already exists)
	if [ -n "$output" ]; then
		echo "Expected no output when symlink already exists, got: $output"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_project_mode_does_not_create_skills_hook() {
	local project_dir="$1"

	run_install "$project_dir" -y . claude

	# Verify skills hook was NOT created (project mode doesn't use hooks)
	if [ -f ".agents/polyfills/claude/skills.sh" ]; then
		echo "skills.sh should not be created in project mode"
		return 1
	fi

	# Verify settings.json does NOT reference skills hook
	if grep -q "skills.sh" ".claude/settings.json"; then
		echo "settings.json should not reference skills.sh in project mode"
		return 1
	fi

	return 0
}

# ============================================
# Gemini global skills hook tests
# ============================================

test_gemini_global_mode_creates_skills_hook() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Verify skills hook was created
	if [ ! -f "$fake_home/.agents/polyfills/gemini/skills.sh" ]; then
		echo "Expected skills.sh hook to be created at $fake_home/.agents/polyfills/gemini/skills.sh"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify it's executable
	if [ ! -x "$fake_home/.agents/polyfills/gemini/skills.sh" ]; then
		echo "Expected skills.sh to be executable"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_mode_settings_include_skills_hook() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Verify settings.json contains skills hook reference
	if ! grep -q "skills.sh" "$fake_home/.gemini/settings.json"; then
		echo "Expected settings.json to reference skills.sh"
		cat "$fake_home/.gemini/settings.json"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify hooks structure is present
	if ! grep -q "SessionStart" "$fake_home/.gemini/settings.json"; then
		echo "Expected settings.json to have SessionStart hook"
		cat "$fake_home/.gemini/settings.json"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_skills_hook_creates_symlink() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Run the skills hook directly
	GEMINI_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/gemini/skills.sh"

	# Verify symlink was created
	if [ ! -L ".gemini/skills" ]; then
		echo "Expected .gemini/skills to be a symlink after hook runs"
		rm -rf "$fake_home"
		return 1
	fi

	local link_target=$(readlink ".gemini/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to point to ../.agents/skills, got: $link_target"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_skills_hook_fallback_to_global() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Create global .agents/skills directory (not project)
	mkdir -p "$fake_home/.agents/skills/global-skill"
	echo "# Global skill" > "$fake_home/.agents/skills/global-skill/SKILL.md"

	# Run the skills hook directly
	GEMINI_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/gemini/skills.sh"

	# Verify symlink was created and points to global skills
	if [ ! -L ".gemini/skills" ]; then
		echo "Expected .gemini/skills to be a symlink after hook runs"
		rm -rf "$fake_home"
		return 1
	fi

	local link_target=$(readlink ".gemini/skills")
	if [ "$link_target" != "$fake_home/.agents/skills" ]; then
		echo "Expected symlink to point to $fake_home/.agents/skills, got: $link_target"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_skills_hook_prefers_project() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Create both project and global .agents/skills directories
	mkdir -p ".agents/skills/project-skill"
	echo "# Project skill" > ".agents/skills/project-skill/SKILL.md"
	mkdir -p "$fake_home/.agents/skills/global-skill"
	echo "# Global skill" > "$fake_home/.agents/skills/global-skill/SKILL.md"

	# Run the skills hook directly
	GEMINI_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/gemini/skills.sh"

	# Verify symlink points to project skills (preferred)
	if [ ! -L ".gemini/skills" ]; then
		echo "Expected .gemini/skills to be a symlink after hook runs"
		rm -rf "$fake_home"
		return 1
	fi

	local link_target=$(readlink ".gemini/skills")
	if [ "$link_target" != "../.agents/skills" ]; then
		echo "Expected symlink to point to ../.agents/skills (project), got: $link_target"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_skills_hook_silent_without_skills() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Do NOT create any skills directories

	# Run the skills hook directly - should exit silently
	local output=$(GEMINI_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/gemini/skills.sh" 2>&1)

	# Verify no symlink created
	if [ -e ".gemini/skills" ]; then
		echo ".gemini/skills should not exist when no skills directories exist"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify no output
	if [ -n "$output" ]; then
		echo "Expected no output when no skills exist, got: $output"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_skills_hook_warns_on_existing() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Create existing non-symlink .gemini/skills directory
	mkdir -p ".gemini/skills"
	echo "# User skill" > ".gemini/skills/user-skill.md"

	# Run the skills hook and capture stderr
	local output=$(GEMINI_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/gemini/skills.sh" 2>&1)

	# Verify warning was printed
	if ! echo "$output" | grep -q "Warning"; then
		echo "Expected warning about existing directory"
		echo "Output: $output"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify existing directory was not replaced
	if [ -L ".gemini/skills" ]; then
		echo ".gemini/skills should remain a directory, not a symlink"
		rm -rf "$fake_home"
		return 1
	fi

	# Verify user's content preserved
	if [ ! -f ".gemini/skills/user-skill.md" ]; then
		echo "User's skills should be preserved"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_global_skills_hook_outputs_restart_message() {
	local project_dir="$1"

	# Create a fake HOME for global install
	local fake_home=$(mktemp -d)
	HOME="$fake_home" run_install "$project_dir" -y --global . gemini

	# Create project .agents/skills directory
	mkdir -p ".agents/skills/test-skill"
	echo "# Test skill" > ".agents/skills/test-skill/SKILL.md"

	# Run the skills hook and capture output
	local output=$(GEMINI_PROJECT_DIR="$project_dir" HOME="$fake_home" sh "$fake_home/.agents/polyfills/gemini/skills.sh" 2>&1)

	# Verify restart message was output with XML tags
	if ! echo "$output" | grep -q "<skills_setup>"; then
		echo "Expected <skills_setup> tag in output"
		echo "Output: $output"
		rm -rf "$fake_home"
		return 1
	fi

	if ! echo "$output" | grep -q "restart"; then
		echo "Expected restart instruction in output"
		echo "Output: $output"
		rm -rf "$fake_home"
		return 1
	fi

	rm -rf "$fake_home"
	return 0
}

test_gemini_project_mode_no_skills_hook() {
	local project_dir="$1"

	run_install "$project_dir" -y . gemini

	# Verify skills hook was NOT created (project mode doesn't use hooks)
	if [ -f ".agents/polyfills/gemini/skills.sh" ]; then
		echo "skills.sh should not be created in project mode"
		return 1
	fi

	# Verify settings.json does NOT have hooks section
	if grep -q "hooks" ".gemini/settings.json"; then
		echo "settings.json should not have hooks section in project mode"
		cat ".gemini/settings.json"
		return 1
	fi

	return 0
}
