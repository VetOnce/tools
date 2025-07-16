#!/bin/bash

# Claude Worktree Cleanup Tool
# Manages removal of old, merged, or orphaned worktrees

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

# Configuration
CONFIG_FILE="${HOME}/.claude-worktree.config"
AUTO_CLEANUP="false"
DRY_RUN="false"

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Get main branch name
get_main_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        local remote_main=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
        if [ -n "$remote_main" ]; then
            echo "$remote_main"
        else
            echo "main"
        fi
    fi
}

# Check if branch is merged
is_branch_merged() {
    local branch="$1"
    local target_branch="${2:-$(get_main_branch)}"
    
    # Check if all commits from branch are in target branch
    local unmerged_commits=$(git cherry "$target_branch" "$branch" 2>/dev/null | grep -c "^+" || echo "0")
    [ "$unmerged_commits" -eq 0 ]
}

# Check if worktree is orphaned
is_worktree_orphaned() {
    local worktree_path="$1"
    
    # Check if directory exists
    if [ ! -d "$worktree_path" ]; then
        return 0  # Orphaned if directory doesn't exist
    fi
    
    # Check if it's still a valid git directory
    if ! git -C "$worktree_path" rev-parse --git-dir >/dev/null 2>&1; then
        return 0  # Orphaned if not a git directory
    fi
    
    return 1  # Not orphaned
}

# Get worktree age in days
get_worktree_age() {
    local worktree_path="$1"
    
    if [ ! -d "$worktree_path" ]; then
        echo "999"  # Return large number for missing directories
        return
    fi
    
    # Try to get last commit date
    local last_commit_timestamp=$(git -C "$worktree_path" log -1 --format="%at" 2>/dev/null || echo "0")
    
    if [ "$last_commit_timestamp" -gt 0 ]; then
        local current_timestamp=$(date +%s)
        local age_seconds=$((current_timestamp - last_commit_timestamp))
        local age_days=$((age_seconds / 86400))
        echo "$age_days"
    else
        # Fall back to directory modification time
        local dir_timestamp=$(stat -f "%m" "$worktree_path" 2>/dev/null || stat -c "%Y" "$worktree_path" 2>/dev/null || echo "0")
        if [ "$dir_timestamp" -gt 0 ]; then
            local current_timestamp=$(date +%s)
            local age_seconds=$((current_timestamp - dir_timestamp))
            local age_days=$((age_seconds / 86400))
            echo "$age_days"
        else
            echo "999"
        fi
    fi
}

