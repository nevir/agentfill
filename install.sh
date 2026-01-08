#!/bin/sh
set -e

VERSION="1.0.0"

SUPPORTED_AGENTS="claude gemini"

# ============================================
# Colors
# ============================================

color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_blue='\033[0;34m'
color_purple='\033[0;35m'
color_cyan='\033[0;36m'
color_bold='\033[1m'
color_reset='\033[0m'

# Semantic colors
color_error="$color_red"
color_success="$color_green"
color_warning="$color_yellow"
color_heading="$color_bold"
color_agent="$color_cyan"
color_flag="$color_purple"
color_path="$color_yellow"

c() {
	local color_name="$1"; shift
	local text="$*"
	local var_name
	local color_code

	var_name="color_$color_name"
	eval "color_code=\$$var_name"

	printf "%s%s%s" "$color_code" "$text" "$color_reset"
}

c_list() {
	local color_type="$1"
	shift
	local result=""
	local first=1

	for item in "$@"; do
		[ $first -eq 0 ] && result="$result, "
		result="$result$(c "$color_type" "$item")"
		first=0
	done

	echo "$result"
}

# ============================================
# Utilities
# ============================================

list_contains() {
	local item="$1"
	local list="$2"
	for list_item in $list; do
		[ "$item" = "$list_item" ] && return 0
	done
	return 1
}

trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}

