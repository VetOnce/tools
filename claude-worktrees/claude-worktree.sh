#!/bin/bash

# Claude Worktree Management Tool
# Automates Git worktree creation and management for parallel Claude agent development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration defaults
CONFIG_FILE="${HOME}/.claude-worktree.config"
DEFAULT_EDITOR="Cursor"
DEFAULT_FOLDERS_TO_COPY=".env .claude .cursor .agentos"

# Functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        EDITOR="${DEFAULT_EDITOR}"
        FOLDERS_TO_COPY="${DEFAULT_FOLDERS_TO_COPY}"
    fi
}

# Check prerequisites
check_prerequisites() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository. Please run from within a Git repository."
        exit 1
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes. It's recommended to commit or stash them first."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Get project information
get_project_info() {
    PROJECT_ROOT=$(git rev-parse --show-toplevel)
    PROJECT_NAME=$(basename "$PROJECT_ROOT")
    WORKTREES_DIR="${PROJECT_ROOT}/../${PROJECT_NAME}-worktrees"
}

# Create worktree
create_worktree() {
    local branch_name="$1"
    local worktree_path="${WORKTREES_DIR}/${branch_name}"

    print_header "Creating Worktree: ${branch_name}"

    # Create worktrees directory if it doesn't exist
    mkdir -p "$WORKTREES_DIR"

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        print_warning "Branch '${branch_name}' already exists."
        read -p "Use existing branch? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
        git worktree add "$worktree_path" "$branch_name"
    else
        # Create new branch and worktree
        git worktree add -b "$branch_name" "$worktree_path"
    fi

    print_success "Worktree created at: $worktree_path"

    # Copy configuration files
    copy_config_files "$worktree_path"

    # Open in editor if requested
    if [ "${OPEN_EDITOR}" = "true" ]; then
        open_in_editor "$worktree_path"
    fi

    return 0
}

# Copy configuration files
copy_config_files() {
    local worktree_path="$1"
    
    print_header "Copying Configuration Files"

    for item in $FOLDERS_TO_COPY; do
        if [ -e "${PROJECT_ROOT}/${item}" ]; then
            cp -R "${PROJECT_ROOT}/${item}" "$worktree_path/"
            print_success "Copied ${item}"
        fi
    done

    # Copy CLAUDE.md if it exists
    if [ -f "${PROJECT_ROOT}/CLAUDE.md" ]; then
        cp "${PROJECT_ROOT}/CLAUDE.md" "$worktree_path/"
        print_success "Copied CLAUDE.md"
    fi
}

# Open in editor
open_in_editor() {
    local path="$1"
    
    case "$EDITOR" in
        "Cursor")
            if command -v cursor &> /dev/null; then
                cursor "$path"
            else
                open -a "Cursor" "$path" 2>/dev/null || print_warning "Cursor not found"
            fi
            ;;
        "code"|"vscode")
            if command -v code &> /dev/null; then
                code "$path"
            else
                print_warning "VS Code not found"
            fi
            ;;
        *)
            print_warning "Unknown editor: $EDITOR"
            ;;
    esac
}

# List existing worktrees
list_worktrees() {
    print_header "Existing Worktrees"
    
    if command -v git &> /dev/null && git worktree list &> /dev/null; then
        git worktree list | while read -r line; do
            echo "  $line"
        done
    else
        print_error "Unable to list worktrees"
    fi
}

# Interactive mode
interactive_mode() {
    print_header "Claude Worktree Manager - Interactive Mode"
    
    echo "1) Create new worktree"
    echo "2) Create from existing branch"
    echo "3) List worktrees"
    echo "4) Exit"
    echo
    read -p "Select option (1-4): " -n 1 -r
    echo

    case $REPLY in
        1)
            read -p "Enter new branch name: " branch_name
            if [ -z "$branch_name" ]; then
                print_error "Branch name cannot be empty"
                return 1
            fi
            OPEN_EDITOR=true
            create_worktree "$branch_name"
            ;;
        2)
            print_header "Available Branches"
            git branch -a | sed 's/^[* ]*//' | grep -v 'HEAD' | sort -u
            echo
            read -p "Enter branch name: " branch_name
            if [ -z "$branch_name" ]; then
                print_error "Branch name cannot be empty"
                return 1
            fi
            OPEN_EDITOR=true
            create_worktree "$branch_name"
            ;;
        3)
            list_worktrees
            ;;
        4)
            exit 0
            ;;
        *)
            print_error "Invalid option"
            return 1
            ;;
    esac
}

# Main function
main() {
    load_config
    check_prerequisites
    get_project_info

    # Parse command line arguments
    case "${1:-}" in
        "")
            # No arguments - run interactive mode
            interactive_mode
            ;;
        "--list"|"-l")
            list_worktrees
            ;;
        "--help"|"-h")
            cat << EOF
Claude Worktree Management Tool

Usage: $(basename "$0") [OPTIONS] [BRANCH_NAME]

OPTIONS:
    -l, --list       List all worktrees
    -h, --help       Show this help message
    -n, --no-editor  Don't open editor after creation
    -e, --editor     Specify editor (cursor, code, vscode)

EXAMPLES:
    $(basename "$0")                  # Interactive mode
    $(basename "$0") feature-x        # Create worktree for feature-x
    $(basename "$0") -l               # List all worktrees
    $(basename "$0") -e code feat-y   # Create worktree and open in VS Code

CONFIGURATION:
    Config file: ~/.claude-worktree.config
    
    Example config:
        EDITOR="Cursor"
        FOLDERS_TO_COPY=".env .claude .cursor .agentos"
EOF
            ;;
        "--no-editor"|"-n")
            OPEN_EDITOR=false
            shift
            if [ -n "${1:-}" ]; then
                create_worktree "$1"
            else
                print_error "Branch name required"
                exit 1
            fi
            ;;
        "--editor"|"-e")
            shift
            if [ -n "${1:-}" ]; then
                EDITOR="$1"
                shift
                if [ -n "${1:-}" ]; then
                    OPEN_EDITOR=true
                    create_worktree "$1"
                else
                    print_error "Branch name required"
                    exit 1
                fi
            else
                print_error "Editor name required"
                exit 1
            fi
            ;;
        *)
            # Assume it's a branch name
            OPEN_EDITOR=true
            create_worktree "$1"
            ;;
    esac
}

# Run main function
main "$@"