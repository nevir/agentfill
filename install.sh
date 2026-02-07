#!/bin/sh
set -e

VERSION="1.0.0"

SUPPORTED_AGENTS="claude cursor gemini"

# Installation modes
INSTALL_MODE="project"  # project, local, or global
INSTALL_LEVEL="full"    # none, config, or full

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
color_option="$color_blue"

c() {
	local color_name="$1"; shift
	local text="$*"

	# Short-circuit if colors are disabled
	if [ "${DISABLE_COLORS:-0}" -eq 1 ]; then
		printf "%s" "$text"
		return
	fi

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

# Convert agent name to valid shell function name (e.g. some-agent -> some_agent)
func_name() {
	echo "$1" | tr '-' '_'
}

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

# Get the CLI binary name for detecting an agent
agent_detect_binary() {
	echo "$1"
}

detect_installed_agents() {
	local installed=""
	for agent in $SUPPORTED_AGENTS; do
		local binary
		binary=$(agent_detect_binary "$agent")
		if command -v "$binary" >/dev/null 2>&1; then
			installed="$installed $agent"
		fi
	done
	trim "$installed"
}

prompt_agent_selection() {
	printf "\n$(c heading 'Select agents to configure:')\n\n" >&2
	printf "  $(c agent claude)      - Claude Code\n" >&2
	printf "  $(c agent cursor)      - Cursor\n" >&2
	printf "  $(c agent gemini)      - Gemini CLI\n" >&2
	printf "\n" >&2
	printf "Enter agent names (space-separated), or $(c option all) for all: " >&2
	read -r response

	response=$(trim "$response")
	case "$response" in
		""|all|All|ALL) echo "$SUPPORTED_AGENTS" ;;
		*)              echo "$response" ;;
	esac
}

select_agents() {
	local installed
	installed=$(detect_installed_agents)

	if [ -n "$installed" ]; then
		printf "\n$(c heading 'Detected installed agents:') $(c_list agent $installed)\n\n" >&2
		printf "Install for these agents? [Y/n/select]: " >&2
		read -r confirm

		confirm=$(trim "$confirm")
		case "$confirm" in
			""|[yY]|[yY][eE][sS]) echo "$installed" ;;
			[nN]|[nN][oO])        exit 0 ;;
			*)                    prompt_agent_selection ;;
		esac
	else
		printf "\n$(c warning 'No supported agents detected on this system.')\n" >&2
		prompt_agent_selection
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

# ============================================
# File templates
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

template_claude_settings() {
	# Config level: empty settings (no hooks)
	if [ "$INSTALL_LEVEL" = "config" ]; then
		cat <<-'end_template'
			{
			}
		end_template
		return
	fi

	# Full level: includes hooks
	local polyfill_path=$(polyfill_reference_path "claude" "agentsmd/claude.sh")

	# Global mode also includes the skills hook
	if [ "$INSTALL_MODE" = "global" ]; then
		local skills_hook_path=$(polyfill_reference_path "claude" "skills/claude.sh")
		cat <<-end_template
			{
			  "hooks": {
			    "SessionStart": [
			      {
			        "matcher": "startup",
			        "hooks": [
			          {
			            "type": "command",
			            "command": "$polyfill_path"
			          },
			          {
			            "type": "command",
			            "command": "$skills_hook_path"
			          }
			        ]
			      }
			    ]
			  }
			}
		end_template
	else
		cat <<-end_template
			{
			  "hooks": {
			    "SessionStart": [
			      {
			        "matcher": "startup",
			        "hooks": [
			          {
			            "type": "command",
			            "command": "$polyfill_path"
			          }
			        ]
			      }
			    ]
			  }
			}
		end_template
	fi
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

		# Check for global AGENTS.md if global install exists
		# Detection: check if universal-agents is installed globally by checking for global polyfill directory
		has_global_agentsmd=0
		if [ -d "$HOME/.agents/polyfills" ] && [ -f "$HOME/AGENTS.md" ]; then
			has_global_agentsmd=1
			# Add to list if we have project files
			if [ -n "$agent_files" ]; then
				agent_files="$HOME/AGENTS.md
		$agent_files"
			else
				agent_files="$HOME/AGENTS.md"
			fi
		fi

		# Exit if no AGENTS.md files found
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

		1. Load ALL AGENTS.md files in the directory hierarchy matching that location
		   BEFORE you start working on (reading/writing/etc) the file or directory. You
		   do not have to reload AGENTS.md files you have already loaded previously.

		2. ALWAYS apply instructions from the AGENTS.md files that match that location.
		   When there are conflicting instructions, apply instructions from the
		   AGENTS.md file that is CLOSEST (most specific) to that location. More
		   specific instructions OVERRIDE more general ones.

		   Precedence order (from lowest to highest priority):
		   - Global AGENTS.md (~/AGENTS.md) - lowest priority
		   - Project root AGENTS.md (./AGENTS.md)
		   - Nested AGENTS.md files - highest priority (closest to the file)

		   <example>
		     Project structure:
		       ~/AGENTS.md          (global)
		       ./AGENTS.md               (project root)
		       subfolder/
		         file.txt
		         AGENTS.md               (nested)

		     When working with "subfolder/file.txt":
		       - Instructions from "subfolder/AGENTS.md" take highest precedence
		       - Instructions from "./AGENTS.md" override global
		       - Instructions from "~/AGENTS.md" apply only if not overridden
		   </example>

		3. If there is a root ./AGENTS.md file, ALWAYS apply its instructions to ALL
		   work within the project, as everything you do is within scope of the project.
		   Precedence rules still apply for conflicting instructions.
		</agentsmd_instructions>
		end_context

		# Load global AGENTS.md first (lowest precedence)
		if [ "$has_global_agentsmd" -eq 1 ]; then
			cat <<-end_global_context

				The content of ~/AGENTS.md is as follows:

				<agentsmd path="~/AGENTS.md" absolute_path="$HOME/AGENTS.md">
				$(cat "$HOME/AGENTS.md")
				</agentsmd>
			end_global_context
		fi

		# If there is a root AGENTS.md, load it now (higher precedence than global)
		if [ -f "./AGENTS.md" ]; then
			cat <<-end_root_context

				The content of ./AGENTS.md is as follows:

				<agentsmd path="./AGENTS.md" absolute_path="$CLAUDE_PROJECT_DIR/AGENTS.md">
				$(cat "./AGENTS.md")
				</agentsmd>
			end_root_context
		fi
	end_template
}

