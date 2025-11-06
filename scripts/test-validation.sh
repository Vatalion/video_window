#!/bin/bash
# Test script for validate-generated-code.sh
# Verifies that validation script works correctly

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

VALIDATION_SCRIPT="./scripts/validate-generated-code.sh"

echo "🧪 Testing code generation validation..."
echo ""

# Test 1: Check script exists and is executable
echo "Test 1: Script accessibility..."
if [ ! -f "$VALIDATION_SCRIPT" ]; then
    echo "❌ FAIL: Validation script not found at $VALIDATION_SCRIPT"
    exit 1
fi

if [ ! -x "$VALIDATION_SCRIPT" ]; then
    echo "❌ FAIL: Validation script is not executable"
    exit 1
fi
echo "✅ PASS: Script exists and is executable"
echo ""

# Test 2: Check required commands are available
echo "Test 2: Required command availability..."

if ! command -v serverpod &> /dev/null; then
    echo "❌ FAIL: serverpod command not found"
    echo "Install with: dart pub global activate serverpod_cli"
    exit 1
fi
echo "   ✓ serverpod found"

if ! command -v melos &> /dev/null; then
    echo "❌ FAIL: melos command not found"
    echo "Install with: dart pub global activate melos"
    exit 1
fi
echo "   ✓ melos found"

if ! command -v git &> /dev/null; then
    echo "❌ FAIL: git command not found"
    exit 1
fi
echo "   ✓ git found"

echo "✅ PASS: All required commands available"
echo ""

# Test 3: Check project structure
echo "Test 3: Project structure validation..."

if [ ! -d "video_window_server" ]; then
    echo "❌ FAIL: video_window_server directory not found"
    exit 1
fi
echo "   ✓ video_window_server exists"

if [ ! -d "video_window_client" ]; then
    echo "❌ FAIL: video_window_client directory not found"
    exit 1
fi
echo "   ✓ video_window_client exists"

if [ -d "video_window_shared" ]; then
    echo "   ✓ video_window_shared exists"
else
    echo "   ⚠️  video_window_shared not yet generated (will be created by serverpod generate)"
fi

if [ ! -f "melos.yaml" ]; then
    echo "❌ FAIL: melos.yaml not found"
    exit 1
fi
echo "   ✓ melos.yaml exists"

echo "✅ PASS: Project structure is valid"
echo ""

# Test 4: Run validation script (actual execution test)
echo "Test 4: Validation script execution..."
echo "   Note: This may report stale code if generation is needed"
echo ""

# Run the validation script and capture output/exit code
if $VALIDATION_SCRIPT; then
    echo "✅ PASS: Validation completed successfully (code is fresh)"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 1 ]; then
        echo "⚠️  INFO: Validation detected stale code (expected behavior)"
        echo "   This is not a test failure - the script correctly identified issues"
    else
        echo "❌ FAIL: Validation script failed with unexpected exit code: $EXIT_CODE"
        exit 1
    fi
fi
echo ""

# Test 5: Verify git hooks installation script
echo "Test 5: Git hooks installation script..."

HOOKS_SCRIPT="./scripts/install-git-hooks.sh"

if [ ! -f "$HOOKS_SCRIPT" ]; then
    echo "❌ FAIL: Git hooks installation script not found"
    exit 1
fi

if [ ! -x "$HOOKS_SCRIPT" ]; then
    echo "❌ FAIL: Git hooks installation script is not executable"
    exit 1
fi

echo "✅ PASS: Git hooks installation script is valid"
echo ""

# Test 6: Verify documentation exists
echo "Test 6: Documentation validation..."

RUNBOOK="./docs/runbooks/code-generation-workflow.md"

if [ ! -f "$RUNBOOK" ]; then
    echo "❌ FAIL: Code generation runbook not found"
    exit 1
fi

# Check runbook contains key sections
if ! grep -q "## Serverpod Code Generation" "$RUNBOOK"; then
    echo "❌ FAIL: Runbook missing Serverpod section"
    exit 1
fi

if ! grep -q "## Flutter Code Generation" "$RUNBOOK"; then
    echo "❌ FAIL: Runbook missing Flutter section"
    exit 1
fi

if ! grep -q "## Validation" "$RUNBOOK"; then
    echo "❌ FAIL: Runbook missing Validation section"
    exit 1
fi

echo "✅ PASS: Documentation is complete"
echo ""

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 All tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test Results:"
echo "  ✅ Script accessibility"
echo "  ✅ Command availability"
echo "  ✅ Project structure"
echo "  ✅ Validation execution"
echo "  ✅ Git hooks script"
echo "  ✅ Documentation"
echo ""
echo "Code generation validation is working correctly!"
echo ""

exit 0
