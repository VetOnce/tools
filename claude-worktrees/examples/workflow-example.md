# Claude Worktrees Workflow Examples

This document provides detailed, step-by-step examples of using the Claude Worktrees tool in real-world scenarios.

## Example 1: E-Commerce Site Development

### Scenario
You're building an e-commerce site with multiple features that need parallel development:
- User authentication system
- Product catalog
- Shopping cart functionality
- Payment integration

### Step-by-Step Workflow

#### 1. Initial Setup
```bash
# Navigate to your project
cd ~/Projects/ecommerce-site

# Run the worktrees setup (first time only)
~/Code/tools/claude-worktrees/setup.sh

# Source your shell
source ~/.zshrc
```

#### 2. Create Worktrees for Each Feature
```bash
# Terminal 1: Authentication feature
wt feature-auth
# This creates: ../ecommerce-site-worktrees/feature-auth
# Cursor/VS Code opens automatically

# Terminal 2: Product catalog
wt feature-catalog
# This creates: ../ecommerce-site-worktrees/feature-catalog

# Terminal 3: Shopping cart
wt feature-cart
# This creates: ../ecommerce-site-worktrees/feature-cart

# Terminal 4: Payment integration
wt feature-payment
# This creates: ../ecommerce-site-worktrees/feature-payment
```

#### 3. Assign Claude Agents
In each terminal/editor window:

**Terminal 1 - Authentication:**
```
You: Implement user authentication with JWT tokens. Include:
- User registration endpoint
- Login endpoint
- Password reset functionality
- Protected route middleware
```

**Terminal 2 - Product Catalog:**
```
You: Create a product catalog system with:
- Product model and database schema
- CRUD API endpoints
- Category management
- Search functionality
```

**Terminal 3 - Shopping Cart:**
```
You: Build shopping cart functionality:
- Add/remove items
- Update quantities
- Calculate totals
- Persist cart in session
```

**Terminal 4 - Payment:**
```
You: Integrate Stripe payment processing:
- Payment intent creation
- Webhook handling
- Order confirmation
- Receipt generation
```

#### 4. Monitor Progress
```bash
# In main project directory, check status
wts
```

Output shows:
```
╔═══════════════════════════════════════════════════════════════╗
║             Claude Worktree Status Dashboard                   ║
╠═══════════════════════════════════════════════════════════════╣
║ Project: ecommerce-site
║ Main Branch: main
║ Worktrees: 5
╚═══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│ ⎇ feature-auth
│ 📁 ../ecommerce-site-worktrees/feature-auth
│ ⚠ Has changes: 12 modified, 3 untracked
│ Last commit: abc123 - 10 minutes ago
│ "Add JWT authentication middleware"
│ vs main: ↑8 ↓0
└─────────────────────────────────────────────────────────────────┘

[... similar status for other worktrees ...]
```

#### 5. Merge Completed Features
As each feature is completed:

```bash
# First, ensure the feature is fully tested
cd ../ecommerce-site-worktrees/feature-auth
npm test

# Return to main project
cd ~/Projects/ecommerce-site

# Merge the authentication feature
wtm feature-auth
# Select merge strategy when prompted
# Review changes and confirm

# Repeat for other completed features
wtm feature-catalog
wtm feature-cart
```

#### 6. Clean Up
```bash
# Remove merged worktrees
wtc
# Review and confirm cleanup of merged branches
```

## Example 2: Bug Fix Sprint

### Scenario
You have multiple bug reports that need fixing simultaneously:
- Bug #101: Login form validation
- Bug #102: Cart total calculation
- Bug #103: Image upload timeout

### Workflow