template_claude_skills_hook() {
	cat <<-'end_template'
		#!/bin/sh

		# Skills symlink hook for Claude (global install)
		# Creates symlinks to .agents/skills/ on-demand per project

		PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
		TARGET="$PROJECT_DIR/.claude/skills"

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
		mkdir -p "$PROJECT_DIR/.claude"
		ln -s "$SOURCE" "$TARGET"

		# Instruct user to restart (skills discovered before hook runs)
		cat <<-end_message
		<skills_setup>
		Skills symlink created. Please restart Claude to discover skills in this project.
		</skills_setup>
		end_message
	end_template
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

template_cursor_hooks() {
	# Config level: no hooks
	if [ "$INSTALL_LEVEL" = "config" ]; then
		cat <<-'end_template'
			{
			  "version": 1,
			  "hooks": {}
			}
		end_template
		return
	fi

	local polyfill_path=$(polyfill_reference_path "cursor" "agentsmd/cursor.sh")

	# Global mode also includes the skills hook
	if [ "$INSTALL_MODE" = "global" ]; then
		local skills_hook_path=$(polyfill_reference_path "cursor" "skills/cursor.sh")
		cat <<-end_template
			{
			  "version": 1,
			  "hooks": {
			    "sessionStart": [
			      {
			        "command": "$polyfill_path"
			      },
			      {
			        "command": "$skills_hook_path"
			      }
			    ]
			  }
			}
		end_template
	else
		cat <<-end_template
			{
			  "version": 1,
			  "hooks": {
			    "sessionStart": [
			      {
			        "command": "$polyfill_path"
			      }
			    ]
			  }
			}
		end_template
	fi
}

template_cursor_hook() {
	cat <<-'end_template'
		#!/bin/sh

		# This project is licensed under the [Blue Oak Model License, Version 1.0.0][1],
		# but you may also license it under [Apache License, Version 2.0][2] if you—
		# or your legal team—prefer.
		# [1]: https://blueoakcouncil.org/license/1.0.0
		# [2]: https://www.apache.org/licenses/LICENSE-2.0

		# Cursor IDE sessionStart hook for AGENTS.md polyfill
		# Outputs JSON with additional_context for context injection

		PROJECT_DIR="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
		cd "$PROJECT_DIR"
		agent_files=$(find . -name "AGENTS.md" -type f)

		# Check for global AGENTS.md if global install exists
		has_global_agentsmd=0
		if [ -d "$HOME/.agents/polyfills" ] && [ -f "$HOME/AGENTS.md" ]; then
			has_global_agentsmd=1
			if [ -n "$agent_files" ]; then
				agent_files="$HOME/AGENTS.md
		$agent_files"
			else
				agent_files="$HOME/AGENTS.md"
			fi
		fi

		# If no AGENTS.md files found, output minimal JSON and exit
		if [ -z "$agent_files" ]; then
			printf '{"continue":true}\n'
			exit 0
		fi

		# Build the context string
		context="<agentsmd_instructions>
		This project uses AGENTS.md files to provide scoped instructions based on the
		file or directory being worked on.

		This project has the following AGENTS.md files:

		<available_agentsmd_files>
		$agent_files
		</available_agentsmd_files>

		NON-NEGOTIABLE: When working with any file or directory within the project:

		1. Load ALL AGENTS.md files in the directory hierarchy matching that location
		   BEFORE you start working on (reading/writing/etc) the file or directory. You
		   do not have to reload AGENTS.md files you have already loaded previously.

		2. ALWAYS apply instructions from the AGENTS.md files that match that location.
		   When there are conflicting instructions, apply instructions from the
		   AGENTS.md file that is CLOSEST (most specific) to that location. More
		   specific instructions OVERRIDE more general ones.

		   Precedence order (from lowest to highest priority):
		   - Global AGENTS.md (~/AGENTS.md) - lowest priority
		   - Project root AGENTS.md (./AGENTS.md)
		   - Nested AGENTS.md files - highest priority (closest to the file)

		   <example>
		     Project structure:
		       ~/AGENTS.md          (global)
		       ./AGENTS.md               (project root)
		       subfolder/
		         file.txt
		         AGENTS.md               (nested)

		     When working with \"subfolder/file.txt\":
		       - Instructions from \"subfolder/AGENTS.md\" take highest precedence
		       - Instructions from \"./AGENTS.md\" override global
		       - Instructions from \"~/AGENTS.md\" apply only if not overridden
		   </example>

		3. If there is a root ./AGENTS.md file, ALWAYS apply its instructions to ALL
		   work within the project, as everything you do is within scope of the project.
		   Precedence rules still apply for conflicting instructions.
		</agentsmd_instructions>"

		# Append global AGENTS.md content (lowest precedence)
		if [ "$has_global_agentsmd" -eq 1 ]; then
			context="$context

		The content of ~/AGENTS.md is as follows:

		<agentsmd path=\"~/AGENTS.md\" absolute_path=\"$HOME/AGENTS.md\">
		$(cat "$HOME/AGENTS.md")
		</agentsmd>"
		fi

		# Append root AGENTS.md content (higher precedence than global)
		if [ -f "./AGENTS.md" ]; then
			context="$context

		The content of ./AGENTS.md is as follows:

		<agentsmd path=\"./AGENTS.md\" absolute_path=\"$PROJECT_DIR/AGENTS.md\">
		$(cat "./AGENTS.md")
		</agentsmd>"
		fi

		# JSON-encode the context and output the hook response
		printf '%s' "$context" | perl -MJSON::PP -0777 -e '
			my $text = do { local $/; <STDIN> };
			my $json = JSON::PP->new->utf8;
			print $json->encode({
				additional_context => $text,
				continue => JSON::PP::true
			});
		'
	end_template
}

template_cursor_skills_hook() {
	cat <<-'end_template'
		#!/bin/sh

		# Skills symlink hook for Cursor IDE (global install)
		# Creates symlinks to .agents/skills/ on-demand per project

		PROJECT_DIR="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
		TARGET="$PROJECT_DIR/.cursor/skills"

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
		mkdir -p "$PROJECT_DIR/.cursor"
		ln -s "$SOURCE" "$TARGET"

		echo "Created skills symlink: $TARGET -> $SOURCE" >&2
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

ask_confirmation() {
	local response
	printf "Apply these changes? [y/N]: "
	read -r response

	case "$response" in
		[yY]|[yY][eE][sS]) return 0 ;;
		*)                 return 1 ;;
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

	local enabled_agents=""

	if [ -z "$agents" ]; then
		# No agents specified - use interactive selection if available
		if [ "$auto_confirm" = false ] && [ -t 0 ]; then
			enabled_agents=$(select_agents)
			enabled_agents=$(trim "$enabled_agents")
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

	check_perl

	cd "$project_dir" || panic 2 "Cannot access directory: $(c path "'$project_dir'")"

	# Prompt for installation location if not specified and not auto-confirm
	if [ "$INSTALL_MODE" = "project" ] && [ "$auto_confirm" = false ] && [ -t 0 ]; then
		printf "\n$(c heading 'Installation location:')\n\n"
		printf "  $(c option 1)) $(c option Project) - .claude/settings.json (shared, tracked in git)\n"
		printf "  $(c option 2)) $(c option Global)  - ~/.claude/settings.json (user home, all projects)\n"
		printf "\n"
		printf "Choice [$(c option 1)]: "
		read -r choice

		choice=$(trim "${choice:-1}")
		case "$choice" in
			1|project|Project) INSTALL_MODE="project" ;;
			2|global|Global)   INSTALL_MODE="global" ;;
			*) panic 2 "Invalid choice: $choice" ;;
		esac
		printf "\n"
	fi

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

	if [ "$auto_confirm" = false ]; then
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

main "$@"
