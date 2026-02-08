# ============================================
# Change tracking
# ============================================

CHANGE_COUNT=0

add_change() {
	local type="$1"      # create, modify, skip
	local file="$2"
	local desc="$3"
	local content="$4"   # Full file content for diff

	CHANGE_COUNT=$((CHANGE_COUNT + 1))
	eval "CHANGE_${CHANGE_COUNT}_TYPE='$type'"
	eval "CHANGE_${CHANGE_COUNT}_FILE='$file'"
	eval "CHANGE_${CHANGE_COUNT}_DESC='$desc'"

	# Store content in temp file to avoid escaping issues
	local content_file="/tmp/install_change_${CHANGE_COUNT}_$$"
	printf '%s\n' "$content" > "$content_file"
	eval "CHANGE_${CHANGE_COUNT}_CONTENT_FILE='$content_file'"
}

cleanup_change_files() {
	local i=1
	while [ $i -le $CHANGE_COUNT ]; do
		eval "local content_file=\$CHANGE_${i}_CONTENT_FILE"
		[ -f "$content_file" ] && rm -f "$content_file"
		i=$((i + 1))
	done
}

# ============================================
# Ledger display
# ============================================

display_ledger() {
	printf "\n$(c heading '=== Planned Changes ===')\n\n"

	# Show diffs for each planned change (except skip)
	local i=1
	while [ $i -le $CHANGE_COUNT ]; do
		eval "local file=\$CHANGE_${i}_FILE"
		eval "local type=\$CHANGE_${i}_TYPE"
		eval "local content_file=\$CHANGE_${i}_CONTENT_FILE"

		if [ "$type" != "skip" ]; then
			printf "$(c blue '━━━') $(c cyan "$file") $(c blue '━━━')\n"

			if [ -f "$file" ]; then
				diff -u "$file" "$content_file" 2>/dev/null || true
			else
				diff -u /dev/null "$content_file" 2>/dev/null || true
			fi
			printf "\n"
		fi

		i=$((i + 1))
	done

	printf "$(c blue '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')\n\n"

	# Show summary
	printf "$(c heading Summary:)\n"
	local i=1
	while [ $i -le $CHANGE_COUNT ]; do
		eval "local file=\$CHANGE_${i}_FILE"
		eval "local type=\$CHANGE_${i}_TYPE"
		eval "local desc=\$CHANGE_${i}_DESC"

		case "$type" in
			create) printf "  $(c success CREATE)  $file" ;;
			modify) printf "  $(c warning MODIFY)  $file" ;;
			skip)   printf "  $(c blue SKIP)    $file" ;;
		esac

		[ -n "$desc" ] && printf " $(c blue "($desc)")"
		printf "\n"

		i=$((i + 1))
	done

	printf "\n"
}

# ============================================
# Change planning
# ============================================

plan_json() {
	local settings_file="$1"
	local template_content="$2"
	local modify_desc="$3"

	if [ -f "$settings_file" ]; then
		local temp_file="/tmp/settings_tmp_$$"
		cp "$settings_file" "$temp_file"
		if json_merge_deep "$temp_file" "$template_content"; then
			add_change "skip" "$settings_file" "already configured" ""
			rm -f "$temp_file"
		else
			local new_content=$(cat "$temp_file")
			rm -f "$temp_file"
			add_change "modify" "$settings_file" "$modify_desc" "$new_content"
		fi
	else
		add_change "create" "$settings_file" "" "$template_content"
	fi
}

plan_gemini() {
	plan_json \
		"$(gemini_settings_path)" \
		"$(template_gemini_settings)" \
		"add AGENTS.md to context"

	# Config level: no polyfill scripts
	[ "$INSTALL_LEVEL" = "config" ] && return

	# Global mode: plan the skills hook script
	if [ "$INSTALL_MODE" = "global" ]; then
		local skills_hook_path="$(polyfill_dir)/skills/gemini.sh"
		local skills_content="$(template_gemini_skills_hook)"

		if [ -f "$skills_hook_path" ]; then
			local current_skills_content="$(cat "$skills_hook_path")"
			if [ "$current_skills_content" = "$skills_content" ]; then
				add_change "skip" "$skills_hook_path" "already up to date" ""
			else
				add_change "modify" "$skills_hook_path" "update to latest version" "$skills_content"
			fi
		else
			add_change "create" "$skills_hook_path" "" "$skills_content"
		fi
	fi
}

plan_claude() {
	plan_json \
		"$(claude_settings_path)" \
		"$(template_claude_settings)" \
		"add AGENTS.md hook"

	# Config level: no polyfill scripts
	[ "$INSTALL_LEVEL" = "config" ] && return

	# Plan the AGENTS.md hook script
	local polyfill_path="$(polyfill_dir)/agentsmd/claude.sh"
	local new_content="$(template_claude_hook)"

	if [ -f "$polyfill_path" ]; then
		local current_content="$(cat "$polyfill_path")"
		if [ "$current_content" = "$new_content" ]; then
			add_change "skip" "$polyfill_path" "already up to date" ""
		else
			add_change "modify" "$polyfill_path" "update to latest version" "$new_content"
		fi
	else
		add_change "create" "$polyfill_path" "" "$new_content"
	fi

	# Global mode: also plan the skills hook script
	if [ "$INSTALL_MODE" = "global" ]; then
		local skills_hook_path="$(polyfill_dir)/skills/claude.sh"
		local skills_content="$(template_claude_skills_hook)"

		if [ -f "$skills_hook_path" ]; then
			local current_skills_content="$(cat "$skills_hook_path")"
			if [ "$current_skills_content" = "$skills_content" ]; then
				add_change "skip" "$skills_hook_path" "already up to date" ""
			else
				add_change "modify" "$skills_hook_path" "update to latest version" "$skills_content"
			fi
		else
			add_change "create" "$skills_hook_path" "" "$skills_content"
		fi
	fi
}

plan_cursor() {
	plan_json \
		"$(cursor_hooks_path)" \
		"$(template_cursor_hooks)" \
		"add AGENTS.md sessionStart hook"

	# Config level: no polyfill scripts
	[ "$INSTALL_LEVEL" = "config" ] && return

	# Plan the AGENTS.md hook script
	local polyfill_path="$(polyfill_dir)/agentsmd/cursor.sh"
	local new_content="$(template_cursor_hook)"

	if [ -f "$polyfill_path" ]; then
		local current_content="$(cat "$polyfill_path")"
		if [ "$current_content" = "$new_content" ]; then
			add_change "skip" "$polyfill_path" "already up to date" ""
		else
			add_change "modify" "$polyfill_path" "update to latest version" "$new_content"
		fi
	else
		add_change "create" "$polyfill_path" "" "$new_content"
	fi

	# Global mode: also plan the skills hook script
	if [ "$INSTALL_MODE" = "global" ]; then
		local skills_hook_path="$(polyfill_dir)/skills/cursor.sh"
		local skills_content="$(template_cursor_skills_hook)"

		if [ -f "$skills_hook_path" ]; then
			local current_skills_content="$(cat "$skills_hook_path")"
			if [ "$current_skills_content" = "$skills_content" ]; then
				add_change "skip" "$skills_hook_path" "already up to date" ""
			else
				add_change "modify" "$skills_hook_path" "update to latest version" "$skills_content"
			fi
		else
			add_change "create" "$skills_hook_path" "" "$skills_content"
		fi
	fi
}
