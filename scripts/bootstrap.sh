#!/bin/bash
# ==============================================================================
# Command-Center Bootstrap Script
# ==============================================================================
# Bootstraps do-the-thing, commit, and init workflows to global IDE/Agent locations.
# Similar to Spec-Kit's bootstrapping approach.
#
# Supported IDEs/Agents:
#   - Opencode:     ~/.config/opencode/command/ (Markdown format)
#   - Antigravity:  ~/.gemini/antigravity/global_workflows/ (Markdown format)
#   - Gemini-CLI:   ~/.gemini/commands/ (TOML format)
#
# Usage:
#   ./bootstrap.sh [options]
#
# Options:
#   --dry-run     Show what would be done without making changes
#   --opencode    Bootstrap only to Opencode
#   --antigravity Bootstrap only to Antigravity
#   --gemini-cli  Bootstrap only to Gemini-CLI (uses TOML format)
#   --all         Bootstrap to all detected IDEs (default)
#   --help        Show this help message
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory (where command-center repo is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Global locations
OPENCODE_COMMANDS="$HOME/.config/opencode/command"
OPENCODE_SUPPORT="$HOME/.config/opencode/.do-the-thing"
ANTIGRAVITY_COMMANDS="$HOME/.gemini/antigravity/global_workflows"
ANTIGRAVITY_SUPPORT="$HOME/.gemini/antigravity/.do-the-thing"
GEMINI_CLI_COMMANDS="$HOME/.gemini/commands"
GEMINI_CLI_SUPPORT="$HOME/.gemini/.do-the-thing"

# Flags
DRY_RUN=false
TARGET_OPENCODE=false
TARGET_ANTIGRAVITY=false
TARGET_GEMINI_CLI=false

# ==============================================================================
# Helper Functions
# ==============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║             Command-Center Bootstrap Script                   ║"
    echo "║         Deploying workflows to global IDE locations           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} Would: $1"
}

show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run       Show what would be done without making changes"
    echo "  --opencode      Bootstrap only to Opencode"
    echo "  --antigravity   Bootstrap only to Antigravity"
    echo "  --gemini-cli    Bootstrap only to Gemini-CLI"
    echo "  --all           Bootstrap to all detected IDEs (default)"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Bootstrap to all detected IDEs"
    echo "  $0 --opencode         # Bootstrap only to Opencode"
    echo "  $0 --gemini-cli       # Bootstrap only to Gemini-CLI"
    echo "  $0 --dry-run          # Preview changes without applying"
}

# ==============================================================================
# Detection Functions
# ==============================================================================

detect_opencode() {
    # Check if Opencode config directory exists or if opencode command exists
    if [[ -d "$HOME/.config/opencode" ]] || command -v opencode &> /dev/null; then
        return 0
    fi
    return 1
}

detect_antigravity() {
    # Check if Antigravity/Gemini directory exists
    if [[ -d "$HOME/.gemini/antigravity" ]]; then
        return 0
    fi
    return 1
}

detect_gemini_cli() {
    # Check if Gemini-CLI is installed
    # Gemini-CLI uses ~/.gemini/ but NOT ~/.gemini/antigravity/ (that's Antigravity)
    # Check for gemini command in PATH or ~/.gemini/commands/ or ~/.gemini/GEMINI.md
    if command -v gemini &> /dev/null; then
        return 0
    fi
    # Check for Gemini-CLI config files (but not just antigravity)
    if [[ -f "$HOME/.gemini/GEMINI.md" ]] || [[ -d "$HOME/.gemini/commands" ]]; then
        return 0
    fi
    return 1
}

# ==============================================================================
# TOML Conversion Functions (for Gemini-CLI)
# ==============================================================================

# Convert a markdown command file (with YAML frontmatter) to TOML format
# Usage: convert_md_to_toml <source_md_file> <dest_toml_file>
convert_md_to_toml() {
    local src="$1"
    local dest="$2"
    local filename
    filename=$(basename "$src" .md)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Convert $src -> $dest (TOML format)"
        return
    fi
    
    # Extract description from YAML frontmatter
    # Frontmatter is between first --- and second ---
    local description
    description=$(sed -n '/^---$/,/^---$/p' "$src" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    
    # If no description found, use a default
    if [[ -z "$description" ]]; then
        description="Command: $filename"
    fi
    
    # Extract body content (everything after the second ---)
    # Use awk to skip the frontmatter and get everything after
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
    
    log_success "Converted $(basename "$src") -> $(basename "$dest") (TOML format)"
}

# Clean up old markdown command files from Gemini-CLI commands directory
cleanup_old_gemini_md_files() {
    if [[ "$DRY_RUN" == "true" ]]; then
        for file in "do-the-thing.md" "commit.md" "init.md"; do
            if [[ -f "$GEMINI_CLI_COMMANDS/$file" ]]; then
                log_dry_run "Remove old file $GEMINI_CLI_COMMANDS/$file"
            fi
        done
        return
    fi
    
    for file in "do-the-thing.md" "commit.md" "init.md"; do
        if [[ -f "$GEMINI_CLI_COMMANDS/$file" ]]; then
            rm -f "$GEMINI_CLI_COMMANDS/$file"
            log_info "Removed old file: $GEMINI_CLI_COMMANDS/$file"
        fi
    done
}

# ==============================================================================
# Bootstrap Functions
# ==============================================================================

copy_file() {
    local src="$1"
    local dest="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Copy $src -> $dest"
    else
        cp "$src" "$dest"
        log_success "Copied $(basename "$src") -> $dest"
    fi
}

copy_directory() {
    local src="$1"
    local dest="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Copy directory $src -> $dest"
    else
        cp -r "$src" "$dest"
        log_success "Copied directory $(basename "$src") -> $dest"
    fi
}

create_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry_run "Create directory $dir"
        else
            mkdir -p "$dir"
            log_success "Created directory $dir"
        fi
    fi
}

