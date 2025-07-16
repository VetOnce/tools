#!/bin/bash

# Claude Worktree Merge Tool
# Manages merging of worktree branches back to main/master

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
CONFIG_FILE="${HOME}/.claude-worktree.config"
MERGE_STRATEGY="merge"  # Default strategy

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
    fi
}

# Get main branch name
get_main_branch() {
    # Try to detect main branch (main or master)
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        # Try to get from remote
        local remote_main=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
        if [ -n "$remote_main" ]; then
            echo "$remote_main"
        else
            echo "main"  # Default fallback
        fi
    fi
}

# Get worktree info
get_worktree_info() {
    local branch="$1"
    git worktree list --porcelain | awk -v branch="$branch" '
        /^worktree/ { worktree=$2 }
        /^branch/ && $2 == "refs/heads/"branch { print worktree }
    '
}

# Check if branch has uncommitted changes
has_uncommitted_changes() {
    local worktree_path="$1"
    if [ -d "$worktree_path" ]; then
        (cd "$worktree_path" && ! git diff-index --quiet HEAD -- 2>/dev/null)
    else
        return 1
    fi
}

# Get branch status relative to main
get_branch_status() {
    local branch="$1"
    local main_branch="$2"
    
    local ahead=$(git rev-list --count "${main_branch}..${branch}" 2>/dev/null || echo "0")
    local behind=$(git rev-list --count "${branch}..${main_branch}" 2>/dev/null || echo "0")
    
    echo "${ahead}|${behind}"
}

# List worktree branches
list_worktree_branches() {
    local main_branch=$(get_main_branch)
    
    print_header "Available Worktree Branches"
    
    local branches=()
    local index=1
    
    # Get all worktree branches
    while IFS= read -r line; do
        local worktree_path=$(echo "$line" | awk '{print $1}')
        local branch=$(echo "$line" | awk '{print $3}' | sed 's/\[//' | sed 's/\]//')
        
        # Skip main branch and detached heads
        if [ "$branch" != "$main_branch" ] && [ -n "$branch" ] && [ "$branch" != "detached" ]; then
            branches+=("$branch|$worktree_path")
            
            # Get status
            local status=$(get_branch_status "$branch" "$main_branch")
            local ahead=$(echo "$status" | cut -d'|' -f1)
            local behind=$(echo "$status" | cut -d'|' -f2)
            
            # Check for uncommitted changes
            local changes_marker=""
            if has_uncommitted_changes "$worktree_path"; then
                changes_marker="${RED}*${NC}"
            fi
            
            # Format output
            printf "${MAGENTA}%2d)${NC} %-30s" "$index" "$branch$changes_marker"
            
            if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
                printf " ${GREEN}↑%d${NC}/${RED}↓%d${NC}" "$ahead" "$behind"
            fi
            
            printf "\n"
            printf "    ${YELLOW}%s${NC}\n" "$worktree_path"
            
            ((index++))
        fi
    done < <(git worktree list)
    
    if [ ${#branches[@]} -eq 0 ]; then
        print_warning "No worktree branches found"
        return 1
    fi
    
    echo
    echo "${branches[@]}"
}

# Perform merge
perform_merge() {
    local branch="$1"
    local main_branch="$2"
    local strategy="${3:-$MERGE_STRATEGY}"
    
    print_header "Merging $branch into $main_branch"
    
    # Get worktree path
    local worktree_path=$(get_worktree_info "$branch")
    
    # Check for uncommitted changes
    if [ -n "$worktree_path" ] && has_uncommitted_changes "$worktree_path"; then
        print_error "Branch $branch has uncommitted changes in $worktree_path"
        print_warning "Please commit or stash changes before merging"
        return 1
    fi
    
    # Save current branch
    local current_branch=$(git branch --show-current)
    
    # Switch to main branch
    print_success "Switching to $main_branch branch"
    git checkout "$main_branch"
    
    # Pull latest changes
    if git remote -v | grep -q origin; then
        print_success "Pulling latest changes from origin"
        git pull origin "$main_branch" || print_warning "Could not pull from origin"
    fi
    
    # Perform merge based on strategy
    case "$strategy" in
        "merge")
            print_success "Performing merge"
            if git merge "$branch" --no-edit; then
                print_success "Successfully merged $branch into $main_branch"
            else
                print_error "Merge failed - resolve conflicts and complete manually"
                return 1
            fi
            ;;
        "rebase")
            print_success "Performing rebase merge"
            git checkout "$branch"
            if git rebase "$main_branch"; then
                git checkout "$main_branch"
                git merge "$branch" --ff-only
                print_success "Successfully rebased and merged $branch into $main_branch"
            else
                print_error "Rebase failed - resolve conflicts and complete manually"
                return 1
            fi
            ;;
        "squash")
            print_success "Performing squash merge"
            if git merge --squash "$branch"; then
                git commit -m "Squashed commit from $branch"
                print_success "Successfully squash-merged $branch into $main_branch"
            else
                print_error "Squash merge failed - resolve conflicts and complete manually"
                return 1
            fi
            ;;
        *)
            print_error "Unknown merge strategy: $strategy"
            return 1
            ;;
    esac
    
    # Ask about cleanup
    echo
    read -p "Remove worktree for $branch? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_worktree "$branch" "$worktree_path"
    fi
    
    # Ask about pushing
    if git remote -v | grep -q origin; then
        echo
        read -p "Push $main_branch to origin? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push origin "$main_branch"
            print_success "Pushed to origin"
        fi
    fi
}

