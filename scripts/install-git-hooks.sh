#!/bin/bash
# Install Git hooks for the Video Window project
# This script sets up pre-commit validation for generated code

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

HOOKS_DIR=".git/hooks"

echo "🔧 Installing Git hooks..."
echo ""

# Check if .git directory exists
if [ ! -d ".git" ]; then
    echo "❌ Error: .git directory not found"
    echo "Please run this script from the project root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
echo "📝 Installing pre-commit hook..."

cat > "$HOOKS_DIR/pre-commit" << 'HOOK_EOF'
#!/bin/bash
# Pre-commit hook to validate generated code
# Auto-installed by scripts/install-git-hooks.sh

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

echo "🔍 Running pre-commit checks..."
echo ""

# Run the validation script
if [ -f "$PROJECT_ROOT/scripts/validate-generated-code.sh" ]; then
    "$PROJECT_ROOT/scripts/validate-generated-code.sh"
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "❌ Pre-commit validation failed!"
        echo "Please fix the issues above and try again."
        echo ""
        echo "To skip this check (not recommended):"
        echo "  git commit --no-verify"
        exit 1
    fi
else
    echo "⚠️  Warning: validation script not found"
    echo "Expected: $PROJECT_ROOT/scripts/validate-generated-code.sh"
fi

echo "✅ Pre-commit checks passed!"
echo ""
HOOK_EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed successfully"
echo ""
echo "The hook will validate:"
echo "  - Serverpod generated code is fresh"
echo "  - Flutter generated code is fresh"
echo ""
echo "To skip the hook (not recommended):"
echo "  git commit --no-verify"
echo ""
echo "To uninstall:"
echo "  rm .git/hooks/pre-commit"
echo ""

exit 0
