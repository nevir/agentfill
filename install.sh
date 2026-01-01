#!/bin/sh
set -e

VERSION="1.0.0"

# ============================================
# Color codes (borrowed from tests/test.sh)
# ============================================

color_red='\033[0;31m'
color_green='\033[0;32m'
color_yellow='\033[0;33m'
color_blue='\033[0;34m'
color_cyan='\033[0;36m'
color_bold='\033[1m'
color_reset='\033[0m'

color_error="$color_red"
color_success="$color_green"
color_warning="$color_yellow"
color_heading="$color_bold"

# ============================================
# Utility functions (borrowed from tests/test.sh)
# ============================================

c() {
  local color_name="$1"; shift
  local text="$*"
  local var_name
  local color_code

  var_name="color_$color_name"
  eval "color_code=\$$var_name"

  printf "%s%s%s" "$color_code" "$text" "$color_reset"
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

indent() {
  local spaces="$1"
  local text="$2"
  echo "$text" | while IFS= read -r line; do
    printf "%${spaces}s%s\n" "" "$line"
  done
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

  KEY_PATH="$key_path" VALUE_JSON="$value_json" \
  cat "$file" | perl -MJSON::PP -0777 /dev/fd/3 3<<-'PERLCODE' > "$temp_file"
		my $json = JSON::PP->new->utf8->relaxed->pretty->canonical;
		my $data = $json->decode(do { local $/; <STDIN> });
		my $value = $json->decode($ENV{VALUE_JSON});

		my @keys = split /\./, $ENV{KEY_PATH};
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
	PERLCODE

  mv "$temp_file" "$file"
}

json_has_value() {
  local file="$1"
  local key_path="$2"
  local search_value="$3"

  KEY_PATH="$key_path" SEARCH_VALUE="$search_value" \
  cat "$file" | perl -MJSON::PP -0777 /dev/fd/3 3<<-'PERLCODE'
		my $json = JSON::PP->new->utf8->relaxed;
		my $data = $json->decode(do { local $/; <STDIN> });

		my @keys = split /\./, $ENV{KEY_PATH};
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
		  print((grep { $_ eq $ENV{SEARCH_VALUE} } @$ref) ? "true" : "false");
		} elsif (defined $ref && $ref eq $ENV{SEARCH_VALUE}) {
		  print "true";
		} else {
		  print "false";
		}
	PERLCODE
}

json_create() {
  local file="$1"
  local content="$2"

  echo "$content" | perl -MJSON::PP -0777 /dev/fd/3 3<<-'PERLCODE' > "$file"
		my $json = JSON::PP->new->utf8->pretty->canonical;
		my $data = $json->decode(do { local $/; <STDIN> });
		print $json->encode($data);
	PERLCODE
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
  cat <<'EOF'
# AGENTS.md

This file provides context and instructions for AI coding agents.
Add your project-specific instructions here.

Learn more: https://agents.md
EOF
}

template_aider_conf() {
  cat <<'EOF'
# Aider configuration file
# This configures Aider to automatically read AGENTS.md before each session

read:
  - AGENTS.md
EOF
}

template_gemini_settings() {
  cat <<'EOF'
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
EOF
}

template_claude_md() {
  cat <<'EOF'
# In ./CLAUDE.md

@AGENTS.md
EOF
}

template_claude_settings() {
  cat <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/append_agentsmd_context.sh"
          }
        ]
      }
    ]
  }
}
EOF
}

template_claude_hook() {
  cat <<'EOF'
#!/bin/sh

# SessionStart hook for Claude Code
# Automatically appends all AGENTS.md files found in the repository to the context
# This is a workaround for Claude Code's current lack of native AGENTS.md support

echo "=== AGENTS.md Context Loading ==="
echo ""

# Find all AGENTS.md files in current directory and subdirectories
find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
    echo "--- Loading: $file ---"
    cat "$file"
    echo ""
done

echo "=== End of AGENTS.md Context ==="
EOF
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
  local use_hook="$1"

  if [ "$use_hook" = "true" ]; then
    # Plan SessionStart hook approach
    if [ -f ".claude/settings.json" ]; then
      add_change "skip" ".claude/settings.json" "needs manual update for hook" ""
    else
      add_change "create" ".claude/settings.json" "" "$(template_claude_settings)"
    fi

    if [ -f ".claude/hooks/append_agentsmd_context.sh" ]; then
      add_change "skip" ".claude/hooks/append_agentsmd_context.sh" "already exists" ""
    else
      add_change "create" ".claude/hooks/append_agentsmd_context.sh" "" "$(template_claude_hook)"
    fi
  else
    # Plan CLAUDE.md approach (recommended)
    if [ -f "CLAUDE.md" ]; then
      add_change "skip" "CLAUDE.md" "already exists" ""
    else
      add_change "create" "CLAUDE.md" "" "$(template_claude_md)"
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
  printf "$(c heading Usage:) $(c cyan install.sh) [OPTIONS]"
}

show_help() {
  printf "\n"
  printf "$(usage)\n\n"
  printf "AGENTS.md polyfill installer - Configure AI agents to support AGENTS.md\n\n"

  printf "$(c heading Options:)\n"
  printf "  -h, --help          Show this help message\n"
  printf "  -y, --yes           Auto-confirm (skip confirmation prompt)\n"
  printf "  -n, --dry-run       Show plan only, don't apply changes\n"
  printf "  --claude-hook       Use SessionStart hook for Claude (default: CLAUDE.md import)\n"
  printf "  --no-aider          Skip Aider configuration\n"
  printf "  --no-gemini         Skip Gemini CLI configuration\n"
  printf "  --no-claude         Skip Claude Code configuration\n"
  printf "  --project-dir PATH  Specify project directory (default: current dir)\n\n"

  printf "$(c heading Examples:)\n"
  printf "  $(c cyan install.sh)                  # Interactive install in current directory\n"
  printf "  $(c cyan install.sh) -y               # Auto-confirm all changes\n"
  printf "  $(c cyan install.sh) -n               # Dry-run only\n"
  printf "  $(c cyan install.sh) --claude-hook    # Use SessionStart hook for Claude\n\n"

  printf "$(c heading One-liner install:)\n"
  printf "  curl -fsSL https://raw.githubusercontent.com/.../install.sh | sh\n\n"
}

# ============================================
# Main
# ============================================

main() {
  # Parse arguments
  local auto_confirm=false
  local dry_run=false
  local claude_hook=false
  local skip_aider=false
  local skip_gemini=false
  local skip_claude=false
  local project_dir="."

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
      --claude-hook)
        claude_hook=true
        shift
        ;;
      --no-aider)
        skip_aider=true
        shift
        ;;
      --no-gemini)
        skip_gemini=true
        shift
        ;;
      --no-claude)
        skip_claude=true
        shift
        ;;
      --project-dir)
        project_dir="$2"
        shift 2
        ;;
      *)
        panic 2 show_usage "Unknown option: $1"
        ;;
    esac
  done

  # Check requirements
  check_perl

  # Change to project directory
  cd "$project_dir" || panic 2 "Cannot access directory: $project_dir"

  # Welcome
  printf "\n$(c heading '=== AGENTS.md Polyfill Installer ===')\n"
  printf "Version: $VERSION\n"
  printf "Project: $(pwd)\n\n"

  # Plan changes
  plan_agents_md
  [ "$skip_aider" = false ] && plan_aider
  [ "$skip_gemini" = false ] && plan_gemini
  [ "$skip_claude" = false ] && plan_claude "$claude_hook"

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