# Cleanup worktree
cleanup_worktree() {
    local branch="$1"
    local worktree_path="$2"
    
    print_header "Cleaning up worktree"
    
    # Remove worktree
    if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
        git worktree remove "$worktree_path" --force
        print_success "Removed worktree at $worktree_path"
    fi
    
    # Delete branch
    read -p "Delete branch $branch? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -d "$branch" 2>/dev/null || git branch -D "$branch"
        print_success "Deleted branch $branch"
        
        # Delete remote branch if exists
        if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
            read -p "Delete remote branch origin/$branch? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push origin --delete "$branch"
                print_success "Deleted remote branch"
            fi
        fi
    fi
}

# Interactive merge
interactive_merge() {
    local branches_output=$(list_worktree_branches)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        return 1
    fi
    
    # Extract branches array from output
    local branches_line=$(echo "$branches_output" | tail -n 1)
    IFS=' ' read -ra branches <<< "$branches_line"
    
    echo
    read -p "Select branch to merge (1-${#branches[@]}) or 'q' to quit: " selection
    
    if [ "$selection" = "q" ]; then
        return 0
    fi
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#branches[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_branch=$(echo "${branches[$((selection-1))]}" | cut -d'|' -f1)
    local main_branch=$(get_main_branch)
    
    # Ask for merge strategy
    echo
    echo "Merge strategy:"
    echo "1) Merge (default)"
    echo "2) Rebase"
    echo "3) Squash"
    read -p "Select strategy (1-3) [1]: " strategy_choice
    
    case "$strategy_choice" in
        2) strategy="rebase" ;;
        3) strategy="squash" ;;
        *) strategy="merge" ;;
    esac
    
    perform_merge "$selected_branch" "$main_branch" "$strategy"
}

# Main function
main() {
    load_config
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository"
        exit 1
    fi
    
    case "${1:-}" in
        "--help"|"-h")
            cat << EOF
Claude Worktree Merge Tool

Usage: $(basename "$0") [OPTIONS] [BRANCH_NAME]

OPTIONS:
    -h, --help         Show this help message
    -s, --strategy     Merge strategy (merge, rebase, squash)
    -a, --auto         Auto-confirm prompts
    -l, --list         List branches only (no merge)

EXAMPLES:
    $(basename "$0")                    # Interactive mode
    $(basename "$0") feature-x          # Merge specific branch
    $(basename "$0") -s rebase feat-y   # Rebase merge
    $(basename "$0") --list             # List branches only

MERGE STRATEGIES:
    merge   - Standard merge commit (default)
    rebase  - Rebase branch before merging (linear history)
    squash  - Squash all commits into one

EOF
            ;;
        "--list"|"-l")
            list_worktree_branches > /dev/null
            ;;
        "--strategy"|"-s")
            shift
            if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
                print_error "Strategy and branch name required"
                exit 1
            fi
            MERGE_STRATEGY="$1"
            shift
            perform_merge "$1" "$(get_main_branch)" "$MERGE_STRATEGY"
            ;;
        "")
            interactive_merge
            ;;
        *)
            # Assume it's a branch name
            perform_merge "$1" "$(get_main_branch)"
            ;;
    esac
}

# Run main function
main "$@"