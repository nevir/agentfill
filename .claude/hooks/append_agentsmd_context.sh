#!/bin/bash

# SessionStart hook for Claude Code
# Automatically appends all AGENTS.md files found in the repository to the context
# This is a workaround for Claude Code's current lack of native AGENTS.md support

echo "=== AGENTS.md Context Loading ==="
echo ""

# Find all AGENTS.md files in current directory and subdirectories
find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
    echo "--- Loading: $file ---"
    cat "$file"
    echo ""
done

echo "=== End of AGENTS.md Context ==="
