#!/bin/sh
set -e

VERSION="1.0.0"

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

# ============================================
# Utilities
# ============================================

trim() {
	local var="$1"
	var="${var#"${var%%[![:space:]]*}"}"
	var="${var%"${var##*[![:space:]]}"}"
	echo "$var"
}

indent() {
	local spaces="$1"
	local text="$2"
	echo "$text" | while IFS= read -r line; do
		printf "%${spaces}s%s\n" "" "$line"
	done
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

json_set() {
	local file="$1"
	local key_path="$2"
	local value_json="$3"
	local temp_file="/tmp/json_set_tmp_$$_$(date +%s)"

	cat "$file" | perl -MJSON::PP -0777 -e '
my $json = JSON::PP->new->utf8->relaxed->pretty->canonical;
my $data = $json->decode(do { local $/; <STDIN> });
my $value = $json->decode(q{'"$value_json"'});

my @keys = split /\./, q{'"$key_path"'};
my $ref = $data;
$ref = ($ref->{$_} //= {}) for @keys[0..$#keys-1];

my $last = $keys[-1];
if (ref $ref->{$last} eq "ARRAY" && ref $value eq "ARRAY") {
	my %seen;
	$ref->{$last} = [grep { !$seen{$_}++ } (@{$ref->{$last}}, @$value)];
} else {
	$ref->{$last} = $value;
}

print $json->encode($data);
' > "$temp_file"

	mv "$temp_file" "$file"
}

json_has_value() {
	local file="$1"
	local key_path="$2"
	local search_value="$3"

	cat "$file" | perl -MJSON::PP -0777 -e '
my $json = JSON::PP->new->utf8->relaxed;
my $data = $json->decode(do { local $/; <STDIN> });

my @keys = split /\./, q{'"$key_path"'};
my $ref = $data;

# Navigate to key, return false if path does not exist
for my $key (@keys) {
	if (ref $ref eq "HASH" && exists $ref->{$key}) {
		$ref = $ref->{$key};
	} else {
		print "false";
		exit 0;
	}
}

if (ref $ref eq "ARRAY") {
	print((grep { $_ eq q{'"$search_value"'} } @$ref) ? "true" : "false");
} elsif (defined $ref && $ref eq q{'"$search_value"'}) {
	print "true";
} else {
	print "false";
}
'
}

json_create() {
	local file="$1"
	local content="$2"

	echo "$content" | perl -MJSON::PP -0777 -e '
my $json = JSON::PP->new->utf8->pretty->canonical;
my $data = $json->decode(do { local $/; <STDIN> });
print $json->encode($data);
' > "$file"
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

template_aider_conf() {
	cat <<-'end_template'
		# Aider configuration file
		# This configures Aider to automatically read AGENTS.md before each session

		read:
		  - AGENTS.md
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

template_claude_md() {
	cat <<-'end_template'
		@AGENTS.md
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
		            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/polyfill_agentsmd.sh"
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

plan_agents_md() {
	if [ -f "AGENTS.md" ]; then
		add_change "skip" "AGENTS.md" "already exists" ""
	else
		add_change "create" "AGENTS.md" "placeholder" "$(template_agents_md)"
	fi
}

plan_aider() {
	if [ -f ".aider.conf.yml" ]; then
		if yaml_has_item ".aider.conf.yml" "read" "AGENTS.md"; then
			add_change "skip" ".aider.conf.yml" "already configured" ""
		else
			# Need to add AGENTS.md to read list
			local current_content=$(cat ".aider.conf.yml")
			# For now, mark as skip and show manual instructions
			add_change "skip" ".aider.conf.yml" "needs manual update: add 'AGENTS.md' to read list" ""
		fi
	else
		add_change "create" ".aider.conf.yml" "" "$(template_aider_conf)"
	fi
}

plan_gemini() {
	if [ -f ".gemini/settings.json" ]; then
		local has_value=$(json_has_value ".gemini/settings.json" "context.fileName" "AGENTS.md")
		if [ "$has_value" = "true" ]; then
			add_change "skip" ".gemini/settings.json" "already configured" ""
		else
			# Need to add AGENTS.md to context.fileName array
			# Create modified version
			local temp_file="/tmp/gemini_settings_tmp_$$"
			cp ".gemini/settings.json" "$temp_file"
			json_set "$temp_file" "context.fileName" '["AGENTS.md", "GEMINI.md"]'
			local new_content=$(cat "$temp_file")
			rm -f "$temp_file"

			add_change "modify" ".gemini/settings.json" "add AGENTS.MD to context" "$new_content"
		fi
	else
		# Create directory and file
		add_change "create" ".gemini/settings.json" "" "$(template_gemini_settings)"
	fi
}

plan_claude() {
	# Always use SessionStart hook approach for proper AGENTS.md inheritance
	if [ -f ".claude/settings.json" ]; then
		add_change "skip" ".claude/settings.json" "needs manual update for hook" ""
	else
		add_change "create" ".claude/settings.json" "" "$(template_claude_settings)"
	fi

	if [ -f ".claude/hooks/polyfill_agentsmd.sh" ]; then
		add_change "skip" ".claude/hooks/polyfill_agentsmd.sh" "already exists" ""
	else
		add_change "create" ".claude/hooks/polyfill_agentsmd.sh" "" "$(template_claude_hook)"
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
				# Create parent directory if needed
				local dir=$(dirname "$file")
				[ "$dir" != "." ] && mkdir -p "$dir"

				# Write content
				cat "$content_file" > "$file"

				# Make executable if it's a hook script
				case "$file" in
					*.sh) chmod +x "$file" ;;
				esac

				printf "$(c success ✓) Created $file\n"
				;;
			modify)
				# Backup original
				cp "$file" "${file}.backup.$(date +%s)"

				# Write new content
				cat "$content_file" > "$file"

				printf "$(c success ✓) Modified $file\n"
				;;
			skip)
				# Nothing to do
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
	printf "  $(c path PATH)                Project directory (default: current directory)\n"
	printf "  $(c agent AGENTS...)           Agent names to configure (default: all)\n"
	printf "                      Valid agents: $(c agent aider), $(c agent gemini), $(c agent claude)\n\n"

	printf "$(c heading Options:)\n"
	printf "  $(c flag -h), $(c flag --help)          Show this help message\n"
	printf "  $(c flag -y), $(c flag --yes)           Auto-confirm (skip confirmation prompt)\n"
	printf "  $(c flag -n), $(c flag --dry-run)       Show plan only, don't apply changes\n\n"

	printf "$(c heading Examples:)\n"
	printf "  install.sh                           # All agents, current directory\n"
	printf "  install.sh $(c agent aider)                       # Only Aider, current directory\n"
	printf "  install.sh $(c path /path/to/project)            # All agents, specific directory\n"
	printf "  install.sh $(c path .) $(c agent aider) $(c agent gemini)              # Aider and Gemini in current directory\n"
	printf "  install.sh $(c flag -y) $(c agent aider)                    # Auto-confirm, Aider only\n"
	printf "  install.sh $(c flag -n)                          # Dry-run, all agents\n\n"
}

# ============================================
# Main
# ============================================

main() {
	# Parse arguments
	local auto_confirm=false
	local dry_run=false
	local project_dir="."
	local agents=""
	local positional_args=""

	# First pass: collect flags and positional args
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

	# Parse positional arguments: [path] [agents...]
	positional_args=$(trim "$positional_args")
	if [ -n "$positional_args" ]; then
		set -- $positional_args
		local first_arg="$1"

		# Check if first arg is a valid agent name
		case "$first_arg" in
			aider|gemini|claude)
				# It's an agent name - check for ambiguity
				if [ -e "$first_arg" ]; then
					panic 2 <<-end_panic
						Ambiguous argument: $(c agent "'$first_arg'")
						This is both a valid agent name AND an existing path.
						Please rename the file/directory or use an explicit path like $(c path "'./$first_arg'")
					end_panic
				fi
				# All args are agents
				agents="$positional_args"
				;;
			*)
				# First arg might be a path - validate it exists if it looks like a path
				# Otherwise, treat as invalid agent name
				if [ -e "$first_arg" ] || [ "$first_arg" = "." ] || [ "$first_arg" = ".." ] || echo "$first_arg" | grep -q "/"; then
					# It's a path (exists or looks like a path with /)
					project_dir="$first_arg"
					shift
					# Remaining args are agents
					agents="$*"
				else
					# Doesn't exist and doesn't look like a path - must be invalid agent
					panic 2 "Unknown agent: $(c agent "'$first_arg'") (valid agents: $(c agent aider), $(c agent gemini), $(c agent claude))"
				fi
				;;
		esac
	fi

	# Determine which agents to skip
	local skip_aider=true
	local skip_gemini=true
	local skip_claude=true

	if [ -z "$agents" ]; then
		# No agents specified - enable all
		skip_aider=false
		skip_gemini=false
		skip_claude=false
	else
		# Enable only specified agents
		for agent in $agents; do
			case "$agent" in
				aider)
					skip_aider=false
					;;
				gemini)
					skip_gemini=false
					;;
				claude)
					skip_claude=false
					;;
				*)
					panic 2 "Unknown agent: $(c agent "'$agent'") (valid agents: $(c agent aider), $(c agent gemini), $(c agent claude))"
					;;
			esac
		done
	fi

	# Check requirements
	check_perl

	# Change to project directory
	cd "$project_dir" || panic 2 "Cannot access directory: $(c path "'$project_dir'")"

	# Welcome
	printf "\n$(c heading '=== AGENTS.md Polyfill Installer ===')\n"
	printf "Version: $VERSION\n"
	printf "Project: $(pwd)\n\n"

	# Plan changes
	plan_agents_md
	[ "$skip_aider" = false ] && plan_aider
	[ "$skip_gemini" = false ] && plan_gemini
	[ "$skip_claude" = false ] && plan_claude

	# Display ledger
	display_ledger

	# Dry run?
	if [ "$dry_run" = true ]; then
		printf "$(c warning 'Dry-run mode - no changes applied')\n\n"
		exit 0
	fi

	# Confirm
	if [ "$auto_confirm" = false ]; then
		if ! ask_confirmation; then
			printf "\n$(c warning 'Installation cancelled')\n\n"
			exit 0
		fi
	fi

	# Apply changes
	printf "\n$(c heading 'Applying changes...')\n\n"
	apply_changes

	# Success
	printf "\n$(c success '✓ Installation complete!')\n\n"

	printf "$(c heading 'Next steps:')\n"
	printf "  1. Edit AGENTS.md with your project instructions\n"
	printf "  2. Test with your AI agent\n"
	printf "  3. Learn more: https://agents.md\n\n"
}

main "$@"
