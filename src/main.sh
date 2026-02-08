# ============================================
# Usage and help
# ============================================

usage() {
	printf "$(c heading Usage:) install.sh [$(c flag OPTIONS)] [$(c path PATH)] [$(c agent AGENTS...)]"
}

show_help() {
	printf "\n"
	printf "$(usage)\n\n"
	printf "AGENTS.md polyfill installer - Configure AI agents to support AGENTS.md\n\n"

	printf "$(c heading Arguments:)\n"
	printf "  $(c path PATH)             Project directory (default: current directory)\n"
	printf "  $(c agent AGENTS...)        Agent names to configure\n"
	printf "                   Valid agents: $(c_list agent $SUPPORTED_AGENTS), or $(c option all) for all agents\n"
	printf "                   If omitted, auto-detects installed agents\n\n"

	printf "$(c heading Options:)\n"
	printf "  $(c flag -h), $(c flag --help)       Show this help message\n"
	printf "  $(c flag -y), $(c flag --yes)        Auto-confirm (skip prompts, use all agents)\n"
	printf "  $(c flag -n), $(c flag --dry-run)    Show plan only, don't apply changes\n"
	printf "  $(c flag --global)            Install to user home directory (~/.claude/)\n\n"

	printf "$(c heading Examples:)\n"
	printf "  install.sh                      # Auto-detect agents, interactive mode\n"
	printf "  install.sh $(c agent claude)               # Only Claude, project mode\n"
	printf "  install.sh $(c agent cursor)               # Only Cursor, project mode\n"
	printf "  install.sh $(c agent claude) $(c agent gemini)        # Multiple agents\n"
	printf "  install.sh $(c option all)                  # Install all supported agents\n"
	printf "  install.sh $(c flag --global)             # Global mode (user home)\n"
	printf "  install.sh $(c flag --global) $(c option all)        # All agents, global mode\n"
	printf "  install.sh $(c path /path/to/project)     # Specific directory\n"
	printf "  install.sh $(c flag -y)                   # Auto-confirm, all agents\n"
	printf "  install.sh $(c flag -n)                   # Dry-run mode\n\n"
}

# ============================================
# Main
# ============================================

