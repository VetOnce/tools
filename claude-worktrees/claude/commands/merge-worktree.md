# Merge Git Worktree

Merge a worktree branch back into the main branch and optionally clean up.

## Steps:

1. Save the current branch name for reference
2. Determine the main branch (main or master)
3. Check out the main branch
4. Pull latest changes from origin
5. Merge the specified branch
6. Optionally remove the worktree and delete the branch

## Commands to execute:

```bash
# Get the branch to merge (use provided argument or current branch)
branch_to_merge="${1:-$(git branch --show-current)}"

# Determine main branch
if git show-ref --verify --quiet refs/heads/main; then
    main_branch="main"
elif git show-ref --verify --quiet refs/heads/master; then
    main_branch="master"
else
    echo "Error: Cannot find main or master branch"
    exit 1
fi

# Save current location
current_dir=$(pwd)

# Check out main branch
git checkout "$main_branch"

# Pull latest changes
git pull origin "$main_branch" || echo "Could not pull from origin"

# Merge the branch
echo "Merging $branch_to_merge into $main_branch..."
git merge "$branch_to_merge" --no-edit

# Success message
echo "✓ Successfully merged $branch_to_merge into $main_branch"

# Optional: Show merge status
git log --oneline -5
```

## Post-merge cleanup (manual steps):

After merging, you may want to:
1. Remove the worktree: `git worktree remove ../[project]-worktrees/[branch]`
2. Delete the local branch: `git branch -d [branch]`
3. Delete the remote branch: `git push origin --delete [branch]`
4. Push the updated main branch: `git push origin [main-branch]`

## Example usage:
- `/merge-worktree` merges the current branch
- `/merge-worktree feature-auth` merges the "feature-auth" branch