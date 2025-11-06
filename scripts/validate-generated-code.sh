#!/bin/bash
# Validates that all generated code is up-to-date
# Usage: ./scripts/validate-generated-code.sh
# Exit code: 0 = success, 1 = stale code detected

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔍 Validating generated code..."
echo ""

# Step 1: Serverpod generation check
echo "📦 Checking Serverpod generated code..."
cd video_window_server

# Check if serverpod command exists
if ! command -v serverpod &> /dev/null; then
    echo "❌ serverpod command not found!"
    echo "Install with: dart pub global activate serverpod_cli"
    exit 1
fi

# Run generation
echo "   Running: serverpod generate"
serverpod generate > /dev/null 2>&1

# Check for changes in generated files
SERVERPOD_CHANGED=false

if ! git diff --quiet --exit-code lib/src/generated/ 2>/dev/null; then
    SERVERPOD_CHANGED=true
    echo "   ⚠️  Changes detected in lib/src/generated/"
fi

cd ..

if ! git diff --quiet --exit-code video_window_client/ 2>/dev/null; then
    SERVERPOD_CHANGED=true
    echo "   ⚠️  Changes detected in video_window_client/"
fi

if ! git diff --quiet --exit-code video_window_shared/ 2>/dev/null; then
    SERVERPOD_CHANGED=true
    echo "   ⚠️  Changes detected in video_window_shared/"
fi

if [ "$SERVERPOD_CHANGED" = true ]; then
    echo ""
    echo "❌ Serverpod generated code is STALE!"
    echo ""
    echo "To fix, run:"
    echo "  cd video_window_server"
    echo "  serverpod generate"
    echo "  cd .."
    echo "  git add video_window_server/lib/src/generated/ video_window_client/ video_window_shared/"
    echo "  git commit -m 'chore: update serverpod generated code'"
    echo ""
    exit 1
else
    echo "   ✅ Serverpod generated code is fresh"
fi

echo ""

# Step 2: Flutter build_runner generation check
echo "📱 Checking Flutter generated code..."

# Check if melos command exists
if ! command -v melos &> /dev/null; then
    echo "❌ melos command not found!"
    echo "Install with: dart pub global activate melos"
    exit 1
fi

# Run generation
echo "   Running: melos run generate"
melos run generate > /dev/null 2>&1

# Check for changes in .g.dart and .freezed.dart files
FLUTTER_CHANGED=false

# Find all generated files and check if they changed
if git diff --quiet --exit-code -- '*.g.dart' '*.freezed.dart' 2>/dev/null; then
    echo "   ✅ Flutter generated code is fresh"
else
    FLUTTER_CHANGED=true
    echo "   ⚠️  Changes detected in generated Dart files"
fi

if [ "$FLUTTER_CHANGED" = true ]; then
    echo ""
    echo "❌ Flutter generated code is STALE!"
    echo ""
    echo "To fix, run:"
    echo "  melos run generate"
    echo "  git add ."
    echo "  git commit -m 'chore: update flutter generated code'"
    echo ""
    echo "Changed files:"
    git diff --name-only -- '*.g.dart' '*.freezed.dart' 2>/dev/null | head -20
    echo ""
    exit 1
fi

echo ""
echo "✅ All generated code is up-to-date!"
echo ""

exit 0
