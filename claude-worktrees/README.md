# Claude Worktrees Tool

A comprehensive Git worktree management tool designed for parallel development with Claude agents. This tool automates the creation, management, and merging of Git worktrees, enabling multiple Claude instances to work on different features simultaneously without conflicts.

## 🚀 Quick Start

```bash
# Run the setup script
./setup.sh

# Source your shell configuration
source ~/.zshrc  # or ~/.bashrc

# Create your first worktree
wt feature-awesome
```

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Commands](#commands)
- [Configuration](#configuration)
- [Claude Integration](#claude-integration)
- [Workflow Examples](#workflow-examples)
- [Troubleshooting](#troubleshooting)

## ✨ Features

### Core Features
- **Automated Worktree Creation**: Create Git worktrees with a single command
- **Configuration Preservation**: Automatically copies `.env`, `.claude`, `.cursor`, and other config files
- **Editor Integration**: Opens worktrees in Cursor or VS Code automatically
- **Interactive Management**: User-friendly menus for all operations
- **Smart Merging**: Handles merge, rebase, and squash strategies
- **Visual Dashboard**: Comprehensive status view of all worktrees
- **Cleanup Utilities**: Remove merged, orphaned, or old worktrees

### Manager Project Integration
- Track which Claude agent works on which worktree
- Coordinate between multiple parallel agents
- Maintain clean separation of concerns
- Enable true multitasking with Claude

## 📦 Installation

### Prerequisites
- Git 2.5+ (for worktree support)
- Bash or Zsh shell
- Cursor or VS Code (optional, for editor integration)

### Setup Steps

1. **Clone or download this tool**:
   ```bash
   cd /Users/chrisshaw/Code/tools/claude-worktrees
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```
   
   This will:
   - Check prerequisites
   - Create configuration file
   - Install shell functions
   - Set up Claude slash commands

3. **Reload your shell**:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

## 🔧 Usage

### Basic Commands

```bash
# Create a new worktree
wt feature-auth

# List all worktrees
wtl

# Show worktree status dashboard
wts

# Merge a worktree branch
wtm feature-auth

# Clean up old worktrees
wtc
```

### Direct Script Usage

```bash
# Create worktree with specific editor
./claude-worktree.sh -e code feature-api

# Merge with rebase strategy
./merge-worktrees.sh -s rebase feature-auth

# Dry run cleanup to preview changes
./cleanup-worktrees.sh --dry-run

# Watch status in real-time
./worktree-status.sh --watch
```

## 📚 Commands

### Shell Functions (after setup)

| Command | Description |
|---------|-------------|
| `wt <branch>` | Create new worktree and open in editor |
| `wtl` | List all worktrees |
| `wts` | Show detailed status dashboard |
| `wtm [branch]` | Merge worktree (interactive if no branch specified) |
| `wtc` | Clean up old/merged worktrees |

### Script Options

#### claude-worktree.sh
```bash
Usage: claude-worktree.sh [OPTIONS] [BRANCH_NAME]

OPTIONS:
    -l, --list       List all worktrees
    -h, --help       Show help message
    -n, --no-editor  Don't open editor after creation
    -e, --editor     Specify editor (cursor, code, vscode)
```

#### merge-worktrees.sh
```bash
Usage: merge-worktrees.sh [OPTIONS] [BRANCH_NAME]

OPTIONS:
    -h, --help         Show help message
    -s, --strategy     Merge strategy (merge, rebase, squash)
    -a, --auto         Auto-confirm prompts
    -l, --list         List branches only
```

#### cleanup-worktrees.sh
```bash
Usage: cleanup-worktrees.sh [OPTIONS]

OPTIONS:
    -h, --help      Show help message
    -d, --dry-run   Preview cleanup without changes
    -a, --auto      Auto-confirm all prompts
    -p, --prune     Only run git worktree prune
```

## ⚙️ Configuration

Configuration file location: `~/.claude-worktree.config`

```bash
# Default editor (Cursor, code, vscode)
EDITOR="Cursor"

# Files/folders to copy to new worktrees
FOLDERS_TO_COPY=".env .claude .cursor .agentos"

# Branch naming prefix (optional)
# BRANCH_PREFIX="feature/"

# Automatic cleanup of merged worktrees
AUTO_CLEANUP="false"

# Default merge strategy (merge, rebase, squash)
MERGE_STRATEGY="merge"
```

## 🤖 Claude Integration

### Slash Commands

After setup, these commands are available in Claude:

- `/create-worktree <branch-name>` - Create new worktree
- `/merge-worktree [branch-name]` - Merge worktree branch
- `/worktree-status` - Show worktree status

### CLAUDE.md Integration

Add to your project's CLAUDE.md:
```markdown
## Worktree Workflow
- Use `/create-worktree feature-name` to start new features
- Each worktree represents an independent task
- Use `/worktree-status` to check progress
- Use `/merge-worktree` when feature is complete
```

## 📖 Workflow Examples

### Example 1: Multiple Features in Parallel

```bash
# Terminal 1: Create auth feature worktree
wt feature-auth
# Claude agent 1 works on authentication

# Terminal 2: Create API feature worktree
wt feature-api
# Claude agent 2 works on API endpoints

# Terminal 3: Create UI feature worktree
wt feature-ui
# Claude agent 3 works on user interface

# Check status of all work
wts

# Merge completed features
wtm feature-auth
wtm feature-api
wtm feature-ui
```

### Example 2: Bug Fix Workflow

```bash
# Create bugfix worktree
wt bugfix-123

# Work on the fix...
# When complete, merge with squash
./merge-worktrees.sh -s squash bugfix-123

# Clean up
wtc
```

### Example 3: Manager Project Integration

1. Manager project creates task list
2. For each task, create a worktree:
   ```bash
   wt task-database-schema
   wt task-api-endpoints
   wt task-frontend-components
   ```
3. Assign each worktree to a Claude agent
4. Monitor progress with `wts`
5. Merge completed tasks back to main

## 🛠️ Advanced Usage

### Custom Branch Prefixes

Add to your shell configuration:
```bash
alias wtf='wt feature/'
alias wtb='wt bugfix/'
alias wth='wt hotfix/'
```

Usage:
```bash
wtf user-auth    # Creates feature/user-auth
wtb issue-123    # Creates bugfix/issue-123
```

### Automated Workflows

Create a script for your workflow:
```bash
#!/bin/bash
# create-feature.sh

feature_name="$1"
wt "feature-$feature_name"
echo "Created worktree for feature: $feature_name"
echo "Agent can now work in: ../$(basename $PWD)-worktrees/feature-$feature_name"
```

## 🔍 Status Dashboard Features

The `wts` command shows:
- Branch name and type (main/feature)
- Working directory path
- Uncommitted changes (staged, modified, untracked)
- Last commit information
- Sync status with main branch
- Remote tracking status

Example output:
```
╔═══════════════════════════════════════════════════════════════╗
║             Claude Worktree Status Dashboard                   ║
╠═══════════════════════════════════════════════════════════════╣
║ Project: my-project
║ Main Branch: main
║ Worktrees: 3
║ Generated: 2025-01-16 10:30:45
╚═══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│ ⎇ feature-auth
│ 📁 /path/to/my-project-worktrees/feature-auth
├─────────────────────────────────────────────────────────────────┤
│ ✓ Clean working tree
│ Last commit: abc123 - 2 hours ago
│ "Add authentication middleware"
│ vs main: ↑5 ↓0
└─────────────────────────────────────────────────────────────────┘
```

## 🚨 Troubleshooting

### Common Issues

1. **"Not in a Git repository" error**
   - Ensure you're in a Git repository before running commands
   - Initialize with `git init` if needed

2. **Editor doesn't open automatically**
   - Check your configuration: `cat ~/.claude-worktree.config`
   - Ensure editor is installed and in PATH
   - Use `-n` flag to skip editor opening

3. **Permission denied errors**
   - Ensure scripts are executable: `chmod +x *.sh`
   - Check directory permissions

4. **Worktree already exists**
   - Use a different branch name
   - Or remove existing worktree first: `git worktree remove <path>`

### Debug Mode

Run scripts with bash debug mode:
```bash
bash -x ./claude-worktree.sh feature-test
```

## 📝 Best Practices

1. **Branch Naming**: Use descriptive names (feature-auth, bugfix-123)
2. **Regular Cleanup**: Run `wtc` weekly to remove old worktrees
3. **Commit Often**: Keep worktrees clean with regular commits
4. **Update Main**: Pull main branch regularly before merging
5. **Document Tasks**: Update CLAUDE.md with active worktrees

## 🤝 Contributing

Improvements and bug fixes are welcome! The tool is designed to be extensible.

## 📄 License

This tool is part of the Claude Worktrees toolkit and is available for use in Claude-assisted development workflows.

## 🙏 Acknowledgments

Based on the workflow described in Brian Casel's video "Claude Code Multitasking Made EASY" and enhanced for the Manager project requirements.