#!/bin/bash

echo "🚀 Creating GitHub repository for tools"

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "📝 Please authenticate with GitHub first:"
    gh auth login
fi

echo ""
echo "📦 Creating repository on VetOnce organization..."

# Create the repository
gh repo create VetOnce/tools \
    --private \
    --description "Internal tools and utilities for VetOnce" \
    --source=. \
    --remote=origin \
    --push

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Repository created successfully!"
    echo "🔗 Repository URL: https://github.com/VetOnce/tools"
    echo ""
    echo "📊 Repository contents:"
    git ls-tree --name-only -r HEAD | head -20
    echo ""
    echo "You can now access your repository at:"
    echo "https://github.com/VetOnce/tools"
else
    echo ""
    echo "❌ Failed to create repository"
    echo ""
    echo "Alternative manual steps:"
    echo "1. Create repo at: https://github.com/organizations/VetOnce/repositories/new"
    echo "2. Then run:"
    echo "   git remote add origin https://github.com/VetOnce/tools.git"
    echo "   git push -u origin master"
fi