bootstrap_to_opencode() {
    log_info "Bootstrapping to Opencode..."
    
    # Create directories
    create_directory "$OPENCODE_COMMANDS"
    create_directory "$OPENCODE_SUPPORT"
    
    # Copy command files
    copy_file "$REPO_DIR/do-the-thing.md" "$OPENCODE_COMMANDS/do-the-thing.md"
    copy_file "$REPO_DIR/commit.md" "$OPENCODE_COMMANDS/commit.md"
    copy_file "$REPO_DIR/init.md" "$OPENCODE_COMMANDS/init.md"
    
    # Copy support files (.do-the-thing directory contents)
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Copy .do-the-thing/* -> $OPENCODE_SUPPORT/"
    else
        # Remove existing and copy fresh
        rm -rf "$OPENCODE_SUPPORT"
        cp -r "$REPO_DIR/.do-the-thing" "$OPENCODE_SUPPORT"
        log_success "Copied .do-the-thing support files to $OPENCODE_SUPPORT"
    fi
    
    echo ""
    log_success "Opencode bootstrap complete!"
}

bootstrap_to_antigravity() {
    log_info "Bootstrapping to Antigravity..."
    
    # Create directories
    create_directory "$ANTIGRAVITY_COMMANDS"
    create_directory "$ANTIGRAVITY_SUPPORT"
    
    # Copy command files
    copy_file "$REPO_DIR/do-the-thing.md" "$ANTIGRAVITY_COMMANDS/do-the-thing.md"
    copy_file "$REPO_DIR/commit.md" "$ANTIGRAVITY_COMMANDS/commit.md"
    copy_file "$REPO_DIR/init.md" "$ANTIGRAVITY_COMMANDS/init.md"
    
    # Copy support files (.do-the-thing directory contents)
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Copy .do-the-thing/* -> $ANTIGRAVITY_SUPPORT/"
    else
        # Remove existing and copy fresh
        rm -rf "$ANTIGRAVITY_SUPPORT"
        cp -r "$REPO_DIR/.do-the-thing" "$ANTIGRAVITY_SUPPORT"
        log_success "Copied .do-the-thing support files to $ANTIGRAVITY_SUPPORT"
    fi
    
    echo ""
    log_success "Antigravity bootstrap complete!"
}

bootstrap_to_gemini_cli() {
    log_info "Bootstrapping to Gemini-CLI (TOML format)..."
    
    # Create directories
    create_directory "$GEMINI_CLI_COMMANDS"
    create_directory "$GEMINI_CLI_SUPPORT"
    
    # Clean up old markdown command files
    cleanup_old_gemini_md_files
    
    # Convert and copy command files as TOML
    convert_md_to_toml "$REPO_DIR/do-the-thing.md" "$GEMINI_CLI_COMMANDS/do-the-thing.toml"
    convert_md_to_toml "$REPO_DIR/commit.md" "$GEMINI_CLI_COMMANDS/commit.toml"
    convert_md_to_toml "$REPO_DIR/init.md" "$GEMINI_CLI_COMMANDS/init.toml"
    
    # Copy support files (.do-the-thing directory contents)
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Copy .do-the-thing/* -> $GEMINI_CLI_SUPPORT/"
    else
        # Remove existing and copy fresh
        rm -rf "$GEMINI_CLI_SUPPORT"
        cp -r "$REPO_DIR/.do-the-thing" "$GEMINI_CLI_SUPPORT"
        log_success "Copied .do-the-thing support files to $GEMINI_CLI_SUPPORT"
    fi
    
    echo ""
    log_success "Gemini-CLI bootstrap complete!"
}

# ==============================================================================
# Verification Functions
# ==============================================================================

verify_installation() {
    echo ""
    log_info "Verifying installation..."
    echo ""
    
    local all_ok=true
    
    if [[ "$TARGET_OPENCODE" == "true" ]]; then
        echo -e "${CYAN}Opencode:${NC}"
        for file in "do-the-thing.md" "commit.md" "init.md"; do
            if [[ -f "$OPENCODE_COMMANDS/$file" ]]; then
                echo -e "  ${GREEN}✓${NC} $OPENCODE_COMMANDS/$file"
            else
                echo -e "  ${RED}✗${NC} $OPENCODE_COMMANDS/$file (missing)"
                all_ok=false
            fi
        done
        if [[ -d "$OPENCODE_SUPPORT" ]]; then
            echo -e "  ${GREEN}✓${NC} $OPENCODE_SUPPORT/"
        else
            echo -e "  ${RED}✗${NC} $OPENCODE_SUPPORT/ (missing)"
            all_ok=false
        fi
        echo ""
    fi
    
    if [[ "$TARGET_ANTIGRAVITY" == "true" ]]; then
        echo -e "${CYAN}Antigravity:${NC}"
        for file in "do-the-thing.md" "commit.md" "init.md"; do
            if [[ -f "$ANTIGRAVITY_COMMANDS/$file" ]]; then
                echo -e "  ${GREEN}✓${NC} $ANTIGRAVITY_COMMANDS/$file"
            else
                echo -e "  ${RED}✗${NC} $ANTIGRAVITY_COMMANDS/$file (missing)"
                all_ok=false
            fi
        done
        if [[ -d "$ANTIGRAVITY_SUPPORT" ]]; then
            echo -e "  ${GREEN}✓${NC} $ANTIGRAVITY_SUPPORT/"
        else
            echo -e "  ${RED}✗${NC} $ANTIGRAVITY_SUPPORT/ (missing)"
            all_ok=false
        fi
        echo ""
    fi
    
    if [[ "$TARGET_GEMINI_CLI" == "true" ]]; then
        echo -e "${CYAN}Gemini-CLI:${NC}"
        for file in "do-the-thing.toml" "commit.toml" "init.toml"; do
            if [[ -f "$GEMINI_CLI_COMMANDS/$file" ]]; then
                echo -e "  ${GREEN}✓${NC} $GEMINI_CLI_COMMANDS/$file"
            else
                echo -e "  ${RED}✗${NC} $GEMINI_CLI_COMMANDS/$file (missing)"
                all_ok=false
            fi
        done
        if [[ -d "$GEMINI_CLI_SUPPORT" ]]; then
            echo -e "  ${GREEN}✓${NC} $GEMINI_CLI_SUPPORT/"
        else
            echo -e "  ${RED}✗${NC} $GEMINI_CLI_SUPPORT/ (missing)"
            all_ok=false
        fi
        echo ""
    fi
    
    if [[ "$all_ok" == "true" ]]; then
        log_success "All files verified successfully!"
    else
        log_warning "Some files are missing. Check the output above."
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --opencode)
                TARGET_OPENCODE=true
                shift
                ;;
            --antigravity)
                TARGET_ANTIGRAVITY=true
                shift
                ;;
            --gemini-cli)
                TARGET_GEMINI_CLI=true
                shift
                ;;
            --all)
                TARGET_OPENCODE=false
                TARGET_ANTIGRAVITY=false
                TARGET_GEMINI_CLI=false
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_banner
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Verify source files exist
    if [[ ! -f "$REPO_DIR/do-the-thing.md" ]]; then
        log_error "Source file not found: $REPO_DIR/do-the-thing.md"
        log_error "Please run this script from the command-center repository"
        exit 1
    fi
    
    # Auto-detect if no specific target
    if [[ "$TARGET_OPENCODE" == "false" && "$TARGET_ANTIGRAVITY" == "false" && "$TARGET_GEMINI_CLI" == "false" ]]; then
        log_info "Auto-detecting available IDEs..."
        
        if detect_opencode; then
            log_success "Detected: Opencode"
            TARGET_OPENCODE=true
        else
            log_warning "Not detected: Opencode"
        fi
        
        if detect_antigravity; then
            log_success "Detected: Antigravity"
            TARGET_ANTIGRAVITY=true
        else
            log_warning "Not detected: Antigravity"
        fi
        
        if detect_gemini_cli; then
            log_success "Detected: Gemini-CLI"
            TARGET_GEMINI_CLI=true
        else
            log_warning "Not detected: Gemini-CLI"
        fi
        
        echo ""
        
        if [[ "$TARGET_OPENCODE" == "false" && "$TARGET_ANTIGRAVITY" == "false" && "$TARGET_GEMINI_CLI" == "false" ]]; then
            log_error "No supported IDEs detected!"
            log_info "Make sure Opencode, Antigravity, or Gemini-CLI is installed."
            exit 1
        fi
    fi
    
    # Bootstrap to selected targets
    if [[ "$TARGET_OPENCODE" == "true" ]]; then
        bootstrap_to_opencode
    fi
    
    if [[ "$TARGET_ANTIGRAVITY" == "true" ]]; then
        bootstrap_to_antigravity
    fi
    
    if [[ "$TARGET_GEMINI_CLI" == "true" ]]; then
        bootstrap_to_gemini_cli
    fi
    
    # Verify installation (skip for dry run)
    if [[ "$DRY_RUN" != "true" ]]; then
        verify_installation
    fi
    
    echo ""
    echo -e "${GREEN}Bootstrap complete!${NC}"
    echo ""
    echo "You can now use the following commands from any project:"
    echo "  /do-the-thing  - Execute the complete SDD workflow"
    echo "  /commit        - Commit, push, and optionally create PR"
    echo "  /init          - Create/update AGENTS.md"
}

main "$@"
