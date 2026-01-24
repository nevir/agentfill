#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export TESTS_DIR="$SCRIPT_DIR/agents"

cd "$REPO_ROOT"

# Load agent detection (auto-configures VERBOSE and DISABLE_COLORS)
. "$SCRIPT_DIR/_common/agent-detection.sh"

# Load common libraries (after setting DISABLE_COLORS)
. "$SCRIPT_DIR/_common/colors.sh"
. "$SCRIPT_DIR/_common/utils.sh"
. "$SCRIPT_DIR/_common/output.sh"

# ============================================
# Agent-specific Configuration
# ============================================

# Define agent-specific commands and settings paths
# This centralizes agent configuration so new agents only need to be added here

KNOWN_AGENTS="claude codex copilot cursor-agent gemini"

agent_command() {
	local agent="$1"
	local prompt="$2"

	case "$agent" in
		claude)       echo "echo \"$prompt\" | claude --print" ;;
		codex)        echo "echo \"$prompt\" | codex exec -" ;;
		copilot)      echo "copilot -p \"$prompt\"" ;;
		cursor-agent) echo "echo \"$prompt\" | cursor-agent --print" ;;
		gemini)       echo "echo \"$prompt\" | gemini" ;;
	esac
}

# Get command to run agent interactively (for debug mode)
agent_interactive_command() {
	local agent="$1"

	case "$agent" in
		claude)       echo "claude" ;;
		codex)        echo "codex" ;;
		copilot)      echo "copilot" ;;
		cursor-agent) echo "cursor-agent" ;;
		gemini)       echo "gemini" ;;
	esac
}

agent_settings_path() {
	local agent="$1"

	case "$agent" in
		claude)       echo "$HOME/.claude/settings.json" ;;
		codex)        echo "$HOME/.codex/config.toml" ;;
		copilot)      echo "$HOME/.copilot/config.json" ;;
		cursor-agent) echo "$HOME/.cursor-agent/settings.json" ;;
		gemini)       echo "$HOME/.gemini/settings.json" ;;
	esac
}

# Get the agent's config directory name (for credential copying)
agent_config_dir() {
	local agent="$1"

	case "$agent" in
		claude)       echo ".claude" ;;
		codex)        echo ".codex" ;;
		copilot)      echo ".copilot" ;;
		cursor-agent) echo ".cursor-agent" ;;
		gemini)       echo ".gemini" ;;
	esac
}

# Get the agent's skills directory path (relative to project root)
agent_skills_dir() {
	local agent="$1"

	case "$agent" in
		claude)       echo ".claude/skills" ;;
		codex)        echo ".codex/skills" ;;
		copilot)      echo ".github/skills" ;;
		cursor-agent) echo ".cursor-agent/skills" ;;
		gemini)       echo ".gemini/skills" ;;
	esac
}

# Copy agent credentials from real HOME to temp HOME
# Copies the agent's config directory and root-level config files,
# but excludes settings files that will be created by install.sh
copy_agent_credentials() {
	local agent="$1"
	local real_home="$2"
	local temp_home="$3"

	local config_dir
	config_dir=$(agent_config_dir "$agent")
	[ -z "$config_dir" ] && return 0

	local src="$real_home/$config_dir"
	local dst="$temp_home/$config_dir"

	# Copy agent config directory if it exists
	if [ -d "$src" ]; then
		mkdir -p "$dst"
		cp -R "$src/"* "$src/".* "$dst/" 2>/dev/null || true

		# Remove settings files that will be created by install.sh
		# (we want fresh settings, but keep credentials)
		rm -f "$dst/settings.json" 2>/dev/null || true
		rm -f "$dst/settings.local.json" 2>/dev/null || true
		rm -f "$dst/config.toml" 2>/dev/null || true
		rm -f "$dst/config.json" 2>/dev/null || true
	fi

	# Copy root-level config files (some agents store credentials here)
	case "$agent" in
		claude)
			[ -f "$real_home/.claude.json" ] && cp "$real_home/.claude.json" "$temp_home/"
			;;
		gemini)
			[ -f "$real_home/.gemini.json" ] && cp "$real_home/.gemini.json" "$temp_home/"
			;;
	esac
}

# Get API key from system keychain for an agent
# Returns the API key or empty string if not found
get_agent_api_key() {
	local agent="$1"

	case "$agent" in
		claude)
			security find-generic-password -s "Claude Code" -w 2>/dev/null || true
			;;
	esac
}

# Get the environment variable name for an agent's API key
agent_api_key_env_var() {
	local agent="$1"

	case "$agent" in
		claude) echo "ANTHROPIC_API_KEY" ;;
		gemini) echo "GOOGLE_API_KEY" ;;
	esac
}

# ============================================
# Agent-specific Utilities
# ============================================

# Normalize agent name for use in variable names (replace hyphens with underscores)
normalize_agent_name() {
	local agent="$1"
	echo "$agent" | tr '-' '_'
}

extract_answer() {
	local text="$1"

	# Extract content between <answer> and </answer> tags
	# Match the LAST occurrence to avoid backticked examples
	# Returns empty string if tags are not found

	if echo "$text" | grep -q "<answer>"; then
		# Use perl for multiline matching, taking the last match to avoid backticked examples
		echo "$text" | perl -0777 -ne 'my @matches = /<answer>\s*(.*?)\s*<\/answer>/gs; print $matches[-1] if @matches'
	else
		echo ""
	fi
}


# ============================================
# Discovery
# ============================================

discover_agents() {
	agents=""
	for agent in $KNOWN_AGENTS; do
		if command -v "$agent" >/dev/null 2>&1; then
			agents="$agents $agent"
		fi
	done
	echo "$agents"
}