panic() {
	local exit_code="$1"
	shift
	local show_usage=0
	local message

	if [ "$1" = "show_usage" ]; then
		show_usage=1
		shift
	fi

	if [ $# -gt 0 ]; then
		message="$*"
	else
		message=$(cat)
	fi

	printf "\n$(c error Error:) $(trim "$message")\n" >&2

	if [ "$show_usage" -eq 1 ]; then
		printf "\n$(usage)\n" >&2
	fi

	printf "\n" >&2
	exit "$exit_code"
}

# ============================================
# Tool detection
# ============================================

check_perl() {
	if ! command -v perl >/dev/null 2>&1; then
		panic 2 "Perl is required but not found. Please install perl."
	fi

	if ! perl -MJSON::PP -e 1 2>/dev/null; then
		panic 2 "Perl JSON::PP module is required but not found."
	fi
}

# ============================================
# JSON operations (Perl)
# ============================================

json_merge_deep() {
	local file="$1"
	local merge_json="$2"
	local temp_file="/tmp/json_merge_tmp_$$_$(date +%s)"

	cat "$file" | perl -MJSON::PP -0777 -e '
my $json = JSON::PP->new->utf8->relaxed->pretty->canonical;
my $base = $json->decode(do { local $/; <STDIN> });
my $merge = $json->decode(q{'"$merge_json"'});
my $base_json = $json->encode($base);

sub merge_recursive {
	my ($base, $merge) = @_;

	if (ref $merge eq "HASH") {
		$base = {} unless ref $base eq "HASH";
		for my $key (keys %$merge) {
			$base->{$key} = merge_recursive($base->{$key}, $merge->{$key});
		}
		return $base;
	} elsif (ref $merge eq "ARRAY") {
		$base = [] unless ref $base eq "ARRAY";
		# For arrays, merge unique elements
		my %seen;
		my @result;
		for my $item (@$base, @$merge) {
			my $key = ref $item ? $json->encode($item) : $item;
			push @result, $item unless $seen{$key}++;
		}
		return \@result;
	} else {
		return $merge;
	}
}

my $result = merge_recursive($base, $merge);
my $result_json = $json->encode($result);

print $result_json;
exit($base_json eq $result_json ? 0 : 1);
' > "$temp_file"

	local exit_code=$?
	mv "$temp_file" "$file"
	return $exit_code
}

# ============================================
# YAML operations (simple line-based)
# ============================================

yaml_has_section() {
	local file="$1"
	local section="$2"

	grep -q "^${section}:" "$file" 2>/dev/null
}

yaml_has_item() {
	local file="$1"
	local section="$2"
	local item="$3"

	if ! yaml_has_section "$file" "$section"; then
		return 1
	fi

	grep -A 999 "^${section}:" "$file" | grep -q "^  - ${item}\$"
}

yaml_add_section_with_items() {
	local file="$1"
	local section="$2"
	shift 2
	local items="$*"

	{
		echo ""
		echo "${section}:"
		for item in $items; do
			echo "  - $item"
		done
	} >> "$file"
}

yaml_add_item() {
	local file="$1"
	local section="$2"
	local item="$3"
	local temp_file="${file}.tmp.$$"

	perl -i -pe <<-end_perl "$file"
		BEGIN { \$section = q{$section}; \$item = q{$item}; \$added = 0; }
		if (/^\$section:/) { \$in_section = 1; }
		if (\$in_section && /^[a-z]/) {
			print "  - \$item\\n" unless \$added;
			\$added = 1;
			\$in_section = 0;
		}
		END { print "  - \$item\\n" if \$in_section && !\$added; }
	end_perl
}

# ============================================
# File templates
# ============================================

template_agents_md() {
	cat <<-'end_template'
		# AGENTS.md

		This file provides context and instructions for AI coding agents.
		Add your project-specific instructions here.

		Learn more: https://agents.md
	end_template
}

template_gemini_settings() {
	cat <<-'end_template'
		{
		  "context": {
		    "fileName": ["AGENTS.md", "GEMINI.md"]
		  }
		}
	end_template
}

template_claude_settings() {
	cat <<-'end_template'
		{
		  "hooks": {
		    "SessionStart": [
		      {
		        "matcher": "startup",
		        "hooks": [
		          {
		            "type": "command",
		            "command": "$CLAUDE_PROJECT_DIR/.agents/polyfills/claude_agentsmd.sh"
		          }
		        ]
		      }
		    ]
		  }
		}
	end_template
}

template_claude_hook() {
	cat <<-'end_template'
		#!/bin/sh

		# This project is licensed under the [Blue Oak Model License, Version 1.0.0][1],
		# but you may also license it under [Apache License, Version 2.0][2] if you—
		# or your legal team—prefer.
		# [1]: https://blueoakcouncil.org/license/1.0.0
		# [2]: https://www.apache.org/licenses/LICENSE-2.0

		cd "$CLAUDE_PROJECT_DIR"
		agent_files=$(find . -name "AGENTS.md" -type f)
		[ -z "$agent_files" ] && exit 0

		cat <<end_context
		<agentsmd_instructions>
		This project uses AGENTS.md files to provide scoped instructions based on the
		file or directory being worked on.

		This project has the following AGENTS.md files:

		<available_agentsmd_files>
		$agent_files
		</available_agentsmd_files>

		NON-NEGOTIABLE: When working with any file or directory within the project:

		1. Load ALL AGENTS.md files in the directory hierarchy matching that location.
		   You do not have to reload AGENTS.md files you have already loaded previously.

		2. ALWAYS apply instructions from the AGENTS.md files that match that location.
		   When there are conflicting instructions, apply instructions from the
		   AGENTS.md file that is CLOSEST (most specific) to that location. More
		   specific instructions OVERRIDE more general ones.

		   <example>
		     Project structure:
		       AGENTS.md
		       subfolder/
		         file.txt
		         AGENTS.md

		     When working with "subfolder/file.txt":
		       - Instructions from "subfolder/AGENTS.md" take precedence
		       - Instructions from root "AGENTS.md" apply only if not overridden
		   </example>

		3. If there is a root ./AGENTS.md file, ALWAYS apply its instructions to ALL
		   work within the project, as everything you do is within scope of the project.
		   Precedence rules still apply for conflicting instructions.
		</agentsmd_instructions>
		end_context

		# If there is a root AGENTS.md, load it now because it always applies.
		if [ -f "./AGENTS.md" ]; then
			cat <<-end_root_context

				The content of ./AGENTS.md is as follows:

				<root_agentsmd>
				$(cat "./AGENTS.md")
				</root_agentsmd>
			end_root_context
		fi
	end_template
}

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
	echo "$content" > "$content_file"
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

trap cleanup_change_files EXIT

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
			create)
				printf "  $(c success CREATE)  $file"
				;;
			modify)
				printf "  $(c warning MODIFY)  $file"
				;;
			skip)
				printf "  $(c blue SKIP)    $file"
				;;
		esac

		[ -n "$desc" ] && printf " $(c blue "($desc)")"
		printf "\n"

		i=$((i + 1))
	done

	printf "\n"
}

