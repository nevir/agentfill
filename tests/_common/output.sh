
# ============================================
# Output Formatting
# ============================================

# Print a spinner character for a running test
print_test_running() {
	local test_name="$1"
	printf "\r◌ $(c test "$test_name")"
}

# Print test success
print_test_pass() {
	local test_name="$1"
	printf "\r\033[K"
	printf "$(c success ✓) $(c test "$test_name")\n"
}

# Print test failure
print_test_fail() {
	local test_name="$1"
	printf "\r\033[K"
	printf "$(c error ✗) $(c test "$test_name")\n"
}

# Print verbose test header
print_test_header_verbose() {
	local test_name="$1"
	printf "\n$(c heading "Test:") $(c test "$test_name")\n"
}

# Print verbose test result
print_test_result_verbose() {
	local result="$1"
	if [ "$result" -eq 0 ]; then
		printf "  $(c success "PASS")\n"
	else
		printf "  $(c error "FAIL")\n"
	fi
}

# Print section heading
print_heading() {
	local text="$1"
	printf "$(c heading "$text")\n"
}

# Print section header with === style
print_section_header() {
	local section_name="$1"
	local color="${2:-heading}"
	printf "\n$(c bold)$(c "$color" "=== $section_name ===")\n"
}

# Print indented content
print_indented() {
	local spaces="$1"
	local text="$2"
	echo "$text" | while IFS= read -r line; do
		printf "%${spaces}s%s\n" "" "$line"
	done
}