discover_tests() {
	tests=""
	for test_dir in "$TESTS_DIR"/*/; do
		test_name="$(basename "$test_dir")"
		case "$test_name" in
			_*|.*) continue ;;
			*) tests="$tests $test_name" ;;
		esac
	done
	echo "$tests"
}

# ============================================
# Test execution
# ============================================

run_debug() {
	local agent="$1"
	local test_name="$2"
	local mode="$3"
	local test_dir="$TESTS_DIR/$test_name"
	local sandbox_dir="$test_dir/sandbox"
	local global_dir="$test_dir/global"

	# Create isolated temp directory for test (project working directory)
	local temp_dir
	temp_dir=$(mktemp -d -t "universal-agents-test-XXXXXX")

	# Copy sandbox contents if it exists (sandbox is optional)
	if [ -d "$sandbox_dir" ]; then
		cp -R "$sandbox_dir/"* "$sandbox_dir/".* "$temp_dir/" 2>/dev/null || true
	fi

	# Create temp home directory for isolated global installs
	local temp_home
	temp_home=$(mktemp -d -t "universal-agents-home-XXXXXX")

	# Copy agent credentials from real HOME (for authentication)
	copy_agent_credentials "$agent" "$HOME" "$temp_home"

	# Copy global directory contents to temp home if it exists
	if [ -d "$global_dir" ]; then
		cp -R "$global_dir/"* "$global_dir/".* "$temp_home/" 2>/dev/null || true
	fi

	# Get API key from keychain before changing HOME
	local api_key
	api_key=$(get_agent_api_key "$agent")

	# Save original HOME and override it for test isolation
	local original_home="$HOME"
	export HOME="$temp_home"

	# Export API key if we got one from keychain
	local api_key_env_var
	api_key_env_var=$(agent_api_key_env_var "$agent")
	if [ -n "$api_key" ] && [ -n "$api_key_env_var" ]; then
		export "$api_key_env_var=$api_key"
	fi

	# Change to temp dir and run install (unless level is "none")
	cd "$temp_dir"
	if [ "$INSTALL_LEVEL" != "none" ]; then
		local install_flags="-y --level $INSTALL_LEVEL"
		case "$mode" in
			project)
				"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
				;;
			global)
				"$REPO_ROOT/install.sh" $install_flags --global > /dev/null 2>&1
				;;
			combined)
				"$REPO_ROOT/install.sh" $install_flags --global > /dev/null 2>&1
				"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
				;;
		esac
	fi

	# For global/combined mode with global skills, create the skills symlink
	if { [ "$mode" = "global" ] || [ "$mode" = "combined" ]; } && [ -d "$temp_home/.agents/skills" ]; then
		local agent_skills_target
		agent_skills_target=$(agent_skills_dir "$agent")
		if [ -n "$agent_skills_target" ] && [ ! -e "$temp_dir/$agent_skills_target" ]; then
			mkdir -p "$(dirname "$temp_dir/$agent_skills_target")"
			ln -s "$temp_home/.agents/skills" "$temp_dir/$agent_skills_target"
		fi
	fi

	# Show test info
	printf "$(c heading 'Test files:')\n"
	printf "  Prompt:   $(c path "$test_dir/prompt.md")\n"
	printf "  Expected: $(c path "$test_dir/expected.md")\n\n"

	printf "$(c heading 'Environment:')\n"
	printf "  Temp dir:  $(c path "$temp_dir")\n"
	printf "  Temp home: $(c path "$temp_home")\n"
	printf "  HOME:      $(c path "$HOME")\n\n"

	printf "$(c heading 'Prompt from test:')\n"
	cat "$test_dir/prompt.md" | sed 's/^/  /'
	printf "\n"

	printf "$(c heading 'Expected answer:')\n"
	cat "$test_dir/expected.md" | sed 's/^/  /'
	printf "\n"

	printf "$(c heading 'Starting interactive session...')\n\n"

	# Run agent interactively
	local interactive_cmd
	interactive_cmd=$(agent_interactive_command "$agent")
	eval "$interactive_cmd"
	local exit_code=$?

	# Restore HOME
	export HOME="$original_home"
	if [ -n "$api_key_env_var" ]; then
		unset "$api_key_env_var"
	fi

	# Cleanup
	printf "\n$(c heading 'Debug session ended.')\n"
	printf "Temp directories preserved for inspection:\n"
	printf "  Project: $(c path "$temp_dir")\n"
	printf "  Home:    $(c path "$temp_home")\n\n"

	return $exit_code
}

run_test() {
	local agent="$1"
	local test_name="$2"
	local mode="$3"
	local test_dir="$TESTS_DIR/$test_name"
	local sandbox_dir="$test_dir/sandbox"
	local global_dir="$test_dir/global"

	if [ ! -f "$test_dir/prompt.md" ]; then
		panic 2 "$test_dir/prompt.md not found"
	fi
	if [ ! -f "$test_dir/expected.md" ]; then
		panic 2 "$test_dir/expected.md not found"
	fi

	# Create isolated temp directory for test (project working directory)
	local temp_dir
	temp_dir=$(mktemp -d -t "universal-agents-test-XXXXXX")

	# Copy sandbox contents if it exists (sandbox is optional)
	if [ -d "$sandbox_dir" ]; then
		cp -R "$sandbox_dir/"* "$sandbox_dir/".* "$temp_dir/" 2>/dev/null || true
	fi

	# Create temp home directory for isolated global installs
	local temp_home
	temp_home=$(mktemp -d -t "universal-agents-home-XXXXXX")

	# Copy agent credentials from real HOME (for authentication)
	# This copies the agent's config dir but removes settings files
	copy_agent_credentials "$agent" "$HOME" "$temp_home"

	# Copy global directory contents to temp home if it exists
	# (these can override/add to what was copied from credentials)
	if [ -d "$global_dir" ]; then
		cp -R "$global_dir/"* "$global_dir/".* "$temp_home/" 2>/dev/null || true
	fi

	# Get API key from keychain before changing HOME
	# (keychain access may depend on original HOME)
	local api_key
	api_key=$(get_agent_api_key "$agent")

	# Save original HOME and override it for test isolation
	local original_home="$HOME"
	export HOME="$temp_home"

	# Export API key if we got one from keychain
	local api_key_env_var
	api_key_env_var=$(agent_api_key_env_var "$agent")
	if [ -n "$api_key" ] && [ -n "$api_key_env_var" ]; then
		export "$api_key_env_var=$api_key"
	fi

	# Change to temp dir and run install (unless level is "none")
	cd "$temp_dir"
	if [ "$INSTALL_LEVEL" != "none" ]; then
		local install_flags="-y --level $INSTALL_LEVEL"
		case "$mode" in
			project)
				"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
				;;
			global)
				"$REPO_ROOT/install.sh" $install_flags --global > /dev/null 2>&1
				;;
			combined)
				# Run both: global first, then project overlay
				"$REPO_ROOT/install.sh" $install_flags --global > /dev/null 2>&1
				"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
				;;
		esac
	fi

	# For global/combined mode with global skills, create the skills symlink
	# (normally the hook does this at runtime, but skills discovery happens first)
	if { [ "$mode" = "global" ] || [ "$mode" = "combined" ]; } && [ -d "$temp_home/.agents/skills" ]; then
		local agent_skills_target
		agent_skills_target=$(agent_skills_dir "$agent")
		if [ -n "$agent_skills_target" ] && [ ! -e "$temp_dir/$agent_skills_target" ]; then
			mkdir -p "$(dirname "$temp_dir/$agent_skills_target")"
			ln -s "$temp_home/.agents/skills" "$temp_dir/$agent_skills_target"
		fi
	fi

	prompt=$(cat "$test_dir/prompt.md")
	expected=$(cat "$test_dir/expected.md")
	expected=$(trim "$expected")

	# Get the command to run
	TEST_COMMAND=$(agent_command "$agent" "$prompt")

	# Run agent from within temp directory
	if [ "$VERBOSE" -eq 1 ]; then
		# In verbose mode, clear the spinner line and show command and stream output
		printf "\r\033[K"
		printf "  $(c test $test_name)\n"
		printf "    $(c heading Temp dir:)\n"
		print_indented 6 "$temp_dir"
		printf "    $(c heading Temp home:)\n"
		print_indented 6 "$temp_home"
		printf "    $(c heading Command:)\n"
		print_indented 6 "$TEST_COMMAND"
		printf "    $(c heading Full output:)\n"

		output=$(eval "$TEST_COMMAND" 2>/dev/null | sed 's/^/      /' | tee /dev/stderr)
	else
		# In normal mode, just capture output
		output=$(eval "$TEST_COMMAND" 2>/dev/null)
	fi

	output=$(trim "$output")

	# Extract answer from <answer> tags (required)
	local extracted_answer=$(extract_answer "$output")
	extracted_answer=$(trim "$extracted_answer")

	# Restore HOME and unset API key
	export HOME="$original_home"
	if [ -n "$api_key_env_var" ]; then
		unset "$api_key_env_var"
	fi

	# Set these for display_result
	TEST_EXPECTED="$expected"
	TEST_GOT="$output"
	TEST_EXTRACTED="$extracted_answer"
	TEST_TEMP_DIR="$temp_dir"
	TEST_TEMP_HOME="$temp_home"

	# Check if answer tags were found
	if [ -z "$extracted_answer" ]; then
		TEST_EXTRACTED="<missing answer tags>"
		return 1
	fi

	local test_result=0
	if [ "$extracted_answer" = "$expected" ]; then
		# Clean up temp directories on success
		rm -rf "$temp_dir"
		rm -rf "$temp_home"
		test_result=0
	else
		# Keep temp directories on failure for debugging
		test_result=1
	fi

	return $test_result
}

display_result() {
	local test_name="$1"
	local result="$2"
	local mode="$3"

	# Add mode indicator to test name
	local display_name="$test_name"
	if [ "$SHOW_MODE" -eq 1 ]; then
		display_name="$test_name [$(c option "$mode")]"
	fi

	if [ "$result" -eq 0 ]; then
		if [ "$VERBOSE" -eq 1 ]; then
			# In verbose mode, just show the result and details
			printf "    $(c heading Extracted:)\n"
			printf "      %s\n" "$TEST_EXTRACTED"
			printf "    $(c heading Expected:)\n"
			printf "      %s\n" "$TEST_EXPECTED"
			printf "    $(c success Result:) $(c success PASS)\n"
		else
			# In normal mode, clear spinner and show checkmark
			print_test_pass "$display_name"
		fi
	else
		if [ "$VERBOSE" -eq 1 ]; then
			# In verbose mode, command and full output already shown during streaming
			printf "    $(c heading Extracted:)\n"
			printf "      %s\n" "$TEST_EXTRACTED"
			printf "    $(c heading Expected:)\n"
			printf "      %s\n" "$TEST_EXPECTED"
			printf "    $(c error Result:) $(c error FAIL)\n"
			printf "    $(c heading Debug:) Temp directories preserved at:\n"
			printf "      Project: %s\n" "$TEST_TEMP_DIR"
			printf "      Home:    %s\n" "$TEST_TEMP_HOME"
		else
			# In normal mode, show everything for failures
			print_test_fail "$display_name"
			printf "    $(c heading Temp dir:)\n"
			print_indented 6 "$TEST_TEMP_DIR"
			printf "    $(c heading Temp home:)\n"
			print_indented 6 "$TEST_TEMP_HOME"
			printf "    $(c heading Command:)\n"
			print_indented 6 "$TEST_COMMAND"
			printf "    $(c heading Full output:)\n"
			print_indented 6 "$TEST_GOT"
			printf "    $(c heading Extracted:)\n"
			print_indented 6 "$TEST_EXTRACTED"
			printf "    $(c heading Expected:)\n"
			print_indented 6 "$TEST_EXPECTED"
		fi
	fi
}

# ============================================
# Usage and help
# ============================================

usage() {
	printf "$(c heading Usage:) $(c command test-agents.sh) [$(c flag OPTIONS)] [$(c agent AGENT)…] [$(c test TEST…)]"
}

show_help() {
	printf "\n"
	printf "$(usage)\n\n"
	printf "Test runner for AGENTS.md polyfill configuration.\n\n"

	printf "$(c heading Arguments:)\n"
	printf "  $(c agent AGENT)    Agent(s) to test: $(c_list agent $KNOWN_AGENTS), $(c agent all) (default: $(c agent all))\n"
	printf "  $(c test TEST)     Test(s) to run (default: $(c test all))\n\n"

	printf "Arguments are auto-detected as agents or tests:\n"
	printf "  - Agent names come first, test names come after\n"
	printf "  - Multiple agents and/or tests can be specified\n"
	printf "  - Use $(c agent all) for all agents or $(c test all) for all tests\n\n"

	printf "$(c heading Options:)\n"
	printf "  $(c flag -h), $(c flag --help)        Show this help message\n"
	printf "  $(c flag -v), $(c flag --verbose)     Show full output for all tests\n"
	printf "  $(c flag -j), $(c flag --jobs) $(c option N)     Run N tests in parallel (default: $(c option 4))\n"
	printf "  $(c flag --debug) $(c option MODE)      Run one test interactively for debugging\n"
	printf "  $(c flag --mode) $(c option MODE)       Installation mode (default: $(c option all))\n"
	printf "                      $(c option project):  Project-level install only\n"
	printf "                      $(c option global):   Global install only\n"
	printf "                      $(c option combined): Global + project install (layered)\n"
	printf "                      $(c option all):      All three modes\n"
	printf "  $(c flag --install) $(c option LEVEL)   Installation level (default: $(c option full))\n"
	printf "                      $(c option none):     Skip install (test native agent support)\n"
	printf "                      $(c option config):   Config only (no polyfill hooks)\n"
	printf "                      $(c option full):     Complete installation with hooks\n\n"

	printf "$(c heading Test Naming:)\n"
	printf "  Tests run in all modes by default. Use prefixes to restrict:\n"
	printf "    $(c test project-*)   Only runs in project mode\n"
	printf "    $(c test global-*)    Only runs in global mode\n"
	printf "    $(c test combined-*)  Only runs in combined mode\n\n"

	printf "$(c heading Examples:)\n"
	printf "  $(c command test-agents.sh)                                       # All tests, 4 parallel (default)\n"
	printf "  $(c command test-agents.sh) $(c flag -j) $(c option 1)                                  # Sequential execution\n"
	printf "  $(c command test-agents.sh) $(c flag -j) $(c option 8)                                  # Run 8 tests at once\n"
	printf "  $(c command test-agents.sh) $(c agent claude)                                # All tests on Claude\n"
	printf "  $(c command test-agents.sh) $(c agent claude) $(c test basic-support)                  # Specific test on Claude\n"
	printf "  $(c command test-agents.sh) $(c flag --mode) $(c option global)                         # All tests in global mode only\n"
	printf "  $(c command test-agents.sh) $(c flag --debug) $(c option global) $(c agent claude) $(c test global-skills)   # Debug interactively\n\n"

	printf "$(c heading Agents:)\n"
	for agent in $KNOWN_AGENTS; do
		if command -v "$agent" >/dev/null 2>&1; then
			printf "  $(c agent %-14s) $(c success ✓ available)\n" "$agent"
		else
			printf "  $(c agent %-14s) $(c error ✗ not found)\n" "$agent"
		fi
	done

	printf "\n$(c heading Tests:)\n"
	for test in $(discover_tests); do
		printf "  $(c test "$test")\n"
	done

	printf "\n$(c heading Exit codes:)\n"
	printf "  0    All tests passed\n"
	printf "  1    One or more tests failed\n"
	printf "  2    Invalid arguments or configuration error\n"
	printf "\n"
}

# ============================================
# Parallel Execution
# ============================================

# Global state for parallel execution
RESULTS_DIR=""
JOB_PIDS=""
RUNNING_TESTS=""
RUNNING_BLOCK_LINES=0
COMPLETED_COUNT=0
COL_WIDTH_TEST=0
COL_WIDTH_MODE=0
COL_WIDTH_AGENT=0
SPINNER_FRAMES="⣾⣽⣻⢿⡿⣟⣯⣷"
SPINNER_INDEX=0
SPINNER="⣾"
SPINNER_INTERVAL_MS=150
SPINNER_LAST_MS=0
TOTAL_TESTS=0

# Initialize the job pool and results directory
init_job_pool() {
	RESULTS_DIR=$(mktemp -d -t "test-results-XXXXXX")
	JOB_PIDS=""
	RUNNING_TESTS=""
	RUNNING_BLOCK_LINES=0
	COMPLETED_COUNT=0
}

# Clean up the job pool
cleanup_job_pool() {
	[ -n "$RESULTS_DIR" ] && rm -rf "$RESULTS_DIR"
	RESULTS_DIR=""
}

# Get current time in milliseconds (portable)
get_time_ms() {
	if command -v perl >/dev/null 2>&1; then
		perl -MTime::HiRes=time -e 'printf "%d", time * 1000' 2>/dev/null && return
	fi
	# Fallback: seconds * 1000 (less precise but works everywhere)
	echo $(($(date +%s) * 1000))
}

# Advance spinner if enough time has passed, set SPINNER to current frame
# Returns 0 if spinner changed, 1 if not
advance_spinner() {
	local now_ms=$(get_time_ms)
	local elapsed=$((now_ms - SPINNER_LAST_MS))

	if [ "$elapsed" -ge "$SPINNER_INTERVAL_MS" ]; then
		SPINNER_LAST_MS=$now_ms
		case $SPINNER_INDEX in
			0) SPINNER="⣾" ;;
			1) SPINNER="⣽" ;;
			2) SPINNER="⣻" ;;
			3) SPINNER="⢿" ;;
			4) SPINNER="⡿" ;;
			5) SPINNER="⣟" ;;
			6) SPINNER="⣯" ;;
			7) SPINNER="⣷" ;;
		esac
		SPINNER_INDEX=$(( (SPINNER_INDEX + 1) % 8 ))
		return 0
	fi
	return 1
}

# Count currently running jobs
count_running_jobs() {
	local count=0
	local new_pids=""

	for pid in $JOB_PIDS; do
		if kill -0 "$pid" 2>/dev/null; then
			count=$((count + 1))
			new_pids="$new_pids $pid"
		fi
	done

	JOB_PIDS="$new_pids"
	echo "$count"
}

# Wait until a job slot is available
wait_for_slot() {
	while [ "$(count_running_jobs)" -ge "$PARALLEL_JOBS" ]; do
		sleep 0.05
		# Only redraw if spinner changed (to reduce flicker)
		if advance_spinner; then
			print_running_block "$TOTAL_TESTS" "$COMPLETED_COUNT"
		fi
		poll_completed_tests "$TOTAL_TESTS"
	done
}

# Add a test to the running list
add_running_test() {
	local test_id="$1"
	RUNNING_TESTS="$RUNNING_TESTS $test_id"
}

# Remove a test from the running list
remove_running_test() {
	local test_id="$1"
	local new_list=""

	for t in $RUNNING_TESTS; do
		if [ "$t" != "$test_id" ]; then
			new_list="$new_list $t"
		fi
	done

	RUNNING_TESTS="$new_list"
}

# Clear the running block from terminal
clear_running_block() {
	if [ "$RUNNING_BLOCK_LINES" -gt 0 ]; then
		local i=0
		while [ "$i" -lt "$RUNNING_BLOCK_LINES" ]; do
			printf "\033[A\033[K"
			i=$((i + 1))
		done
		RUNNING_BLOCK_LINES=0
	fi
}

# Print the running block (sticky footer)
# Uses cursor positioning to overwrite in place, minimizing flicker
print_running_block() {
	local total_tests="$1"
	local completed="$2"
	local running_count=0

	# Count running tests
	for t in $RUNNING_TESTS; do
		running_count=$((running_count + 1))
	done

	if [ "$running_count" -eq 0 ]; then
		RUNNING_BLOCK_LINES=0
		return
	fi

	local new_lines=$((3 + running_count))

	# Build all lines, each with \r to start at column 0 and \033[K to clear to end
	local output=""

	# If we have existing content, move cursor up to overwrite
	if [ "$RUNNING_BLOCK_LINES" -gt 0 ]; then
		output="\033[${RUNNING_BLOCK_LINES}A"
	fi

	# Blank line + progress + header
	output="${output}\r\033[K
\r$(c heading "$completed/$total_tests") complete\033[K
\r$(c heading "Running:")\033[K"

	# Each running test
	for test_id in $RUNNING_TESTS; do
		local agent=$(echo "$test_id" | cut -d: -f1)
		local test_name=$(echo "$test_id" | cut -d: -f2)
		local mode=$(echo "$test_id" | cut -d: -f3)

		local padded_test=$(printf "%-${COL_WIDTH_TEST}s" "$test_name")
		local padded_mode=$(printf "%-${COL_WIDTH_MODE}s" "$mode")
		local padded_agent=$(printf "%-${COL_WIDTH_AGENT}s" "$agent")

		output="${output}
\r${SPINNER} $(c test "$padded_test")  $(c option "$padded_mode")  $(c agent "$padded_agent")\033[K"
	done

	# If new block is smaller, clear extra lines
	if [ "$RUNNING_BLOCK_LINES" -gt "$new_lines" ]; then
		local extra=$((RUNNING_BLOCK_LINES - new_lines))
		local i=0
		while [ "$i" -lt "$extra" ]; do
			output="${output}
\r\033[K"
			i=$((i + 1))
		done
		# Move cursor back up to end of actual content
		output="${output}\033[${extra}A"
	fi

	# Single write
	printf "%b\n" "$output"
	RUNNING_BLOCK_LINES=$new_lines
}

# Run a single test and write results to files (for parallel mode)
run_test_parallel() {
	local agent="$1"
	local test_name="$2"
	local mode="$3"
	local test_id="$4"
	local result_base="$RESULTS_DIR/$test_id"
	local test_dir="$TESTS_DIR/$test_name"
	local sandbox_dir="$test_dir/sandbox"
	local global_dir="$test_dir/global"

	# Create isolated temp directory for test (project working directory)
	local temp_dir
	temp_dir=$(mktemp -d -t "universal-agents-test-XXXXXX")

	# Copy sandbox contents if it exists (sandbox is optional)
	if [ -d "$sandbox_dir" ]; then
		cp -R "$sandbox_dir/"* "$sandbox_dir/".* "$temp_dir/" 2>/dev/null || true
	fi

	# Create temp home directory for isolated global installs
	local temp_home
	temp_home=$(mktemp -d -t "universal-agents-home-XXXXXX")

	# Copy agent credentials from real HOME (for authentication)
	copy_agent_credentials "$agent" "$REAL_HOME" "$temp_home"

	# Copy global directory contents to temp home if it exists
	if [ -d "$global_dir" ]; then
		cp -R "$global_dir/"* "$global_dir/".* "$temp_home/" 2>/dev/null || true
	fi

	# Get API key from keychain before changing HOME
	local api_key
	api_key=$(get_agent_api_key "$agent")

	# Override HOME for test isolation
	export HOME="$temp_home"

	# Export API key if we got one from keychain
	local api_key_env_var
	api_key_env_var=$(agent_api_key_env_var "$agent")
	if [ -n "$api_key" ] && [ -n "$api_key_env_var" ]; then
		export "$api_key_env_var=$api_key"
	fi

	# Change to temp dir and run install (unless level is "none")
	cd "$temp_dir"
	if [ "$INSTALL_LEVEL" != "none" ]; then
		local install_flags="-y --level $INSTALL_LEVEL"
		case "$mode" in
			project)
				"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
				;;
			global)
				"$REPO_ROOT/install.sh" $install_flags --global > /dev/null 2>&1
				;;
			combined)
				"$REPO_ROOT/install.sh" $install_flags --global > /dev/null 2>&1
				"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
				;;
		esac
	fi

	# For global/combined mode with global skills, create the skills symlink
	if { [ "$mode" = "global" ] || [ "$mode" = "combined" ]; } && [ -d "$temp_home/.agents/skills" ]; then
		local agent_skills_target
		agent_skills_target=$(agent_skills_dir "$agent")
		if [ -n "$agent_skills_target" ] && [ ! -e "$temp_dir/$agent_skills_target" ]; then
			mkdir -p "$(dirname "$temp_dir/$agent_skills_target")"
			ln -s "$temp_home/.agents/skills" "$temp_dir/$agent_skills_target"
		fi
	fi

	local prompt=$(cat "$test_dir/prompt.md")
	local expected=$(cat "$test_dir/expected.md")
	expected=$(trim "$expected")

	# Get the command to run
	local test_command=$(agent_command "$agent" "$prompt")

	# Run agent from within temp directory
	local output
	output=$(eval "$test_command" 2>/dev/null) || true
	output=$(trim "$output")

	# Extract answer from <answer> tags (required)
	local extracted_answer=$(extract_answer "$output")
	extracted_answer=$(trim "$extracted_answer")

	# Write results to files
	echo "$expected" > "$result_base.expected"
	echo "$output" > "$result_base.output"
	echo "$extracted_answer" > "$result_base.extracted"
	echo "$temp_dir" > "$result_base.temp_dir"
	echo "$temp_home" > "$result_base.temp_home"
	echo "$test_command" > "$result_base.command"

	# Determine result
	if [ -z "$extracted_answer" ]; then
		echo "fail" > "$result_base.status"
		echo "missing_tags" > "$result_base.fail_reason"
	elif [ "$extracted_answer" = "$expected" ]; then
		echo "pass" > "$result_base.status"
		# Clean up temp directories on success
		rm -rf "$temp_dir"
		rm -rf "$temp_home"
	else
		echo "fail" > "$result_base.status"
		echo "mismatch" > "$result_base.fail_reason"
	fi
}

# Start a test as a background job
start_test_job() {
	local agent="$1"
	local test_name="$2"
	local mode="$3"
	local test_id="${agent}:${test_name}:${mode}"

	add_running_test "$test_id"

	(
		run_test_parallel "$agent" "$test_name" "$mode" "$test_id"
	) &

	JOB_PIDS="$JOB_PIDS $!"
}

# Check for and display completed tests
# Updates global COMPLETED_COUNT
poll_completed_tests() {
	local total_tests="$1"

	for test_id in $RUNNING_TESTS; do
		local result_base="$RESULTS_DIR/$test_id"

		if [ -f "$result_base.status" ]; then
			# Test completed - clear running block and display result
			clear_running_block

			local status=$(cat "$result_base.status")
			local agent=$(echo "$test_id" | cut -d: -f1)
			local test_name=$(echo "$test_id" | cut -d: -f2)
			local mode=$(echo "$test_id" | cut -d: -f3)

			# Pad strings for alignment (pad before colorizing)
			local padded_test=$(printf "%-${COL_WIDTH_TEST}s" "$test_name")
			local padded_mode=$(printf "%-${COL_WIDTH_MODE}s" "$mode")
			local padded_agent=$(printf "%-${COL_WIDTH_AGENT}s" "$agent")

			if [ "$status" = "pass" ]; then
				printf "%b %b  %b  %b\n" "$(c success ✓)" "$(c test "$padded_test")" "$(c option "$padded_mode")" "$(c agent "$padded_agent")"
			else
				printf "%b %b  %b  %b\n" "$(c error ✗)" "$(c test "$padded_test")" "$(c option "$padded_mode")" "$(c agent "$padded_agent")"
			fi

			# Show details (always for failures, or when verbose)
			if [ "$status" != "pass" ] || [ "$VERBOSE" -eq 1 ]; then
				local extracted=$(cat "$result_base.extracted" 2>/dev/null || echo "<missing>")
				local expected=$(cat "$result_base.expected")
				local temp_dir=$(cat "$result_base.temp_dir")
				local temp_home=$(cat "$result_base.temp_home")
				local command=$(cat "$result_base.command" 2>/dev/null || echo "<unknown>")
				local full_output=$(cat "$result_base.output" 2>/dev/null || echo "<no output>")

				if [ -z "$extracted" ]; then
					extracted="<missing answer tags>"
				fi

				printf "    %b\n" "$(c heading "Temp dir:")"
				print_indented 6 "$temp_dir"
				printf "    %b\n" "$(c heading "Temp home:")"
				print_indented 6 "$temp_home"
				printf "    %b\n" "$(c heading "Command:")"
				print_indented 6 "$command"
				printf "    %b\n" "$(c heading "Full output:")"
				print_indented 6 "$full_output"
				printf "    %b\n" "$(c heading "Extracted:")"
				print_indented 6 "$extracted"
				printf "    %b\n" "$(c heading "Expected:")"
				print_indented 6 "$expected"
			fi

			remove_running_test "$test_id"
			COMPLETED_COUNT=$((COMPLETED_COUNT + 1))

			# Update per-agent stats
			local agent_var=$(normalize_agent_name "$agent")
			if [ "$status" = "pass" ]; then
				eval "agent_passed_$agent_var=\$((agent_passed_$agent_var + 1))"
			fi
			eval "agent_total_$agent_var=\$((agent_total_$agent_var + 1))"

			# Print updated running block
			print_running_block "$total_tests" "$COMPLETED_COUNT"
		fi
	done
}

# ============================================
# Main
# ============================================

main() {
	# Parse arguments
	local verbose=0
	local debug_mode=0
	local debug_mode_arg=""
	local mode_arg="all"
	local install_arg="full"
	local parallel_jobs=4
	local agent_args=""
	local test_args=""
	local parsing_mode="auto"  # auto, agents, tests

	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				show_help
				exit 0
				;;
			-v|--verbose)
				verbose=1
				shift
				;;
			-j|--jobs)
				case "$2" in
					''|-*)
						panic 2 show_usage "$(c flag "$1") requires a number"
						;;
					*[!0-9]*)
						panic 2 show_usage "Invalid job count: $(c option "'$2'")"
						;;
					*)
						parallel_jobs="$2"
						shift 2
						;;
				esac
				;;
			--debug)
				debug_mode=1
				debug_mode_arg="$2"
				case "$debug_mode_arg" in
					project|global|combined)
						shift 2
						;;
					*)
						panic 2 show_usage "$(c flag --debug) requires a mode: $(c_list option project global combined)"
						;;
				esac
				;;
			--mode)
				mode_arg="$2"
				case "$mode_arg" in
					project|global|combined|all)
						shift 2
						;;
					*)
						panic 2 show_usage "Invalid mode: $(c option "'$mode_arg'"). Valid modes: $(c_list option project global combined all)"
						;;
				esac
				;;
			--install)
				install_arg="$2"
				case "$install_arg" in
					none|config|full)
						shift 2
						;;
					*)
						panic 2 show_usage "Invalid install level: $(c option "'$install_arg'"). Valid levels: $(c_list option none config full)"
						;;
				esac
				;;
			*)
				# Collect positional arguments
				if [ "$parsing_mode" = "auto" ] || [ "$parsing_mode" = "agents" ]; then
					agent_args="$agent_args $1"
				elif [ "$parsing_mode" = "tests" ]; then
					test_args="$test_args $1"
				fi
				shift
				;;
		esac
	done

	# Export for use in run_test and subshells
	VERBOSE=$verbose
	export INSTALL_LEVEL=$install_arg
	export PARALLEL_JOBS=$parallel_jobs
	export REAL_HOME="$HOME"


	# Determine modes to run
	local modes_to_run
	if [ "$mode_arg" = "all" ]; then
		modes_to_run="project global combined"
	else
		modes_to_run="$mode_arg"
	fi

	# Show mode in output if testing multiple modes
	local mode_count=0
	for mode in $modes_to_run; do
		mode_count=$((mode_count + 1))
	done
	if [ $mode_count -gt 1 ]; then
		SHOW_MODE=1
	else
		SHOW_MODE=0
	fi

	# Discover available agents and tests
	local available_agents=$(discover_agents)
	local available_tests=$(discover_tests)

	if [ -z "$available_agents" ]; then
		panic 2 <<-end_panic
			No agents found
			Available agents: $(c_list agent $KNOWN_AGENTS)
		end_panic
	fi

	if [ -z "$available_tests" ]; then
		panic 2 "No tests found"
	fi

	# Parse collected arguments and separate agents from tests
	local agents=""
	local tests=""
	local switched_to_tests=0

	for arg in $agent_args; do
		# Check if it's "all"
		if [ "$arg" = "all" ]; then
			if [ $switched_to_tests -eq 0 ]; then
				agents="$agents $arg"
			else
				tests="$tests $arg"
			fi
			continue
		fi

		# Check if it's an available agent
		local is_agent=0
		for agent in $available_agents; do
			if [ "$agent" = "$arg" ]; then
				is_agent=1
				break
			fi
		done

		# Check if it's a known but unavailable agent
		local is_known_agent=0
		for agent in $KNOWN_AGENTS; do
			if [ "$agent" = "$arg" ]; then
				is_known_agent=1
				break
			fi
		done

		# Check if it's a test
		local is_test=0
		for test in $available_tests; do
			if [ "$test" = "$arg" ]; then
				is_test=1
				break
			fi
		done

		# Determine where to put it
		if [ $is_agent -eq 1 ] && [ $is_test -eq 0 ]; then
			if [ $switched_to_tests -eq 1 ]; then
				panic 2 show_usage "Agent $(c agent "'$arg'") specified after test names"
			fi
			agents="$agents $arg"
		elif [ $is_test -eq 1 ] && [ $is_agent -eq 0 ]; then
			switched_to_tests=1
			tests="$tests $arg"
		elif [ $is_test -eq 1 ] && [ $is_agent -eq 1 ]; then
			# Ambiguous - prefer agent if we haven't switched to tests yet
			if [ $switched_to_tests -eq 0 ]; then
				agents="$agents $arg"
			else
				tests="$tests $arg"
			fi
		elif [ $is_known_agent -eq 1 ]; then
			panic 2 show_usage "Agent $(c agent "'$arg'") not found on PATH"
		else
			panic 2 show_usage "Unknown argument: $(c agent "'$arg'")"
		fi
	done

	# Trim leading/trailing spaces
	agents=$(trim "$agents")
	tests=$(trim "$tests")

	# Determine agents to run
	local agents_to_run
	if [ -z "$agents" ] || echo "$agents" | grep -q "\\ball\\b"; then
		agents_to_run="$available_agents"
	else
		agents_to_run="$agents"
	fi

	# Determine tests to run
	local tests_to_run
	if [ -z "$tests" ] || echo "$tests" | grep -q "\\ball\\b"; then
		tests_to_run="$available_tests"
	else
		tests_to_run="$tests"
	fi

	# Count agents and tests
	local agent_count=0
	for agent in $agents_to_run; do
		agent_count=$((agent_count + 1))
	done

	local test_count=0
	for test in $tests_to_run; do
		test_count=$((test_count + 1))
	done

	# Debug mode validation and execution
	if [ "$debug_mode" -eq 1 ]; then
		# Validate requirements for debug mode
		if [ "$agent_count" -ne 1 ]; then
			panic 2 show_usage "Debug mode requires exactly one agent"
		fi
		if [ "$test_count" -ne 1 ]; then
			panic 2 show_usage "Debug mode requires exactly one test"
		fi

		local agent="$agents_to_run"
		local test_name="$tests_to_run"
		local mode="$debug_mode_arg"

		printf "\n$(c heading '=== Debug Mode ===')\n"
		printf "Agent: $(c agent "$agent")\n"
		printf "Test:  $(c test "$test_name")\n"
		printf "Mode:  $(c option "$mode")\n\n"

		run_debug "$agent" "$test_name" "$mode"
		exit $?
	fi

	# Run tests
	local total_passed=0
	local total_failed=0

	# Initialize per-agent counters
	for agent in $agents_to_run; do
		local agent_var=$(normalize_agent_name "$agent")
		eval "agent_passed_$agent_var=0"
		eval "agent_total_$agent_var=0"
	done

	# Parallel execution mode (works for any job count including 1)
	init_job_pool

		# Count total tests and calculate column widths
		local total_tests=0
		COL_WIDTH_TEST=0
		COL_WIDTH_MODE=0
		COL_WIDTH_AGENT=0
		for agent in $agents_to_run; do
			local agent_len=${#agent}
			[ "$agent_len" -gt "$COL_WIDTH_AGENT" ] && COL_WIDTH_AGENT=$agent_len
			for test_name in $tests_to_run; do
				local test_len=${#test_name}
				[ "$test_len" -gt "$COL_WIDTH_TEST" ] && COL_WIDTH_TEST=$test_len
				for mode in $modes_to_run; do
					case "$test_name" in
						global-*)   [ "$mode" != "global" ] && continue ;;
						project-*)  [ "$mode" != "project" ] && continue ;;
						combined-*) [ "$mode" != "combined" ] && continue ;;
					esac
					local mode_len=${#mode}
					[ "$mode_len" -gt "$COL_WIDTH_MODE" ] && COL_WIDTH_MODE=$mode_len
					total_tests=$((total_tests + 1))
				done
			done
		done

		# Set global for wait_for_slot to use
		TOTAL_TESTS=$total_tests

		printf "\nRunning %b tests with %b parallel jobs…\n\n" "$(c heading "$total_tests")" "$(c heading "$PARALLEL_JOBS")"

		# Print column headers
		local header_test=$(printf "%-${COL_WIDTH_TEST}s" "TEST")
		local header_mode=$(printf "%-${COL_WIDTH_MODE}s" "MODE")
		local header_agent=$(printf "%-${COL_WIDTH_AGENT}s" "AGENT")
		printf "  %b  %b  %b\n" "$(c heading "$header_test")" "$(c heading "$header_mode")" "$(c heading "$header_agent")"

		# Start all tests
		for agent in $agents_to_run; do
			for test_name in $tests_to_run; do
				for mode in $modes_to_run; do
					case "$test_name" in
						global-*)   [ "$mode" != "global" ] && continue ;;
						project-*)  [ "$mode" != "project" ] && continue ;;
						combined-*) [ "$mode" != "combined" ] && continue ;;
					esac

					wait_for_slot
					start_test_job "$agent" "$test_name" "$mode"

					# Update running block
					clear_running_block
					print_running_block "$total_tests" "$COMPLETED_COUNT"

					# Poll for completed tests
					poll_completed_tests "$total_tests"
				done
			done
		done

		# Wait for remaining tests to complete
		while [ "$(count_running_jobs)" -gt 0 ]; do
			sleep 0.05
			# Only redraw if spinner changed (to reduce flicker)
			if advance_spinner; then
				print_running_block "$total_tests" "$COMPLETED_COUNT"
			fi
			poll_completed_tests "$total_tests"
		done

		# Final poll to catch any remaining completions
		clear_running_block
		poll_completed_tests "$total_tests"

		# Count results from result files
		for status_file in "$RESULTS_DIR"/*.status; do
			[ -f "$status_file" ] || continue
			local status=$(cat "$status_file")
			if [ "$status" = "pass" ]; then
				total_passed=$((total_passed + 1))
			else
				total_failed=$((total_failed + 1))
			fi
		done

		cleanup_job_pool

	# Display summary
	local total=$((total_passed + total_failed))

	printf "\n"
	if [ "$total_passed" -eq "$total" ]; then
		printf "$(c success %d/%d passed)\n" "$total_passed" "$total"
	else
		printf "$(c error %d/%d passed)\n" "$total_passed" "$total"
	fi

	if [ "$agent_count" -gt 1 ]; then
		for agent in $agents_to_run; do
			local agent_var=$(normalize_agent_name "$agent")
			eval "passed=\$agent_passed_$agent_var"
			eval "total_tests=\$agent_total_$agent_var"
			if [ "$passed" -eq "$total_tests" ]; then
				printf "$(c agent $agent): $(c success $passed/$total_tests)\n"
			else
				printf "$(c agent $agent): $(c error $passed/$total_tests)\n"
			fi
		done
	fi

	# Exit with appropriate code
	if [ "$total_failed" -gt 0 ]; then
		exit 1
	else
		exit 0
	fi
}

main "$@"
