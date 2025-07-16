#!/bin/bash

# Claude Worktree Status Dashboard
# Displays comprehensive status of all Git worktrees

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Symbols
CHECK_MARK="✓"
CROSS_MARK="✗"
WARNING_SIGN="⚠"
ARROW_UP="↑"
ARROW_DOWN="↓"
BRANCH_SYMBOL="⎇"

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

# Get worktree status details
get_worktree_details() {
    local worktree_path="$1"
    local branch="$2"
    local main_branch="$3"
    
    if [ ! -d "$worktree_path" ]; then
        echo "ERROR|Directory not found"
        return
    fi
    
    cd "$worktree_path" 2>/dev/null || {
        echo "ERROR|Cannot access directory"
        return
    }
    
    # Get status info
    local has_changes="false"
    local staged_files=0
    local modified_files=0
    local untracked_files=0
    
    # Check for changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        has_changes="true"
        modified_files=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Check for staged changes
    if ! git diff-index --quiet --cached HEAD -- 2>/dev/null; then
        has_changes="true"
        staged_files=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Check for untracked files
    untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$untracked_files" -gt 0 ]; then
        has_changes="true"
    fi
    
    # Get commit info
    local last_commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "none")
    local last_commit_date=$(git log -1 --format="%ar" 2>/dev/null || echo "never")
    local last_commit_msg=$(git log -1 --format="%s" 2>/dev/null | cut -c1-50)
    if [ ${#last_commit_msg} -eq 50 ]; then
        last_commit_msg="${last_commit_msg}..."
    fi
    
    # Get ahead/behind info
    local ahead=0
    local behind=0
    if [ "$branch" != "$main_branch" ]; then
        ahead=$(git rev-list --count "${main_branch}..HEAD" 2>/dev/null || echo "0")
        behind=$(git rev-list --count "HEAD..${main_branch}" 2>/dev/null || echo "0")
    fi
    
    # Get remote tracking info
    local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "none")
    local remote_ahead=0
    local remote_behind=0
    if [ "$remote_branch" != "none" ]; then
        remote_ahead=$(git rev-list --count "${remote_branch}..HEAD" 2>/dev/null || echo "0")
        remote_behind=$(git rev-list --count "HEAD..${remote_branch}" 2>/dev/null || echo "0")
    fi
    
    echo "OK|$has_changes|$staged_files|$modified_files|$untracked_files|$last_commit_hash|$last_commit_date|$last_commit_msg|$ahead|$behind|$remote_branch|$remote_ahead|$remote_behind"
}

# Format file count
format_file_count() {
    local count=$1
    local label=$2
    local color=$3
    
    if [ "$count" -gt 0 ]; then
        echo -e "${color}${count} ${label}${NC}"
    fi
}

# Print status header
print_header() {
    local project_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
    local main_branch=$(get_main_branch)
    local worktree_count=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}             ${CYAN}Claude Worktree Status Dashboard${NC}                 ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} Project: ${GREEN}$project_name${NC}"
    echo -e "${BLUE}║${NC} Main Branch: ${MAGENTA}$main_branch${NC}"
    echo -e "${BLUE}║${NC} Worktrees: ${YELLOW}$worktree_count${NC}"
    echo -e "${BLUE}║${NC} Generated: ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Print worktree status
