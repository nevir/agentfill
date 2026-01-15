#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$SCRIPT_DIR/agents"

cd "$REPO_ROOT"

KNOWN_AGENTS="claude cursor-agent gemini"

# Load agent detection (auto-configures VERBOSE and DISABLE_COLORS)
. "$SCRIPT_DIR/_common/agent-detection.sh"

# Load common libraries (after setting DISABLE_COLORS)
. "$SCRIPT_DIR/_common/colors.sh"
. "$SCRIPT_DIR/_common/utils.sh"
. "$SCRIPT_DIR/_common/output.sh"

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

run_test() {
	local agent="$1"
	local test_name="$2"
	local mode="$3"
	local test_dir="$TESTS_DIR/$test_name"
	local sandbox_dir="$test_dir/sandbox"

	if [ ! -f "$test_dir/prompt.md" ]; then
		panic 2 "$test_dir/prompt.md not found"
	fi
	if [ ! -f "$test_dir/expected.md" ]; then
		panic 2 "$test_dir/expected.md not found"
	fi

	# Create isolated temp directory for test
	if [ ! -d "$sandbox_dir" ]; then
		panic 2 "$sandbox_dir not found"
	fi

	# Create temp dir and copy sandbox into it
	local temp_dir
	temp_dir=$(mktemp -d -t "universal-agents-test-XXXXXX")
	cp -R "$sandbox_dir/"* "$sandbox_dir/".* "$temp_dir/" 2>/dev/null || true

	# For global mode, backup existing settings before install
	local claude_backup=""
	local gemini_backup=""
	local polyfill_backup=""
	if [ "$mode" = "global" ]; then
		[ -f "$HOME/.claude/settings.json" ] && claude_backup=$(cat "$HOME/.claude/settings.json")
		[ -f "$HOME/.gemini/settings.json" ] && gemini_backup=$(cat "$HOME/.gemini/settings.json")
		[ -f "$HOME/.agents/polyfills/claude/agentsmd.sh" ] && polyfill_backup=$(cat "$HOME/.agents/polyfills/claude/agentsmd.sh")
	fi

	# Change to temp dir and run install (unless level is "none")
	cd "$temp_dir"
	if [ "$INSTALL_LEVEL" != "none" ]; then
		local install_flags="-y --level $INSTALL_LEVEL"
		[ "$mode" = "global" ] && install_flags="$install_flags --global"
		"$REPO_ROOT/install.sh" $install_flags > /dev/null 2>&1
	fi

	prompt=$(cat "$test_dir/prompt.md")
	expected=$(cat "$test_dir/expected.md")
	expected=$(trim "$expected")

	# Determine the command to run
	case "$agent" in
		claude)       TEST_COMMAND="echo \"$prompt\" | claude --print" ;;
		cursor-agent) TEST_COMMAND="echo \"$prompt\" | cursor-agent --print" ;;
		gemini)       TEST_COMMAND="echo \"$prompt\" | gemini" ;;
		*)            TEST_COMMAND="echo \"$prompt\" | $agent" ;;
	esac

	# Run agent from within temp directory
	if [ "$VERBOSE" -eq 1 ]; then
		# In verbose mode, clear the spinner line and show command and stream output
		printf "\r\033[K"
		printf "  $(c test $test_name)\n"
		printf "    $(c heading Temp dir:)\n"
		print_indented 6 "$temp_dir"
		printf "    $(c heading Command:)\n"
		print_indented 6 "$TEST_COMMAND"
		printf "    $(c heading Full output:)\n"

		case "$agent" in
			claude) output=$(echo "$prompt" | claude --print 2>/dev/null | sed 's/^/      /' | tee /dev/stderr) ;;
			gemini) output=$(echo "$prompt" | gemini 2>/dev/null | sed 's/^/      /' | tee /dev/stderr) ;;
			*)      output=$(echo "$prompt" | "$agent" 2>/dev/null | sed 's/^/      /' | tee /dev/stderr) ;;
		esac
	else
		# In normal mode, just capture output
		case "$agent" in
			claude) output=$(echo "$prompt" | claude --print 2>/dev/null) ;;
			gemini) output=$(echo "$prompt" | gemini 2>/dev/null) ;;
			*)      output=$(echo "$prompt" | "$agent" 2>/dev/null) ;;
		esac
	fi

	output=$(trim "$output")

	# Extract answer from <answer> tags (required)
	local extracted_answer=$(extract_answer "$output")
	extracted_answer=$(trim "$extracted_answer")

	# Set these for display_result
	TEST_EXPECTED="$expected"
	TEST_GOT="$output"
	TEST_EXTRACTED="$extracted_answer"
	TEST_TEMP_DIR="$temp_dir"

	# Check if answer tags were found
	if [ -z "$extracted_answer" ]; then
		TEST_EXTRACTED="<missing answer tags>"
		return 1
	fi

	local test_result=0
	if [ "$extracted_answer" = "$expected" ]; then
		# Clean up temp dir on success
		rm -rf "$temp_dir"
		test_result=0
	else
		# Keep temp dir on failure for debugging
		test_result=1
	fi

	# Restore backups for global mode
	if [ "$mode" = "global" ]; then
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
			mkdir -p "$HOME/.agents/polyfills"
			echo "$polyfill_backup" > "$HOME/.agents/polyfills/claude/agentsmd.sh"
		else
			rm -f "$HOME/.agents/polyfills/claude/agentsmd.sh"
		fi
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
			printf "    $(c heading Debug:) Temp dir preserved at:\n"
			printf "      %s\n" "$TEST_TEMP_DIR"
		else
			# In normal mode, show everything for failures
			print_test_fail "$display_name"
			printf "    $(c heading Temp dir:)\n"
			print_indented 6 "$TEST_TEMP_DIR"
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
	printf "  -h, --help           Show this help message\n"
	printf "  -v, --verbose        Show full output for all tests\n"
	printf "  --mode $(c option MODE)      Installation mode to test: project, global, or all\n"
	printf "                       (default: $(c option all))\n"
	printf "  --install $(c option LEVEL)  Installation level: $(c option none), $(c option config), or $(c option full) (default)\n"
	printf "                       $(c option none):   Skip install (test native agent support)\n"
	printf "                       $(c option config): Config only (no polyfill hooks)\n"
	printf "                       $(c option full):   Complete installation with hooks\n\n"

	printf "$(c heading Examples:)\n"
	printf "  $(c command test-agents.sh)                                           # All tests, all agents, all modes\n"
	printf "  $(c command test-agents.sh) $(c agent claude)                                    # All tests on claude, all modes\n"
	printf "  $(c command test-agents.sh) --mode $(c option global) $(c agent claude)                  # All tests on claude, global mode\n"
	printf "  $(c command test-agents.sh) $(c agent claude) $(c agent gemini)                             # All tests on claude and gemini, all modes\n"
	printf "  $(c command test-agents.sh) $(c test basic-load)                                # basic-load on all agents, all modes\n"
	printf "  $(c command test-agents.sh) $(c test basic-load) $(c test nested-precedence)             # Two tests on all agents, all modes\n"
	printf "  $(c command test-agents.sh) $(c agent claude) $(c test basic-load)                         # basic-load on claude, all modes\n"
	printf "  $(c command test-agents.sh) --mode $(c option project) $(c agent claude) $(c test basic-load)          # basic-load on claude, project mode\n"
	printf "  $(c command test-agents.sh) $(c agent claude) $(c agent gemini) $(c test basic-load)                # basic-load on two agents, all modes\n"
	printf "  $(c command test-agents.sh) $(c agent claude) $(c test basic-load) $(c test nested-precedence)      # Two tests on claude, all modes\n"
	printf "  $(c command test-agents.sh) --install $(c option none) $(c agent claude)                 # Test claude's native support (no install)\n"
	printf "  $(c command test-agents.sh) --install $(c option config)                         # Test with config-only install (no hooks)\n\n"

	printf "$(c heading Agents:)\n"
	for agent in $KNOWN_AGENTS; do
		if command -v "$agent" >/dev/null 2>&1; then
			printf "  $(c agent %-8s) $(c success ✓ available)\n" "$agent"
		else
			printf "  $(c agent %-8s) $(c error ✗ not found)\n" "$agent"
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
# Main
# ============================================

