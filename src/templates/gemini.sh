# ============================================
# Gemini templates
# ============================================

template_gemini_settings() {
	# Config level: just context settings, no hooks
	if [ "$INSTALL_LEVEL" = "config" ]; then
		cat <<-'end_template'
			{
			  "context": {
			    "fileName": ["AGENTS.md", "GEMINI.md"]
			  }
			}
		end_template
		return
	fi

	# Full level: Global mode includes the skills hook
	if [ "$INSTALL_MODE" = "global" ]; then
		local skills_hook_path="$(polyfill_dir)/skills/gemini.sh"
		cat <<-end_template
			{
			  "context": {
			    "fileName": ["AGENTS.md", "GEMINI.md"]
			  },
			  "hooks": {
			    "SessionStart": [
			      {
			        "type": "command",
			        "command": "$skills_hook_path"
			      }
			    ]
			  }
			}
		end_template
	else
		cat <<-'end_template'
			{
			  "context": {
			    "fileName": ["AGENTS.md", "GEMINI.md"]
			  }
			}
		end_template
	fi
}

template_gemini_skills_hook() {
	cat <<-'end_template'
		#!/bin/sh

		# Skills symlink hook for Gemini (global install)
		# Creates symlinks to .agents/skills/ on-demand per project

		PROJECT_DIR="${GEMINI_PROJECT_DIR:-.}"
		TARGET="$PROJECT_DIR/.gemini/skills"

		# Check for skills source: project skills first, then global skills
		if [ -d "$PROJECT_DIR/.agents/skills" ]; then
			SOURCE="../.agents/skills"
		elif [ -d "$HOME/.agents/skills" ]; then
			SOURCE="$HOME/.agents/skills"
		else
			exit 0
		fi

		# Safety: existing non-symlink directory - warn and skip
		if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
			echo "Warning: $TARGET exists and is not a symlink. Move skills to .agents/skills/ to use universal skills." >&2
			exit 0
		fi

		# Already a symlink - nothing to do
		if [ -L "$TARGET" ]; then
			exit 0
		fi

		# Create symlink
		mkdir -p "$PROJECT_DIR/.gemini"
		ln -s "$SOURCE" "$TARGET"

		# Instruct user to restart (skills discovered before hook runs)
		cat <<-end_message
		<skills_setup>
		Skills symlink created. Please restart Gemini to discover skills in this project.
		</skills_setup>
		end_message
	end_template
}
