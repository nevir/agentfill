
# Helper to run polyfill script with isolated HOME
run_polyfill_isolated() {
	local project_dir="$1"
	local temp_home
	temp_home=$(mktemp -d)
	local output
	output=$(HOME="$temp_home" CLAUDE_PROJECT_DIR="$project_dir" sh "$REPO_ROOT/.agents/polyfills/agentsmd/claude.sh")
	rm -rf "$temp_home"
	echo "$output"
}

test_no_agentsmd_files() {
	local project_dir="$1"

	# Run the polyfill script with no AGENTS.md files
	local output
	output=$(run_polyfill_isolated "$project_dir")
	local exit_code=$?

	# Should exit with 0 and produce no output
	[ "$exit_code" -eq 0 ] &&
	[ -z "$output" ]
}

test_single_root_agentsmd() {
	local project_dir="$1"

	# Create a root AGENTS.md
	cat > "$project_dir/AGENTS.md" <<-end_agentsmd
		# Test Project
		This is a test AGENTS.md file.
	end_agentsmd

	# Run the polyfill script
	local output
	output=$(run_polyfill_isolated "$project_dir")

	# Should output the instructions and root content
	echo "$output" | grep -q "<agentsmd_instructions>" &&
	echo "$output" | grep -q "<available_agentsmd_files>" &&
	echo "$output" | grep -q "./AGENTS.md" &&
	echo "$output" | grep -q 'path="./AGENTS.md"' &&
	echo "$output" | grep -q "# Test Project" &&
	echo "$output" | grep -q "This is a test AGENTS.md file."
}

test_multiple_nested_agentsmd() {
	local project_dir="$1"

	# Create multiple AGENTS.md files
	cat > "$project_dir/AGENTS.md" <<-end_root
		# Root Instructions
	end_root

	mkdir -p "$project_dir/subfolder"
	cat > "$project_dir/subfolder/AGENTS.md" <<-end_subfolder
		# Subfolder Instructions
	end_subfolder

	mkdir -p "$project_dir/deep/nested/path"
	cat > "$project_dir/deep/nested/path/AGENTS.md" <<-end_deep
		# Deep Instructions
	end_deep

	# Run the polyfill script
	local output
	output=$(run_polyfill_isolated "$project_dir")

	# Should list all AGENTS.md files
	echo "$output" | grep -q "<available_agentsmd_files>" &&
	echo "$output" | grep -q "./AGENTS.md" &&
	echo "$output" | grep -q "./subfolder/AGENTS.md" &&
	echo "$output" | grep -q "./deep/nested/path/AGENTS.md" &&
	# Should include root content
	echo "$output" | grep -q 'path="./AGENTS.md"' &&
	echo "$output" | grep -q "# Root Instructions"
}

test_nested_agentsmd_without_root() {
	local project_dir="$1"

	# Create nested AGENTS.md files but no root
	mkdir -p "$project_dir/subfolder"
	cat > "$project_dir/subfolder/AGENTS.md" <<-end_subfolder
		# Subfolder Only
	end_subfolder

	# Run the polyfill script
	local output
	output=$(run_polyfill_isolated "$project_dir")

	# Should list the subfolder file
	echo "$output" | grep -q "<available_agentsmd_files>" &&
	echo "$output" | grep -q "./subfolder/AGENTS.md" &&
	# Should NOT have root AGENTS.md content
	! echo "$output" | grep -q 'path="./AGENTS.md"'
}

test_output_format_structure() {
	local project_dir="$1"

	# Create a simple AGENTS.md
	cat > "$project_dir/AGENTS.md" <<-end_agentsmd
		# Format Test
	end_agentsmd

	# Run the polyfill script
	local output
	output=$(run_polyfill_isolated "$project_dir")

	# Verify complete XML-like structure
	echo "$output" | grep -q "<agentsmd_instructions>" &&
	echo "$output" | grep -q "</agentsmd_instructions>" &&
	echo "$output" | grep -q "<available_agentsmd_files>" &&
	echo "$output" | grep -q "</available_agentsmd_files>" &&
	echo "$output" | grep -q 'path="./AGENTS.md"' &&
	echo "$output" | grep -q "</agentsmd>" &&
	# Verify key instruction text
	echo "$output" | grep -q "NON-NEGOTIABLE" &&
	echo "$output" | grep -q "Load ALL AGENTS.md files"
}

test_special_characters_in_agentsmd() {
	local project_dir="$1"

	# Create AGENTS.md with special characters
	cat > "$project_dir/AGENTS.md" <<-'end_agentsmd'
		# Special Characters Test
		Use `backticks` and $variables and "quotes"
		<xml>tags</xml>
		Line with \ backslash
	end_agentsmd

	# Run the polyfill script
	local output
	output=$(run_polyfill_isolated "$project_dir")

	# Should preserve special characters
	echo "$output" | grep -q '`backticks`' &&
	echo "$output" | grep -q '\$variables' &&
	echo "$output" | grep -q '"quotes"' &&
	echo "$output" | grep -q '<xml>tags</xml>' &&
	echo "$output" | grep -q 'backslash'
}

test_empty_agentsmd_file() {
	local project_dir="$1"

	# Create an empty AGENTS.md
	touch "$project_dir/AGENTS.md"

	# Run the polyfill script
	local output
	output=$(run_polyfill_isolated "$project_dir")

	# Should still run successfully and include the file
	echo "$output" | grep -q "<available_agentsmd_files>" &&
	echo "$output" | grep -q "./AGENTS.md" &&
	echo "$output" | grep -q 'path="./AGENTS.md"' &&
	echo "$output" | grep -q "</agentsmd>"
}