main() {
	# Parse arguments
	local verbose=0
	local mode_arg="all"
	local install_arg="full"
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
			--mode)
				mode_arg="$2"
				case "$mode_arg" in
					project|global|all)
						shift 2
						;;
					*)
						panic 2 show_usage "Invalid mode: $(c option "'$mode_arg'"). Valid modes: $(c_list option project global all)"
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

	# Export for use in run_test and display_result
	VERBOSE=$verbose
	INSTALL_LEVEL=$install_arg

	# Determine modes to run
	local modes_to_run
	if [ "$mode_arg" = "all" ]; then
		modes_to_run="project global"
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

		# Check if it's an agent
		local is_agent=0
		for agent in $available_agents; do
			if [ "$agent" = "$arg" ]; then
				is_agent=1
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

	# Count agents
	local agent_count=0
	for agent in $agents_to_run; do
		agent_count=$((agent_count + 1))
	done

	# Run tests
	local total_passed=0
	local total_failed=0

	for agent in $agents_to_run; do
		print_section_header "$agent" "agent"

		local passed=0
		local failed=0

		for test_name in $tests_to_run; do
			for mode in $modes_to_run; do
				# Build display name for running state
				local display_name="$test_name"
				if [ "$SHOW_MODE" -eq 1 ]; then
					display_name="$test_name [$(c option "$mode")]"
				fi

				print_test_running "$display_name"

				if run_test "$agent" "$test_name" "$mode"; then
					passed=$((passed + 1))
					total_passed=$((total_passed + 1))
					result=0
				else
					failed=$((failed + 1))
					total_failed=$((total_failed + 1))
					result=1
				fi

				printf "\r"
				display_result "$test_name" "$result" "$mode"
			done
		done

		local agent_var=$(normalize_agent_name "$agent")
		eval "agent_passed_$agent_var=$passed"
		eval "agent_total_$agent_var=$((passed + failed))"
	done

	# Display summary
	local total=$((total_passed + total_failed))

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

	printf "\n"

	# Exit with appropriate code
	if [ "$total_failed" -gt 0 ]; then
		exit 1
	else
		exit 0
	fi
}

main "$@"