main() {
	local auto_confirm=false
	local dry_run=false
	local project_dir="."
	local agents=""
	local positional_args=""

	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				show_help
				exit 0
				;;
			-y|--yes)
				auto_confirm=true
				shift
				;;
			-n|--dry-run)
				dry_run=true
				shift
				;;
			--global)
				INSTALL_MODE="global"
				shift
				;;
			--level)
				case "$2" in
					config|full)
						INSTALL_LEVEL="$2"
						shift 2
						;;
					*)
						panic 2 show_usage "Invalid level: $(c option "'$2'"). Valid levels: $(c_list option config full)"
						;;
				esac
				;;
			-*)
				panic 2 show_usage "Unknown option: $1"
				;;
			*)
				positional_args="$positional_args $1"
				shift
				;;
		esac
	done

	positional_args=$(trim "$positional_args")
	if [ -n "$positional_args" ]; then
		set -- $positional_args
		local first_arg="$1"

		# Check if first arg is "all" or a supported agent
		case "$first_arg" in
			all|All|ALL)
				# "all" keyword - treat as agent specification
				if [ -e "$first_arg" ]; then
					panic 2 <<-end_panic
						Ambiguous argument: $(c option "'$first_arg'")
						This is the special $(c option all) keyword AND an existing path.
						Please rename the file/directory or use an explicit path like $(c path "'./$first_arg'")
					end_panic
				fi
				agents="$positional_args"
				;;
			*)
				# Check if it's a supported agent
				if list_contains "$first_arg" "$SUPPORTED_AGENTS"; then
					if [ -e "$first_arg" ]; then
						panic 2 <<-end_panic
							Ambiguous argument: $(c agent "'$first_arg'")
							This is both a valid agent name AND an existing path.
							Please rename the file/directory or use an explicit path like $(c path "'./$first_arg'")
						end_panic
					fi
					agents="$positional_args"
				else
					# Not a known agent or "all" - check if it's a path
					case "$first_arg" in
						*/*|.|..)
							project_dir="$first_arg"
							shift
							agents="$*"
							;;
						*)
							panic 2 "Unknown agent: $(c agent "'$first_arg'") (valid agents: $(c_list agent $SUPPORTED_AGENTS), or $(c option all))"
							;;
					esac
				fi
				;;
		esac
	fi

	open_user_input

	check_perl

	cd "$project_dir" || panic 2 "Cannot access directory: $(c path "'$project_dir'")"

	# Prompt for installation location if not specified and not auto-confirm
	if [ "$INSTALL_MODE" = "project" ] && [ "$auto_confirm" = false ] && is_interactive; then
		printf "\n$(c heading 'Installation location:')\n\n"
		printf "  $(c option 1)) $(c option Project) - .claude/settings.json (shared, tracked in git)\n"
		printf "  $(c option 2)) $(c option Global)  - ~/.claude/settings.json (user home, all projects)\n"
		printf "\n"
		printf "Choice [$(c option 1)]: "
		read -r choice <&3

		choice=$(trim "${choice:-1}")
		case "$choice" in
			1|project|Project) INSTALL_MODE="project" ;;
			2|global|Global)   INSTALL_MODE="global" ;;
			*) panic 2 "Invalid choice: $choice" ;;
		esac
		printf "\n"
	fi

	local enabled_agents=""

	if [ -z "$agents" ]; then
		# No agents specified - use interactive selection if available
		if [ "$auto_confirm" = false ] && is_interactive; then
			SELECTED_AGENTS=""
			select_agents
			enabled_agents="$SELECTED_AGENTS"
		else
			# Non-interactive mode: use all supported agents
			enabled_agents="$SUPPORTED_AGENTS"
		fi
	else
		# Agents specified on command line
		# Handle "all" keyword to install all supported agents
		case "$agents" in
			all|All|ALL)
				enabled_agents="$SUPPORTED_AGENTS"
				;;
			*)
				for agent in $agents; do
					if ! list_contains "$agent" "$SUPPORTED_AGENTS"; then
						panic 2 "Unknown agent: $(c agent "'$agent'") (valid agents: $(c_list agent $SUPPORTED_AGENTS), or $(c option all))"
					fi
					enabled_agents="$enabled_agents $agent"
				done
				enabled_agents=$(trim "$enabled_agents")
				;;
		esac
	fi

	# Validate the selected agents
	for agent in $enabled_agents; do
		if ! list_contains "$agent" "$SUPPORTED_AGENTS"; then
			panic 2 "Unknown agent: $(c agent "'$agent'") (valid agents: $(c_list agent $SUPPORTED_AGENTS))"
		fi
	done

	printf "\n$(c heading '=== AGENTS.md Polyfill Installer ===')\n"
	printf "Version: $VERSION\n"
	printf "Project: $(pwd)\n"
	if [ "$INSTALL_MODE" = "global" ]; then
		printf "Location: $(c option Global) (~/.claude/)\n\n"
	else
		printf "Location: $(c option Project) (.claude/)\n\n"
	fi

	for agent in $SUPPORTED_AGENTS; do
		if list_contains "$agent" "$enabled_agents"; then
			eval "plan_$(func_name "$agent")"
		fi
	done

	display_ledger

	if [ "$dry_run" = true ]; then
		printf "$(c warning 'Dry-run mode - no changes applied')\n\n"
		exit 0
	fi

	if ! has_pending_changes; then
		printf "$(c success '✓ Already up to date!')\n\n"
		exit 0
	fi

	if [ "$auto_confirm" = false ] && is_interactive; then
		if ! ask_confirmation; then
			printf "\n$(c warning 'Installation cancelled')\n\n"
			exit 0
		fi
	fi

	printf "\n$(c heading 'Applying changes...')\n\n"
	apply_changes

	# Create skills symlinks (project mode only)
	if [ "$INSTALL_MODE" = "project" ]; then
		for agent in $SUPPORTED_AGENTS; do
			if list_contains "$agent" "$enabled_agents"; then
				create_skills_symlink "$agent"
			fi
		done
	fi

	printf "\n$(c success '✓ Installation complete!')\n\n"
	printf "$(c heading 'Next steps:')\n"
	printf "  1. Create AGENTS.md files in your project\n"
	printf "  2. Test with your AI agent\n"
	printf "  3. Learn more: https://agents.md\n\n"
}