```bash
# Create worktrees for each bug
wt bugfix-101-login-validation
wt bugfix-102-cart-calculation
wt bugfix-103-image-upload

# Check current status
wtl

# For each bugfix, in separate terminals:
# Bug #101
You: Fix the login form validation issue where email validation 
     allows invalid formats. Update tests.

# Bug #102
You: Fix cart total calculation that doesn't include tax 
     for certain states. Add test cases.

# Bug #103
You: Increase image upload timeout and add progress indicator.
     Handle large file uploads gracefully.

# After fixes are complete, merge with squash
./merge-worktrees.sh -s squash bugfix-101-login-validation
./merge-worktrees.sh -s squash bugfix-102-cart-calculation
./merge-worktrees.sh -s squash bugfix-103-image-upload

# Clean up all bugfix branches
wtc
```

## Example 3: Feature Development with Code Review

### Scenario
Developing a new feature that requires code review before merging.

### Workflow

```bash
# 1. Create feature branch
wt feature-user-profile

# 2. Develop feature with Claude
You: Implement user profile functionality with:
     - Profile viewing page
     - Profile editing
     - Avatar upload
     - Privacy settings

# 3. When feature is ready, push to remote
cd ../myproject-worktrees/feature-user-profile
git push -u origin feature-user-profile

# 4. Create pull request (using GitHub CLI)
gh pr create --title "Add user profile functionality" \
  --body "Implements user profile with editing and avatar upload"

# 5. After PR approval, merge via worktree tool
cd ~/Projects/myproject
wtm feature-user-profile

# 6. Clean up
wtc
```

## Example 4: Hotfix During Feature Development

### Scenario
You're working on a feature when a critical bug needs immediate fixing.

### Workflow

```bash
# You're currently working on a feature
cd ../myproject-worktrees/feature-new-dashboard

# Critical bug reported! Create hotfix without disrupting feature work
cd ~/Projects/myproject
wt hotfix-critical-security-issue

# Fix the issue with Claude
You: Fix the SQL injection vulnerability in the user search endpoint.
     Sanitize all inputs and add security tests.

# Test the hotfix
cd ../myproject-worktrees/hotfix-critical-security-issue
npm test

# Merge hotfix immediately
cd ~/Projects/myproject
wtm hotfix-critical-security-issue

# Push to production
git push origin main

# Continue with feature development
cd ../myproject-worktrees/feature-new-dashboard
# Pull latest changes including hotfix
git pull origin main
```

## Example 5: Refactoring Project

### Scenario
Large refactoring split across multiple areas.

### Workflow

```bash
# Create worktrees for each refactoring area
wt refactor-database-layer
wt refactor-api-structure  
wt refactor-frontend-components

# Status check shows all refactoring branches
wts

# Work on each refactoring in parallel
# Database layer: Convert callbacks to async/await
# API structure: Implement proper REST conventions
# Frontend: Convert class components to hooks

# Merge in specific order (database first, then API, then frontend)
wtm refactor-database-layer
# Test everything still works

wtm refactor-api-structure
# Test API endpoints

wtm refactor-frontend-components
# Final testing

# Cleanup
wtc
```

## Best Practices from Examples

1. **Clear Branch Names**: Use descriptive prefixes (feature-, bugfix-, hotfix-, refactor-)
2. **Regular Status Checks**: Run `wts` frequently to monitor progress
3. **Test Before Merging**: Always test in the worktree before merging
4. **Clean Up Regularly**: Use `wtc` after merging to keep workspace clean
5. **Document in CLAUDE.md**: Keep track of active worktrees in your project's CLAUDE.md

## Manager Project Integration Example

For projects using the Manager pattern:

```markdown
# In CLAUDE.md

## Active Worktrees
- feature-auth: Implementing authentication (Agent 1)
- feature-api: Building REST API (Agent 2)  
- feature-ui: Creating React components (Agent 3)
- bugfix-102: Fixing cart calculation (Agent 4)

## Worktree Commands
- Create: `wt branch-name` or `/create-worktree branch-name`
- Status: `wts` or `/worktree-status`
- Merge: `wtm branch-name` or `/merge-worktree branch-name`
```

This allows the Manager to coordinate multiple Claude agents effectively.