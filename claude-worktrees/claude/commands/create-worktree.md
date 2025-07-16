# Create Git Worktree

Create a new Git worktree for the specified branch name.

## Steps:

1. Get the current project folder name using `basename "$PWD"`
2. Create a worktrees folder adjacent to the current project: `../[project-name]-worktrees`
3. Create a new worktree and branch with the provided name
4. Copy configuration files (.env, .claude, .cursor, .agentos, CLAUDE.md) if they exist
5. Change directory into the new worktree
6. Optionally open the worktree in the configured editor

## Commands to execute:

```bash
# Get the current project folder name
project_name=$(basename "$PWD")

# Create the worktrees folder if it doesn't exist
mkdir -p "../${project_name}-worktrees"

# Create the new worktree and branch
git worktree add -b "$1" "../${project_name}-worktrees/$1"

# Copy configuration files
for item in .env .claude .cursor .agentos CLAUDE.md; do
    if [ -e "$item" ]; then
        cp -R "$item" "../${project_name}-worktrees/$1/"
    fi
done

# Change directory into the new worktree
cd "../${project_name}-worktrees/$1"

# Show success message
echo "✓ Created worktree: $1"
echo "✓ Location: $(pwd)"
```

Note: Replace `$1` with the branch name provided as an argument to this command.

## Example usage:
- `/create-worktree feature-auth` creates a worktree for branch "feature-auth"
- `/create-worktree bugfix-123` creates a worktree for branch "bugfix-123"