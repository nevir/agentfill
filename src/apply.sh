# ============================================
# Apply changes
# ============================================

has_pending_changes() {
	local i=1
	while [ $i -le $CHANGE_COUNT ]; do
		eval "local type=\$CHANGE_${i}_TYPE"
		case "$type" in create|modify) return 0 ;; esac
		i=$((i + 1))
	done
	return 1
}

apply_changes() {
	local i=1
	while [ $i -le $CHANGE_COUNT ]; do
		eval "local file=\$CHANGE_${i}_FILE"
		eval "local type=\$CHANGE_${i}_TYPE"
		eval "local content_file=\$CHANGE_${i}_CONTENT_FILE"

		case "$type" in
			create)
				local dir=$(dirname "$file")
				[ "$dir" != "." ] && mkdir -p "$dir"

				cat "$content_file" > "$file"

				# Make executable if it's a hook script
				case "$file" in
					*.sh) chmod +x "$file" ;;
				esac

				printf "$(c success ✓) Created $file\n"
				;;
			modify)
				cp "$file" "${file}.backup.$(date +%s)"
				cat "$content_file" > "$file"

				printf "$(c success ✓) Modified $file\n"
				;;
			skip)
				;;
		esac

		i=$((i + 1))
	done
}

ask_confirmation() {
	local response
	printf "Apply these changes? [y/N]: "
	read -r response <&3

	case "$response" in
		[yY]|[yY][eE][sS]) return 0 ;;
		*)                 return 1 ;;
	esac
}

# ============================================
# Skills symlinks (project install only)
# ============================================

# Create skills symlink for an agent
# Only called in project mode; global mode uses hooks instead (Task 04)
create_skills_symlink() {
	local agent="$1"
	local target
	target=$(agent_skills_dir "$agent")

	# Only create symlinks if .agents/skills/ exists
	[ -d ".agents/skills" ] || return 0

	# Skip if agent has no skills directory mapping
	[ -n "$target" ] || return 0

	# Safety: don't overwrite existing non-symlink (user's skills)
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		printf "$(c warning Warning:) $(c path "$target") exists and is not a symlink. Skipping.\n" >&2
		printf "  Move your skills to $(c path ".agents/skills/") to use universal skills.\n" >&2
		return 0
	fi

	# Skip if symlink already points to correct target
	if [ -L "$target" ]; then
		local current
		current=$(readlink "$target")
		if [ "$current" = "../.agents/skills" ]; then
			return 0
		fi
		# Wrong target - remove and recreate
		rm "$target"
	fi

	# Create parent directory and symlink
	mkdir -p "$(dirname "$target")"
	ln -s "../.agents/skills" "$target"
	printf "$(c success Created:) $(c path "$target") -> $(c path "../.agents/skills")\n"
}

cleanup() {
	cleanup_change_files
	[ -n "$USER_INPUT_FD" ] && exec 3<&- 2>/dev/null || true
}
trap cleanup EXIT