ask_confirmation() {
	local response
	printf "Apply these changes? [y/N]: "
	read -r response

	case "$response" in
		[yY]|[yY][eE][sS])
			return 0
			;;
		*)
			return 1
			;;
	esac
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

plan_agents_md() {
	if [ -f "AGENTS.md" ]; then
		add_change "skip" "AGENTS.md" "already exists" ""
	else
		add_change "create" "AGENTS.md" "placeholder" "$(template_agents_md)"
	fi
}

plan_gemini() {
	plan_json \
		".gemini/settings.json" \
		"$(template_gemini_settings)" \
		"add AGENTS.md to context"
}

plan_claude() {
	plan_json \
		".claude/settings.json" \
		"$(template_claude_settings)" \
		"add AGENTS.md hook"

	local polyfill_path=".agents/polyfills/claude_agentsmd.sh"
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
}

# ============================================
# Apply changes
# ============================================

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
	printf "  $(c agent AGENTS...)        Agent names to configure (default: all)\n"
	printf "                   Valid agents: $(c_list agent $SUPPORTED_AGENTS)\n\n"

	printf "$(c heading Options:)\n"
	printf "  $(c flag -h), $(c flag --help)       Show this help message\n"
	printf "  $(c flag -y), $(c flag --yes)        Auto-confirm (skip confirmation prompt)\n"
	printf "  $(c flag -n), $(c flag --dry-run)    Show plan only, don't apply changes\n\n"

	printf "$(c heading Examples:)\n"
	printf "  install.sh                      # All agents, current directory\n"
	printf "  install.sh $(c agent claude)               # Only Claude, current directory\n"
	printf "  install.sh $(c path /path/to/project)     # All agents, specific directory\n"
	printf "  install.sh $(c path .) $(c agent claude) $(c agent gemini)      # Claude and Gemini in current directory\n"
	printf "  install.sh $(c flag -y) $(c agent claude)            # Auto-confirm, Claude only\n"
	printf "  install.sh $(c flag -n)                   # Dry-run, all agents\n\n"
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
			case "$first_arg" in
				*/*|.|..)
					project_dir="$first_arg"
					shift
					agents="$*"
					;;
				*)
					panic 2 "Unknown agent: $(c agent "'$first_arg'") (valid agents: $(c_list agent $SUPPORTED_AGENTS))"
					;;
			esac
		fi
	fi

	local enabled_agents=""

	if [ -z "$agents" ]; then
		enabled_agents="$SUPPORTED_AGENTS"
	else
		for agent in $agents; do
			if ! list_contains "$agent" "$SUPPORTED_AGENTS"; then
				panic 2 "Unknown agent: $(c agent "'$agent'") (valid agents: $(c_list agent $SUPPORTED_AGENTS))"
			fi
			enabled_agents="$enabled_agents $agent"
		done
		enabled_agents=$(trim "$enabled_agents")
	fi

	check_perl

	cd "$project_dir" || panic 2 "Cannot access directory: $(c path "'$project_dir'")"

	printf "\n$(c heading '=== AGENTS.md Polyfill Installer ===')\n"
	printf "Version: $VERSION\n"
	printf "Project: $(pwd)\n\n"

	plan_agents_md
	for agent in $SUPPORTED_AGENTS; do
		if list_contains "$agent" "$enabled_agents"; then
			eval "plan_$agent"
		fi
	done

	display_ledger

	if [ "$dry_run" = true ]; then
		printf "$(c warning 'Dry-run mode - no changes applied')\n\n"
		exit 0
	fi

	if [ "$auto_confirm" = false ]; then
		if ! ask_confirmation; then
			printf "\n$(c warning 'Installation cancelled')\n\n"
			exit 0
		fi
	fi

	printf "\n$(c heading 'Applying changes...')\n\n"
	apply_changes

	printf "\n$(c success '✓ Installation complete!')\n\n"

	printf "$(c heading 'Next steps:')\n"
	printf "  1. Edit AGENTS.md with your project instructions\n"
	printf "  2. Test with your AI agent\n"
	printf "  3. Learn more: https://agents.md\n\n"
}

main "$@"
