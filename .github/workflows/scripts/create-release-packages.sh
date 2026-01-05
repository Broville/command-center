#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# create-release-packages.sh
# ==============================================================================
# Build Command-Center release packages for Opencode and Antigravity.
# Usage: .github/workflows/scripts/create-release-packages.sh <version>
#
# Arguments:
#   version - Version with leading 'v' (e.g., v1.0.0)
#
# Options (via environment variables):
#   AGENTS - Space/comma separated subset of: opencode antigravity (default: both)
#
# Examples:
#   ./create-release-packages.sh v1.0.0
#   AGENTS=opencode ./create-release-packages.sh v1.0.0
# ==============================================================================

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version-with-v-prefix>" >&2
  exit 1
fi

NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v0.0.0" >&2
  exit 1
fi

echo "Building Command-Center release packages for $NEW_VERSION"

# Create and clean release directory
GENRELEASES_DIR=".genreleases"
mkdir -p "$GENRELEASES_DIR"
rm -rf "$GENRELEASES_DIR"/* || true

# Command files to include
COMMAND_FILES=("do-the-thing.md" "commit.md" "init.md")

# Support directory
SUPPORT_DIR=".do-the-thing"

# ==============================================================================
# Build Functions
# ==============================================================================

# Convert a markdown command file (with YAML frontmatter) to TOML format
# Usage: convert_md_to_toml <source_md_file> <dest_toml_file>
convert_md_to_toml() {
  local src="$1"
  local dest="$2"
  local filename
  filename=$(basename "$src" .md)
  
  # Extract description from YAML frontmatter
  local description
  description=$(sed -n '/^---$/,/^---$/p' "$src" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
  
  # If no description found, use a default
  if [[ -z "$description" ]]; then
    description="Command: $filename"
  fi
  
  # Extract body content (everything after the second ---)
  local body
  body=$(awk 'BEGIN{count=0} /^---$/{count++; if(count==2){getline; found=1}} found{print}' "$src")
  
  # Write TOML file
  {
    echo "description = \"$description\""
    echo ""
    echo "prompt = '''"
    printf '%s\n' "$body"
    echo "'''"
  } > "$dest"
  
  echo "  Converted $src -> $(basename "$dest") (TOML)"
}

build_opencode_package() {
  local base_dir="$GENRELEASES_DIR/command-center-opencode"
  echo "Building Opencode package..."
  
  mkdir -p "$base_dir/.opencode/command"
  mkdir -p "$base_dir/.do-the-thing"
  
  # Copy command files
  for cmd in "${COMMAND_FILES[@]}"; do
    if [[ -f "$cmd" ]]; then
      cp "$cmd" "$base_dir/.opencode/command/"
      echo "  Copied $cmd -> .opencode/command/"
    else
      echo "  Warning: $cmd not found" >&2
    fi
  done
  
  # Copy support files (including hidden directories like .specify/)
  if [[ -d "$SUPPORT_DIR" ]]; then
    cp -r "$SUPPORT_DIR"/. "$base_dir/.do-the-thing/"
    echo "  Copied $SUPPORT_DIR/* -> .do-the-thing/"
  else
    echo "  Warning: $SUPPORT_DIR not found" >&2
  fi
  
  # Create ZIP
  local zip_name="command-center-opencode-${NEW_VERSION}.zip"
  (cd "$base_dir" && zip -r "../$zip_name" .)
  echo "Created $GENRELEASES_DIR/$zip_name"
}

build_antigravity_package() {
  local base_dir="$GENRELEASES_DIR/command-center-antigravity"
  echo "Building Antigravity package..."
  
  mkdir -p "$base_dir/global_workflows"
  mkdir -p "$base_dir/.do-the-thing"
  
  # Copy command files
  for cmd in "${COMMAND_FILES[@]}"; do
    if [[ -f "$cmd" ]]; then
      cp "$cmd" "$base_dir/global_workflows/"
      echo "  Copied $cmd -> global_workflows/"
    else
      echo "  Warning: $cmd not found" >&2
    fi
  done
  
  # Copy support files (including hidden directories like .specify/)
  if [[ -d "$SUPPORT_DIR" ]]; then
    cp -r "$SUPPORT_DIR"/. "$base_dir/.do-the-thing/"
    echo "  Copied $SUPPORT_DIR/* -> .do-the-thing/"
  else
    echo "  Warning: $SUPPORT_DIR not found" >&2
  fi
  
  # Create ZIP
  local zip_name="command-center-antigravity-${NEW_VERSION}.zip"
  (cd "$base_dir" && zip -r "../$zip_name" .)
  echo "Created $GENRELEASES_DIR/$zip_name"
}

build_gemini_cli_package() {
  local base_dir="$GENRELEASES_DIR/command-center-gemini-cli"
  echo "Building Gemini-CLI package..."
  
  mkdir -p "$base_dir/.gemini/commands"
  mkdir -p "$base_dir/.gemini/.do-the-thing"
  
  # Convert command files to TOML
  for cmd in "${COMMAND_FILES[@]}"; do
    if [[ -f "$cmd" ]]; then
      local base_name=$(basename "$cmd" .md)
      convert_md_to_toml "$cmd" "$base_dir/.gemini/commands/${base_name}.toml"
    else
      echo "  Warning: $cmd not found" >&2
    fi
  done
  
  # Copy support files
  if [[ -d "$SUPPORT_DIR" ]]; then
    cp -r "$SUPPORT_DIR"/. "$base_dir/.gemini/.do-the-thing/"
    echo "  Copied $SUPPORT_DIR/* -> .gemini/.do-the-thing/"
  else
    echo "  Warning: $SUPPORT_DIR not found" >&2
  fi
  
  # Create ZIP
  local zip_name="command-center-gemini-cli-${NEW_VERSION}.zip"
  (cd "$base_dir" && zip -r "../$zip_name" .)
  echo "Created $GENRELEASES_DIR/$zip_name"
}

# ==============================================================================
# Main
# ==============================================================================

# Determine which agents to build
ALL_AGENTS=(opencode antigravity gemini-cli)

norm_list() {
  tr ',\n' '  ' | awk '{for(i=1;i<=NF;i++){if(!seen[$i]++){printf((out?"\n":"") $i);out=1}}}END{printf("\n")}'
}

if [[ -n ${AGENTS:-} ]]; then
  mapfile -t AGENT_LIST < <(printf '%s' "$AGENTS" | norm_list)
  # Validate
  for agent in "${AGENT_LIST[@]}"; do
    valid=0
    for a in "${ALL_AGENTS[@]}"; do
      [[ $agent == "$a" ]] && { valid=1; break; }
    done
    if [[ $valid -eq 0 ]]; then
      echo "Error: unknown agent '$agent' (allowed: ${ALL_AGENTS[*]})" >&2
      exit 1
    fi
  done
else
  AGENT_LIST=("${ALL_AGENTS[@]}")
fi

echo "Building for agents: ${AGENT_LIST[*]}"
echo ""

# Build packages
for agent in "${AGENT_LIST[@]}"; do
  case $agent in
    opencode)
      build_opencode_package
      ;;
    antigravity)
      build_antigravity_package
      ;;
    gemini-cli)
      build_gemini_cli_package
      ;;
  esac
  echo ""
done

# List created packages
echo "Release packages created in $GENRELEASES_DIR:"
ls -1 "$GENRELEASES_DIR"/command-center-*-"${NEW_VERSION}".zip
