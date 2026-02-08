#!/bin/sh
set -e

# Compile src/ modules into site/install for curl|sh distribution.
# Source file order is derived from install.sh (single source of truth).
#
# Usage: ./scripts/compile.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT="$REPO_ROOT/site/install"

# Extract source files from install.sh (parse `. "$SCRIPT_DIR/..."` lines)
SOURCE_FILES=$(sed -n 's/^\. "\$SCRIPT_DIR\/\(.*\)"/\1/p' "$REPO_ROOT/install.sh")

if [ -z "$SOURCE_FILES" ]; then
	echo "Error: no source files found in install.sh" >&2
	exit 1
fi

{
	printf '#!/bin/sh\n'
	printf 'set -e\n'

	for file in $SOURCE_FILES; do
		filepath="$REPO_ROOT/$file"
		if [ ! -f "$filepath" ]; then
			echo "Error: $file not found" >&2
			exit 1
		fi
		printf '\n'
		# Strip shebang lines and set -e from source files
		sed '/^#!\/bin\/sh$/d; /^set -e$/d' "$filepath"
	done

	printf '\nmain "$@"\n'
} > "$OUTPUT"

chmod +x "$OUTPUT"

echo "Compiled site/install ($(wc -l < "$OUTPUT" | tr -d ' ') lines)"
