
# Helper to run Cursor IDE polyfill script with isolated HOME
run_cursor_ide_polyfill_isolated() {
	local project_dir="$1"
	local temp_home
	temp_home=$(mktemp -d)
	local output
	output=$(HOME="$temp_home" CURSOR_PROJECT_DIR="$project_dir" sh "$REPO_ROOT/.agents/polyfills/agentsmd/cursor-ide.sh")
	rm -rf "$temp_home"
	printf '%s\n' "$output"
}

# Helper to extract additional_context from JSON output
extract_context() {
	perl -MJSON::PP -0777 -e '
		my $data = JSON::PP->new->utf8->decode(do { local $/; <STDIN> });
		print $data->{additional_context} // "";
	'
}

test_cursor_ide_no_agentsmd_files() {
	local project_dir="$1"

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")
	local exit_code=$?

	# Should exit with 0 and produce valid JSON with continue:true
	[ "$exit_code" -eq 0 ] &&
	printf '%s\n' "$output" |perl -MJSON::PP -e '
		my $data = JSON::PP->new->utf8->decode(do { local $/; <STDIN> });
		exit 1 unless $data->{continue};
		exit 1 if exists $data->{additional_context};
		exit 0;
	'
}

test_cursor_ide_single_root_agentsmd() {
	local project_dir="$1"

	cat > "$project_dir/AGENTS.md" <<-end_agentsmd
		# Test Project
		This is a test AGENTS.md file.
	end_agentsmd

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")

	# Should be valid JSON
	local context
	context=$(printf '%s\n' "$output" |extract_context)

	echo "$context" | grep -q "<agentsmd_instructions>" &&
	echo "$context" | grep -q "<available_agentsmd_files>" &&
	echo "$context" | grep -q "./AGENTS.md" &&
	echo "$context" | grep -q "# Test Project" &&
	echo "$context" | grep -q "This is a test AGENTS.md file."
}

test_cursor_ide_multiple_nested_agentsmd() {
	local project_dir="$1"

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

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")
	local context
	context=$(printf '%s\n' "$output" |extract_context)

	echo "$context" | grep -q "<available_agentsmd_files>" &&
	echo "$context" | grep -q "./AGENTS.md" &&
	echo "$context" | grep -q "./subfolder/AGENTS.md" &&
	echo "$context" | grep -q "./deep/nested/path/AGENTS.md" &&
	echo "$context" | grep -q "# Root Instructions"
}

test_cursor_ide_output_is_valid_json() {
	local project_dir="$1"

	cat > "$project_dir/AGENTS.md" <<-end_agentsmd
		# JSON Test
	end_agentsmd

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")

	# Verify it's valid JSON with expected fields
	printf '%s\n' "$output" |perl -MJSON::PP -e '
		my $data = JSON::PP->new->utf8->decode(do { local $/; <STDIN> });
		exit 1 unless exists $data->{additional_context};
		exit 1 unless $data->{continue};
		exit 1 unless length($data->{additional_context}) > 0;
		exit 0;
	'
}

test_cursor_ide_json_encodes_special_characters() {
	local project_dir="$1"

	cat > "$project_dir/AGENTS.md" <<-'end_agentsmd'
		# Special Characters Test
		Use `backticks` and $variables and "quotes"
		<xml>tags</xml>
		Line with \ backslash
	end_agentsmd

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")

	# Verify output is valid JSON (Perl will fail to decode if not)
	local context
	context=$(printf '%s\n' "$output" |extract_context)

	# Verify special characters survived the JSON encoding round-trip
	echo "$context" | grep -q 'backticks' &&
	echo "$context" | grep -q 'quotes' &&
	echo "$context" | grep -q '<xml>tags</xml>' &&
	echo "$context" | grep -q 'backslash'
}

test_cursor_ide_context_contains_instructions() {
	local project_dir="$1"

	cat > "$project_dir/AGENTS.md" <<-end_agentsmd
		# Format Test
	end_agentsmd

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")
	local context
	context=$(printf '%s\n' "$output" |extract_context)

	# Verify key instruction text
	echo "$context" | grep -q "NON-NEGOTIABLE" &&
	echo "$context" | grep -q "Load ALL AGENTS.md files" &&
	echo "$context" | grep -q "<agentsmd_instructions>" &&
	echo "$context" | grep -q "</agentsmd_instructions>"
}

test_cursor_ide_empty_agentsmd_file() {
	local project_dir="$1"

	touch "$project_dir/AGENTS.md"

	local output
	output=$(run_cursor_ide_polyfill_isolated "$project_dir")

	# Should still produce valid JSON with the file listed
	local context
	context=$(printf '%s\n' "$output" |extract_context)

	echo "$context" | grep -q "<available_agentsmd_files>" &&
	echo "$context" | grep -q "./AGENTS.md"
}