# Analyze worktrees
analyze_worktrees() {
    local main_branch=$(get_main_branch)
    
    print_header "Analyzing Worktrees"
    
    local merged_worktrees=()
    local orphaned_worktrees=()
    local old_worktrees=()
    local active_worktrees=()
    
    while IFS= read -r line; do
        local worktree_path=$(echo "$line" | awk '{print $1}')
        local branch_info=$(echo "$line" | cut -d' ' -f3-)
        
        # Skip bare repository
        if [[ "$branch_info" == "(bare)" ]]; then
            continue
        fi
        
        # Extract branch name
        local branch=""
        if [[ "$branch_info" =~ \[([^\]]+)\] ]]; then
            branch="${BASH_REMATCH[1]}"
        fi
        
        # Skip main branch
        if [ "$branch" = "$main_branch" ]; then
            continue
        fi
        
        # Check various conditions
        local status="active"
        local reasons=()
        
        # Check if orphaned
        if is_worktree_orphaned "$worktree_path"; then
            orphaned_worktrees+=("$branch|$worktree_path")
            reasons+=("orphaned")
            status="orphaned"
        else
            # Check if merged
            if is_branch_merged "$branch" "$main_branch"; then
                merged_worktrees+=("$branch|$worktree_path")
                reasons+=("merged")
                status="merged"
            fi
            
            # Check age
            local age=$(get_worktree_age "$worktree_path")
            if [ "$age" -gt 30 ]; then
                old_worktrees+=("$branch|$worktree_path|$age")
                reasons+=("old: ${age} days")
            fi
        fi
        
        if [ "$status" = "active" ] && [ ${#reasons[@]} -eq 0 ]; then
            active_worktrees+=("$branch|$worktree_path")
        fi
        
        # Display status
        echo -n "  $branch: "
        if [ ${#reasons[@]} -gt 0 ]; then
            echo -e "${YELLOW}${reasons[*]}${NC}"
        else
            echo -e "${GREEN}active${NC}"
        fi
    done < <(git worktree list)
    
    # Return results
    echo "${#merged_worktrees[@]}|${#orphaned_worktrees[@]}|${#old_worktrees[@]}|${#active_worktrees[@]}"
    echo "MERGED:${merged_worktrees[*]}"
    echo "ORPHANED:${orphaned_worktrees[*]}"
    echo "OLD:${old_worktrees[*]}"
    echo "ACTIVE:${active_worktrees[*]}"
}

# Remove worktree
remove_worktree() {
    local branch="$1"
    local worktree_path="$2"
    local force="${3:-false}"
    
    if [ "$DRY_RUN" = "true" ]; then
        print_info "[DRY RUN] Would remove worktree: $branch at $worktree_path"
        return 0
    fi
    
    # Remove worktree
    if git worktree remove "$worktree_path" ${force:+--force} 2>/dev/null; then
        print_success "Removed worktree: $worktree_path"
    else
        print_warning "Could not remove worktree, trying force removal"
        if git worktree remove "$worktree_path" --force 2>/dev/null; then
            print_success "Force removed worktree: $worktree_path"
        else
            print_error "Failed to remove worktree: $worktree_path"
            return 1
        fi
    fi
    
    # Ask about branch deletion
    if [ "$AUTO_CLEANUP" != "true" ]; then
        read -p "Delete branch '$branch'? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Delete branch
    if git branch -d "$branch" 2>/dev/null || git branch -D "$branch" 2>/dev/null; then
        print_success "Deleted branch: $branch"
    else
        print_warning "Could not delete branch: $branch"
    fi
    
    # Check for remote branch
    if git ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"; then
        if [ "$AUTO_CLEANUP" = "true" ]; then
            git push origin --delete "$branch" 2>/dev/null && print_success "Deleted remote branch: origin/$branch"
        else
            read -p "Delete remote branch 'origin/$branch'? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push origin --delete "$branch" 2>/dev/null && print_success "Deleted remote branch: origin/$branch"
            fi
        fi
    fi
}

# Interactive cleanup
interactive_cleanup() {
    local analysis_output=$(analyze_worktrees)
    
    # Parse analysis results
    local counts=$(echo "$analysis_output" | head -1)
    IFS='|' read -r merged_count orphaned_count old_count active_count <<< "$counts"
    
    print_header "Cleanup Summary"
    echo -e "  Merged worktrees: ${GREEN}$merged_count${NC}"
    echo -e "  Orphaned worktrees: ${RED}$orphaned_count${NC}"
    echo -e "  Old worktrees (>30 days): ${YELLOW}$old_count${NC}"
    echo -e "  Active worktrees: ${BLUE}$active_count${NC}"
    echo
    
    if [ "$merged_count" -eq 0 ] && [ "$orphaned_count" -eq 0 ] && [ "$old_count" -eq 0 ]; then
        print_success "No worktrees need cleanup!"
        return 0
    fi
    
    # Process each category
    local cleaned_count=0
    
    # Handle orphaned worktrees
    if [ "$orphaned_count" -gt 0 ]; then
        print_header "Orphaned Worktrees"
        local orphaned_list=$(echo "$analysis_output" | grep "^ORPHANED:" | cut -d: -f2-)
        
        echo "Found $orphaned_count orphaned worktree(s):"
        IFS=' ' read -ra orphaned_array <<< "$orphaned_list"
        for item in "${orphaned_array[@]}"; do
            IFS='|' read -r branch path <<< "$item"
            echo "  - $branch: $path"
        done
        
        echo
        read -p "Remove all orphaned worktrees? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            for item in "${orphaned_array[@]}"; do
                IFS='|' read -r branch path <<< "$item"
                remove_worktree "$branch" "$path" true
                ((cleaned_count++))
            done
        fi
    fi
    
    # Handle merged worktrees
    if [ "$merged_count" -gt 0 ]; then
        print_header "Merged Worktrees"
        local merged_list=$(echo "$analysis_output" | grep "^MERGED:" | cut -d: -f2-)
        
        echo "Found $merged_count merged worktree(s):"
        IFS=' ' read -ra merged_array <<< "$merged_list"
        for item in "${merged_array[@]}"; do
            IFS='|' read -r branch path <<< "$item"
            echo "  - $branch: $path"
        done
        
        echo
        read -p "Remove all merged worktrees? (Y/n/i): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Ii]$ ]]; then
            # Individual selection
            for item in "${merged_array[@]}"; do
                IFS='|' read -r branch path <<< "$item"
                read -p "Remove $branch? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_worktree "$branch" "$path"
                    ((cleaned_count++))
                fi
            done
        elif [[ ! $REPLY =~ ^[Nn]$ ]]; then
            # Remove all
            for item in "${merged_array[@]}"; do
                IFS='|' read -r branch path <<< "$item"
                remove_worktree "$branch" "$path"
                ((cleaned_count++))
            done
        fi
    fi
    
    # Handle old worktrees
    if [ "$old_count" -gt 0 ]; then
        print_header "Old Worktrees (>30 days)"
        local old_list=$(echo "$analysis_output" | grep "^OLD:" | cut -d: -f2-)
        
        echo "Found $old_count old worktree(s):"
        IFS=' ' read -ra old_array <<< "$old_list"
        for item in "${old_array[@]}"; do
            IFS='|' read -r branch path age <<< "$item"
            echo "  - $branch: $path (${age} days old)"
        done
        
        echo
        read -p "Review old worktrees? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for item in "${old_array[@]}"; do
                IFS='|' read -r branch path age <<< "$item"
                echo
                echo "Branch: $branch (${age} days old)"
                echo "Path: $path"
                
                # Check if merged
                if is_branch_merged "$branch"; then
                    echo -e "Status: ${GREEN}Merged${NC}"
                else
                    echo -e "Status: ${YELLOW}Not merged${NC}"
                fi
                
                read -p "Remove this worktree? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_worktree "$branch" "$path"
                    ((cleaned_count++))
                fi
            done
        fi
    fi
    
    print_header "Cleanup Complete"
    print_success "Cleaned up $cleaned_count worktree(s)"
}

# Prune worktrees
prune_worktrees() {
    print_header "Pruning Worktrees"
    
    if [ "$DRY_RUN" = "true" ]; then
        print_info "[DRY RUN] Would run: git worktree prune"
    else
        git worktree prune
        print_success "Pruned worktree administrative files"
    fi
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
Claude Worktree Cleanup Tool

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --dry-run   Show what would be cleaned without doing it
    -a, --auto      Auto-confirm all prompts (use with caution!)
    -p, --prune     Only run git worktree prune
    -m, --merged    Clean only merged worktrees
    -o, --orphaned  Clean only orphaned worktrees
    --old [DAYS]    Clean worktrees older than DAYS (default: 30)

EXAMPLES:
    $(basename "$0")                # Interactive cleanup
    $(basename "$0") --dry-run      # Preview cleanup actions
    $(basename "$0") --merged       # Clean merged worktrees
    $(basename "$0") --auto         # Auto-cleanup (dangerous!)

This tool helps clean up:
  • Merged worktrees (branches fully merged to main)
  • Orphaned worktrees (missing directories)
  • Old worktrees (inactive for >30 days)
  • Administrative files (git worktree prune)

EOF
            ;;
        "--dry-run"|"-d")
            DRY_RUN="true"
            print_warning "DRY RUN MODE - No changes will be made"
            interactive_cleanup
            ;;
        "--auto"|"-a")
            AUTO_CLEANUP="true"
            print_warning "AUTO MODE - All prompts will be auto-confirmed"
            read -p "Are you sure? This will delete worktrees automatically! (yes/N): " -r
            if [ "$REPLY" = "yes" ]; then
                interactive_cleanup
            else
                print_error "Cancelled"
                exit 1
            fi
            ;;
        "--prune"|"-p")
            prune_worktrees
            ;;
        "--merged"|"-m")
            # TODO: Implement merged-only cleanup
            print_warning "Merged-only cleanup not yet implemented"
            ;;
        "--orphaned"|"-o")
            # TODO: Implement orphaned-only cleanup
            print_warning "Orphaned-only cleanup not yet implemented"
            ;;
        "--old")
            # TODO: Implement old worktree cleanup with custom days
            print_warning "Old worktree cleanup not yet implemented"
            ;;
        "")
            interactive_cleanup
            prune_worktrees
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"