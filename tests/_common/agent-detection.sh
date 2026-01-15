
# ============================================
# Agent Detection
# ============================================

# Detect if running under an AI agent
run_by_agent() {
	[ "$CLAUDECODE" = "1" ] && return 0                                                               # Claude Code
	[ -n "$GEMINI_CLI_SYSTEM_DEFAULTS_PATH" ] || [ -n "$GEMINI_CLI_SYSTEM_SETTINGS_PATH" ] && return 0  # Gemini CLI
	[ -n "$CODEX_HOME" ] && return 0                                                                  # OpenAI Codex
	return 1
}

# Auto-enable verbose mode and disable colors when running under an agent
# This is called automatically when this file is sourced
if run_by_agent; then
	VERBOSE=1
	DISABLE_COLORS=1
	export DISABLE_COLORS
else
	VERBOSE=0
	DISABLE_COLORS=0
fi
