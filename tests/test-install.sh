#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/install.sh"
TESTS_DIR="$SCRIPT_DIR/install"

# Load common libraries
. "$SCRIPT_DIR/_common/colors.sh"
. "$SCRIPT_DIR/_common/utils.sh"
. "$SCRIPT_DIR/_common/output.sh"

# ============================================
# Test Infrastructure
# ============================================

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
VERBOSE=0

create_temp_project() {
	mktemp -d /tmp/install_test_XXXXXX
}

run_install() {
	local project_dir="$1"
	shift
	cd "$project_dir"
	"$INSTALL_SCRIPT" "$@"
}

assert_file_exists() {
	local file="$1"
	local desc="${2:-File should exist: $file}"

	if [ -f "$file" ]; then
		return 0
	else
		echo "$(c error "✗ $desc")"
		echo "  File not found: $file"
		return 1
	fi
}

assert_file_not_exists() {
	local file="$1"
	local desc="${2:-File should not exist: $file}"

	if [ ! -f "$file" ]; then
		return 0
	else
		echo "$(c error "✗ $desc")"
		echo "  File unexpectedly exists: $file"
		return 1
	fi
}

assert_file_contains() {
	local file="$1"
	local pattern="$2"
	local desc="${3:-File should contain pattern: $pattern}"

	if [ ! -f "$file" ]; then
		echo "$(c error "✗ $desc")"
		echo "  File not found: $file"
		return 1
	fi

	if grep -q "$pattern" "$file"; then
		return 0
	else
		echo "$(c error "✗ $desc")"
		echo "  Pattern not found in $file: $pattern"
		return 1
	fi
}

assert_json_has_key() {
	local file="$1"
	local key="$2"
	local desc="${3:-JSON should have key: $key}"

	if [ ! -f "$file" ]; then
		echo "$(c error "✗ $desc")"
		echo "  File not found: $file"
		return 1
	fi

	if perl -MJSON::PP -0777 -e "
		my \$json = JSON::PP->new->utf8->relaxed;
		my \$data = \$json->decode(do { local \$/; <STDIN> });
		my @keys = split /\\./, '$key';
		my \$ref = \$data;
		for my \$k (@keys) {
			if (ref \$ref eq 'HASH' && exists \$ref->{\$k}) {
				\$ref = \$ref->{\$k};
			} else {
				exit 1;
			}
		}
		exit 0;
	" < "$file" 2>/dev/null; then
		return 0
	else
		echo "$(c error "✗ $desc")"
		echo "  Key not found in $file: $key"
		return 1
	fi
}

# ============================================
# Test Runner
# ============================================

run_test() {
	local test_name="$1"
	local test_func="$2"

	TEST_COUNT=$((TEST_COUNT + 1))

	local temp_dir=$(create_temp_project)
	local output_file="$temp_dir.output"

	if [ "$VERBOSE" -eq 1 ]; then
		print_test_header_verbose "$test_name"
		if (cd "$temp_dir" && $test_func "$temp_dir" 2>&1); then
			PASS_COUNT=$((PASS_COUNT + 1))
			print_test_result_verbose 0
			rm -rf "$temp_dir"
			return 0
		else
			FAIL_COUNT=$((FAIL_COUNT + 1))
			print_test_result_verbose 1
			printf "  $(c heading "Debug:") Project preserved at: $temp_dir\n"
			return 1
		fi
	else
		print_test_running "$test_name"
		if (cd "$temp_dir" && $test_func "$temp_dir" 2>&1) > "$output_file" 2>&1; then
			PASS_COUNT=$((PASS_COUNT + 1))
			print_test_pass "$test_name"
			rm -rf "$temp_dir" "$output_file"
			return 0
		else
			FAIL_COUNT=$((FAIL_COUNT + 1))
			print_test_fail "$test_name"
			printf "  $(c heading "Output:")\n"
			cat "$output_file" | sed 's/^/    /'
			printf "  $(c heading "Debug:") Project preserved at: $temp_dir\n"
			rm -f "$output_file"
			return 1
		fi
	fi
}

# ============================================
# Load Test Suites
# ============================================

. "$TESTS_DIR/fresh-install.sh"
. "$TESTS_DIR/idempotency.sh"
. "$TESTS_DIR/merging.sh"
. "$TESTS_DIR/special-cases.sh"

# ============================================
# Main
# ============================================

main() {
	while [ $# -gt 0 ]; do
		case "$1" in
			-v|--verbose)
				VERBOSE=1
				shift
				;;
			*)
				shift
				;;
		esac
	done

	printf "\n"

	print_section_header "fresh-install"
	run_test "fresh-install-all-agents" test_fresh_install_all_agents
	run_test "fresh-install-claude-only" test_fresh_install_claude_only
	run_test "fresh-install-gemini-only" test_fresh_install_gemini_only
	printf "\n"

	print_section_header "idempotency"
	run_test "idempotent-rerun" test_idempotent_rerun
	run_test "skip-when-already-configured" test_skip_when_already_configured
	run_test "existing-agents-md-preserved" test_existing_agents_md_preserved
	printf "\n"

	print_section_header "merging"
	run_test "merge-claude-existing-permissions" test_merge_claude_existing_permissions
	run_test "merge-gemini-existing-context" test_merge_gemini_existing_context
	printf "\n"

	print_section_header "special-cases"
	run_test "polyfill-update" test_polyfill_update
	run_test "dry-run-no-changes" test_dry_run_no_changes
	printf "\n"

	printf "$(c success %d/%d passed)\n" "$PASS_COUNT" "$TEST_COUNT"
	printf "\n"

	if [ "$FAIL_COUNT" -gt 0 ]; then
		exit 1
	fi
}

main "$@"
