#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/install.sh"
TESTS_DIR="$SCRIPT_DIR/unit"

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

	# Build a map of suite -> tests
	local current_suite=""
	local test_file
	local test_func

	for test_file in $(discover_test_files); do
		local suite_name=$(get_suite_name "$test_file")

		# Print suite header when we encounter a new suite
		if [ "$suite_name" != "$current_suite" ]; then
			if [ -n "$current_suite" ]; then
				printf "\n"
			fi
			print_section_header "$suite_name"
			current_suite="$suite_name"
		fi

		# Run all test functions from this file
		for test_func in $(grep -E '^test_[a-zA-Z0-9_]+\(\)' "$test_file" | sed 's/().*$//' || true); do
			# Convert test_function_name to test-name
			local test_name=$(echo "$test_func" | sed 's/^test_//' | tr '_' '-')
			run_test "$test_name" "$test_func"
		done
	done

	printf "\n"
	printf "$(c success %d/%d passed)\n" "$PASS_COUNT" "$TEST_COUNT"
	printf "\n"

	if [ "$FAIL_COUNT" -gt 0 ]; then
		exit 1
	fi
}

main "$@"
