#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/install.sh"
TESTS_DIR="$SCRIPT_DIR/unit"

# Load agent detection (auto-configures VERBOSE and DISABLE_COLORS)
. "$SCRIPT_DIR/_common/agent-detection.sh"

# Load common libraries (after setting DISABLE_COLORS)
. "$SCRIPT_DIR/_common/colors.sh"
. "$SCRIPT_DIR/_common/utils.sh"
. "$SCRIPT_DIR/_common/output.sh"

# ============================================
# Test Infrastructure
# ============================================

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

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

assert_file_not_contains() {
	local file="$1"
	local pattern="$2"
	local desc="${3:-File should not contain pattern: $pattern}"

	if [ ! -f "$file" ]; then
		echo "$(c error "✗ $desc")"
		echo "  File not found: $file"
		return 1
	fi

	if grep -q "$pattern" "$file"; then
		echo "$(c error "✗ $desc")"
		echo "  Pattern unexpectedly found in $file: $pattern"
		return 1
	else
		return 0
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
# Test Discovery
# ============================================

discover_test_files() {
	find "$TESTS_DIR" -type f -name "*.sh" | sort
}

load_test_suites() {
	local test_file
	for test_file in $(discover_test_files); do
		. "$test_file"
	done
}

discover_test_functions() {
	local test_file
	for test_file in $(discover_test_files); do
		grep -E '^test_[a-zA-Z0-9_]+\(\)' "$test_file" | sed 's/().*$//' || true
	done
}

get_suite_name() {
	local test_file="$1"
	local suite_name

	# Remove TESTS_DIR prefix and .sh suffix
	suite_name="${test_file#$TESTS_DIR/}"
	suite_name="${suite_name%.sh}"

	# Convert path separators to colons for nested tests
	suite_name="$(echo "$suite_name" | tr '/' ':')"

	echo "$suite_name"
}

# ============================================
# Load Test Suites
# ============================================

load_test_suites

# ============================================
# Main
# ============================================

main() {
	local requested_tests=""

	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				show_help
				exit 0
				;;
			-v|--verbose)
				VERBOSE=1
				shift
				;;
			-*)
				panic 2 show_usage "Unknown option: $1"
				;;
			*)
				requested_tests="$requested_tests $1"
				shift
				;;
		esac
	done

	# Build a map of suite -> tests
	local current_suite=""
	local test_file
	local test_func

	for test_file in $(discover_test_files); do
		local suite_name=$(get_suite_name "$test_file")
		local suite_printed=0

		# Run all test functions from this file
		for test_func in $(grep -E '^test_[a-zA-Z0-9_]+\(\)' "$test_file" | sed 's/().*$//' || true); do
			# Convert test_function_name to test-name
			local test_name=$(echo "$test_func" | sed 's/^test_//' | tr '_' '-')

			# Skip if specific tests requested and this isn't one of them
			if [ -n "$requested_tests" ]; then
				local found=0
				for req_test in $requested_tests; do
					if [ "$test_name" = "$req_test" ]; then
						found=1
						break
					fi
				done
				if [ "$found" -eq 0 ]; then
					continue
				fi
			fi

			# Print suite header when we encounter a new suite (only if we're running tests from it)
			if [ "$suite_name" != "$current_suite" ] || [ "$suite_printed" -eq 0 ]; then
				if [ -n "$current_suite" ] && [ "$suite_printed" -eq 1 ]; then
					printf "\n"
				fi
				print_section_header "$suite_name"
				current_suite="$suite_name"
				suite_printed=1
			fi

			run_test "$test_name" "$test_func"
		done
	done

	printf "\n"

	# Warn if specific tests were requested but none were found
	if [ -n "$requested_tests" ] && [ "$TEST_COUNT" -eq 0 ]; then
		printf "$(c warning "Warning:") No tests matched: $requested_tests\n"
		printf "\n"
		exit 1
	fi

	printf "$(c success %d/%d passed)\n" "$PASS_COUNT" "$TEST_COUNT"
	printf "\n"

	if [ "$FAIL_COUNT" -gt 0 ]; then
		exit 1
	fi
}

# ============================================
# Usage and help
# ============================================

usage() {
	printf "Usage: $(c command "test-unit.sh") [$(c flag "OPTIONS")] [$(c test "TEST")...]\n"
}

show_help() {
	printf "%s\n\n" "$(usage)"
	printf "Run unit tests for the install script.\n\n"
	printf "$(c heading "OPTIONS:")\n"
	printf "  $(c flag "-v, --verbose")    Show verbose test output\n"
	printf "  $(c flag "-h, --help")       Show this help message\n\n"
	printf "$(c heading "ARGUMENTS:")\n"
	printf "  $(c test "TEST")              One or more test names to run (runs all if not specified)\n\n"
	printf "$(c heading "EXAMPLES:")\n"
	printf "  $(c command "test-unit.sh")                                    Run all tests\n"
	printf "  $(c command "test-unit.sh") $(c flag "-v")                                  Run all tests (verbose)\n"
	printf "  $(c command "test-unit.sh") $(c test "basic-install")                      Run specific test\n"
	printf "  $(c command "test-unit.sh") $(c test "basic-install") $(c test "config-only")      Run multiple tests\n"
}

main "$@"
