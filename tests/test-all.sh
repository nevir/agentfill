#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load common libraries
. "$SCRIPT_DIR/_common/colors.sh"

# ============================================
# Main
# ============================================

VERBOSE=0

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

VERBOSE_FLAG=""
if [ "$VERBOSE" -eq 1 ]; then
	VERBOSE_FLAG="-v"
fi

TOTAL_FAILED=0

# Run install tests
printf "$(c suite "▸ Install Script Tests")\n"
"$SCRIPT_DIR/test-install.sh" $VERBOSE_FLAG
if [ $? -ne 0 ]; then
	TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

# Run agent tests (if agents available)
printf "$(c suite "▸ Agent Integration Tests")\n"
"$SCRIPT_DIR/test-agents.sh" $VERBOSE_FLAG
AGENT_EXIT=$?
if [ $AGENT_EXIT -eq 2 ]; then
	# Exit code 2 means no agents found (skipped)
	true
elif [ $AGENT_EXIT -ne 0 ]; then
	TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

# Summary
printf "$(c heading "=== Test Suite Summary ===")\n"
if [ "$TOTAL_FAILED" -eq 0 ]; then
	printf "$(c success "All test suites passed!")\n\n"
	exit 0
else
	printf "$(c error "$TOTAL_FAILED test suite(s) failed")\n\n"
	exit 1
fi
