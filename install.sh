#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

. "$SCRIPT_DIR/src/lib/colors.sh"
. "$SCRIPT_DIR/src/lib/utils.sh"
. "$SCRIPT_DIR/src/paths.sh"
. "$SCRIPT_DIR/src/json.sh"
. "$SCRIPT_DIR/src/agents.sh"
. "$SCRIPT_DIR/src/templates/claude.sh"
. "$SCRIPT_DIR/src/templates/cursor.sh"
. "$SCRIPT_DIR/src/templates/gemini.sh"
. "$SCRIPT_DIR/src/planning.sh"
. "$SCRIPT_DIR/src/apply.sh"
. "$SCRIPT_DIR/src/main.sh"

main "$@"