print_worktree_status() {
    local worktree_path="$1"
    local branch="$2"
    local is_bare="$3"
    local main_branch="$4"
    local index="$5"
    
    # Skip bare repository
    if [ "$is_bare" = "true" ]; then
        return
    fi
    
    # Get current directory to restore later
    local original_dir=$(pwd)
    
    # Get worktree details
    local details=$(get_worktree_details "$worktree_path" "$branch" "$main_branch")
    IFS='|' read -r status has_changes staged modified untracked commit_hash commit_date commit_msg ahead behind remote_branch remote_ahead remote_behind <<< "$details"
    
    # Return to original directory
    cd "$original_dir"
    
    # Determine if this is the main branch
    local is_main="false"
    if [ "$branch" = "$main_branch" ]; then
        is_main="true"
    fi
    
    # Print worktree box
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────┐${NC}"
    
    # Branch name and status
    if [ "$is_main" = "true" ]; then
        echo -e "${BLUE}│${NC} ${CYAN}${BRANCH_SYMBOL}${NC} ${GREEN}${branch}${NC} ${GRAY}(main)${NC}"
    else
        echo -e "${BLUE}│${NC} ${CYAN}${BRANCH_SYMBOL}${NC} ${YELLOW}${branch}${NC}"
    fi
    
    # Path
    echo -e "${BLUE}│${NC} ${GRAY}📁 ${worktree_path}${NC}"
    
    # Status line
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────────┤${NC}"
    
    if [ "$status" = "ERROR" ]; then
        echo -e "${BLUE}│${NC} ${RED}${CROSS_MARK} Error: $has_changes${NC}"
    else
        # Changes status
        local changes_line="${BLUE}│${NC} "
        if [ "$has_changes" = "true" ]; then
            changes_line+="${RED}${WARNING_SIGN} Has changes: ${NC}"
            local items=()
            [ "$staged" -gt 0 ] && items+=("$(format_file_count $staged 'staged' $GREEN)")
            [ "$modified" -gt 0 ] && items+=("$(format_file_count $modified 'modified' $YELLOW)")
            [ "$untracked" -gt 0 ] && items+=("$(format_file_count $untracked 'untracked' $RED)")
            
            local first=true
            for item in "${items[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    changes_line+=", "
                fi
                changes_line+="$item"
            done
        else
            changes_line+="${GREEN}${CHECK_MARK} Clean working tree${NC}"
        fi
        echo -e "$changes_line"
        
        # Last commit
        echo -e "${BLUE}│${NC} ${GRAY}Last commit: ${commit_hash} - ${commit_date}${NC}"
        if [ -n "$commit_msg" ]; then
            echo -e "${BLUE}│${NC} ${GRAY}\"${commit_msg}\"${NC}"
        fi
        
        # Sync status with main
        if [ "$is_main" = "false" ] && [ "$ahead" -gt 0 -o "$behind" -gt 0 ]; then
            echo -e "${BLUE}│${NC} ${GRAY}vs ${main_branch}:${NC} ${GREEN}${ARROW_UP}${ahead}${NC} ${RED}${ARROW_DOWN}${behind}${NC}"
        fi
        
        # Remote tracking
        if [ "$remote_branch" != "none" ]; then
            local remote_status="${GRAY}Remote: ${remote_branch}"
            if [ "$remote_ahead" -gt 0 -o "$remote_behind" -gt 0 ]; then
                remote_status+=" ${GREEN}${ARROW_UP}${remote_ahead}${NC} ${RED}${ARROW_DOWN}${remote_behind}${NC}"
            else
                remote_status+=" ${GREEN}${CHECK_MARK}${NC}"
            fi
            echo -e "${BLUE}│${NC} $remote_status"
        fi
    fi
    
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Print summary
print_summary() {
    local total_worktrees=$1
    local worktrees_with_changes=$2
    local total_ahead=$3
    local total_behind=$4
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                          ${CYAN}Summary${NC}                              ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} Total worktrees: ${YELLOW}$total_worktrees${NC}"
    echo -e "${BLUE}║${NC} With uncommitted changes: ${RED}$worktrees_with_changes${NC}"
    
    if [ "$total_ahead" -gt 0 ] || [ "$total_behind" -gt 0 ]; then
        echo -e "${BLUE}║${NC} Total commits: ${GREEN}${ARROW_UP}${total_ahead}${NC} ${RED}${ARROW_DOWN}${total_behind}${NC} (vs main)"
    fi
    
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Main function
main() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not in a Git repository${NC}"
        exit 1
    fi
    
    # Get main branch
    local main_branch=$(get_main_branch)
    
    # Print header
    print_header
    
    # Process worktrees
    local index=1
    local total_worktrees=0
    local worktrees_with_changes=0
    local total_ahead=0
    local total_behind=0
    
    while IFS= read -r line; do
        # Parse worktree list output
        local worktree_path=$(echo "$line" | awk '{print $1}')
        local commit_hash=$(echo "$line" | awk '{print $2}')
        local branch_info=$(echo "$line" | cut -d' ' -f3-)
        
        # Extract branch name
        local branch=""
        local is_bare="false"
        
        if [[ "$branch_info" =~ \[([^\]]+)\] ]]; then
            branch="${BASH_REMATCH[1]}"
        elif [[ "$branch_info" == "(bare)" ]]; then
            is_bare="true"
        fi
        
        if [ "$is_bare" = "false" ]; then
            print_worktree_status "$worktree_path" "$branch" "$is_bare" "$main_branch" "$index"
            ((total_worktrees++))
            
            # Count statistics
            local details=$(get_worktree_details "$worktree_path" "$branch" "$main_branch")
            local has_changes=$(echo "$details" | cut -d'|' -f2)
            local ahead=$(echo "$details" | cut -d'|' -f9)
            local behind=$(echo "$details" | cut -d'|' -f10)
            
            if [ "$has_changes" = "true" ]; then
                ((worktrees_with_changes++))
            fi
            
            if [ "$branch" != "$main_branch" ]; then
                total_ahead=$((total_ahead + ahead))
                total_behind=$((total_behind + behind))
            fi
            
            ((index++))
        fi
    done < <(git worktree list)
    
    # Print summary
    print_summary "$total_worktrees" "$worktrees_with_changes" "$total_ahead" "$total_behind"
    
    # Quick actions hint
    echo -e "\n${GRAY}Quick actions:${NC}"
    echo -e "${GRAY}  • Create worktree: ${NC}wt <branch-name>"
    echo -e "${GRAY}  • Merge worktree: ${NC}wtm [branch-name]"
    echo -e "${GRAY}  • Clean worktrees: ${NC}wtc"
    echo
}

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        cat << EOF
Claude Worktree Status Dashboard

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
    -h, --help    Show this help message
    -w, --watch   Watch mode (refresh every 5 seconds)

This tool displays a comprehensive status dashboard for all Git worktrees
in the current repository, including:
  • Branch names and paths
  • Uncommitted changes (staged, modified, untracked)
  • Commit history
  • Sync status with main branch
  • Remote tracking status

EOF
        ;;
    "--watch"|"-w")
        while true; do
            clear
            main
            sleep 5
        done
        ;;
    *)
        main
        ;;
esac