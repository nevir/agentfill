#!/bin/sh
# Skills symlink setup for Claude Code
# Creates .claude/skills -> ../.agents/skills

CLAUDE_SKILLS="${CLAUDE_PROJECT_DIR:-.}/.claude/skills"

# Determine skills source (project takes precedence over global)
if [ -d "${CLAUDE_PROJECT_DIR:-.}/.agents/skills" ]; then
	SKILLS_SOURCE="../.agents/skills"
elif [ -d "$HOME/.agents/skills" ]; then
	SKILLS_SOURCE="$HOME/.agents/skills"
else
	exit 0  # No skills directory
fi

# Safety: don't overwrite existing non-symlink directory
if [ -e "$CLAUDE_SKILLS" ] && [ ! -L "$CLAUDE_SKILLS" ]; then
	echo "Warning: $CLAUDE_SKILLS exists and is not a symlink. Skipping." >&2
	echo "To use .agents/skills, move your skills there and delete .claude/skills" >&2
	exit 0
fi

# Skip if symlink already correct
if [ -L "$CLAUDE_SKILLS" ]; then
	target=$(readlink "$CLAUDE_SKILLS")
	[ "$target" = "$SKILLS_SOURCE" ] && exit 0
fi

mkdir -p "$(dirname "$CLAUDE_SKILLS")"
[ -L "$CLAUDE_SKILLS" ] && rm "$CLAUDE_SKILLS"
ln -s "$SKILLS_SOURCE" "$CLAUDE_SKILLS"
echo "Created skills symlink: $CLAUDE_SKILLS -> $SKILLS_SOURCE" >&2
