# Worktree Status

Display the status of all Git worktrees in the current project.

## Commands to execute:

```bash
# Display header
echo "=== Git Worktree Status ==="
echo

# List all worktrees with details
git worktree list

echo
echo "=== Branch Status ==="
echo

# Get main branch name
if git show-ref --verify --quiet refs/heads/main; then
    main_branch="main"
elif git show-ref --verify --quiet refs/heads/master; then
    main_branch="master"
else
    main_branch="main"
fi

# Show status for each worktree
git worktree list | while read -r line; do
    worktree_path=$(echo "$line" | awk '{print $1}')
    branch=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')
    
    if [ -n "$branch" ] && [ "$branch" != "$main_branch" ]; then
        echo "Branch: $branch"
        echo "Path: $worktree_path"
        
        # Check if directory exists and has changes
        if [ -d "$worktree_path" ]; then
            cd "$worktree_path" 2>/dev/null && {
                # Check for uncommitted changes
                if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                    echo "Status: Has uncommitted changes"
                else
                    echo "Status: Clean"
                fi
                
                # Show ahead/behind status
                ahead=$(git rev-list --count "$main_branch..HEAD" 2>/dev/null || echo "0")
                behind=$(git rev-list --count "HEAD..$main_branch" 2>/dev/null || echo "0")
                echo "Commits: ↑$ahead ↓$behind (vs $main_branch)"
            }
        else
            echo "Status: Directory not found (orphaned)"
        fi
        echo
    fi
done

# Summary
total_worktrees=$(git worktree list | wc -l)
echo "Total worktrees: $total_worktrees"
```

## Information displayed:
- List of all worktrees with their paths and branches
- Status of each worktree (clean/has changes/orphaned)
- Number of commits ahead/behind the main branch
- Total count of worktrees

## Example usage:
- `/worktree-status` shows the status of all worktrees