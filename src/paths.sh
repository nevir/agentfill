VERSION="1.0.0"

SUPPORTED_AGENTS="claude cursor gemini"

# Installation modes
INSTALL_MODE="project"  # project, local, or global
INSTALL_LEVEL="full"    # none, config, or full

# Get Claude settings file path based on install mode
claude_settings_path() {
	case "$INSTALL_MODE" in
		project) echo ".claude/settings.json" ;;
		global)  echo "$HOME/.claude/settings.json" ;;
	esac
}

# Get Gemini settings file path based on install mode
gemini_settings_path() {
	case "$INSTALL_MODE" in
		project) echo ".gemini/settings.json" ;;
		global)  echo "$HOME/.gemini/settings.json" ;;
	esac
}

# Get Cursor hooks file path based on install mode
cursor_hooks_path() {
	case "$INSTALL_MODE" in
		project) echo ".cursor/hooks.json" ;;
		global)  echo "$HOME/.cursor/hooks.json" ;;
	esac
}

# Get polyfill directory based on install mode
polyfill_dir() {
	case "$INSTALL_MODE" in
		project) echo ".agents/polyfills" ;;
		global)  echo "$HOME/.agents/polyfills" ;;
	esac
}

# Map agent name to skills directory path
agent_skills_dir() {
	local agent="$1"
	case "$agent" in
		claude)     echo ".claude/skills" ;;
		cursor)     echo ".cursor/skills" ;;
		gemini)     echo ".gemini/skills" ;;
		codex)      echo ".codex/skills" ;;
		copilot)    echo ".github/skills" ;;
	esac
}

# Get polyfill reference path for settings/hooks config
polyfill_reference_path() {
	local agent="$1"
	local script_name="$2"
	local dir=$(polyfill_dir)
	case "$INSTALL_MODE" in
		project)
			local env_var
			case "$agent" in
				cursor) env_var="CURSOR_PROJECT_DIR" ;;
				*)          env_var="CLAUDE_PROJECT_DIR" ;;
			esac
			echo "\$$env_var/$dir/$script_name"
			;;
		global)
			echo "$dir/$script_name"
			;;
	esac
}
