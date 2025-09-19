#!/bin/bash
# Git Hook Installation Script
# Installs all git hooks to prevent workflow violations

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.git/hooks"
SOURCE_HOOKS_DIR="$REPO_ROOT/scripts/git-hooks"

echo "🔧 Installing Git Hooks for Workflow Protection"
echo "=============================================="

# Ensure hooks directory exists
mkdir -p "$HOOKS_DIR"

# Install each hook
for hook_file in "$SOURCE_HOOKS_DIR"/*; do
    if [[ -f "$hook_file" ]]; then
        hook_name=$(basename "$hook_file")
        target_path="$HOOKS_DIR/$hook_name"
        
        echo "📝 Installing $hook_name..."
        cp "$hook_file" "$target_path"
        chmod +x "$target_path"
        echo "   ✅ $hook_name installed and made executable"
    fi
done

echo ""
echo "🎯 Protection Summary:"
echo "   • Direct commits to develop/main/master blocked"
echo "   • Automatic feature branch workflow enforcement" 
echo "   • Clear guidance provided on proper workflow"
echo ""
echo "✅ Git hooks installation complete!"
echo ""
echo "🚀 Next steps:"
echo "   • All team members should run: ./scripts/install-git-hooks.sh"
echo "   • This ensures consistent workflow protection across all clones"
