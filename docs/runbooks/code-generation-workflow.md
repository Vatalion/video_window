# Code Generation Workflow Runbook

**Last Updated:** 2025-11-06  
**Maintainer:** DevOps Team  
**Related Stories:** 01-3

---

## Overview

This runbook documents the complete code generation workflow for the Video Window project, covering both Serverpod backend generation and Flutter build_runner generation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Serverpod Code Generation](#serverpod-code-generation)
3. [Flutter Code Generation](#flutter-code-generation)
4. [Validation](#validation)
5. [Troubleshooting](#troubleshooting)
6. [CI/CD Integration](#cicd-integration)

---

## Prerequisites

### Required Tools

- **Serverpod CLI:** >= 2.9.0
- **Melos:** Latest (installed globally via `dart pub global activate melos`)
- **Dart SDK:** >= 3.5.6
- **Flutter SDK:** >= 3.19.6

### Verify Installation

```bash
# Check Serverpod version
serverpod --version

# Check Melos installation
melos --version

# Check Dart/Flutter versions
dart --version
flutter --version
```

---

## Serverpod Code Generation

### When to Run

Execute `serverpod generate` after:
- ✅ Creating/modifying protocol files (`.yaml` in `video_window_server/lib/src/protocol/`)
- ✅ Changing endpoint signatures
- ✅ Adding new endpoints
- ✅ Updating database table definitions
- ✅ Modifying any server models

### Command

```bash
# Navigate to server directory
cd video_window_server

# Generate code
serverpod generate
```

### What Gets Generated

1. **Server-side Code:**
   - `lib/src/generated/protocol.dart` - Combined protocol export
   - `lib/src/generated/endpoints.dart` - Endpoint registry
   - Model classes for each protocol file

2. **Client Package (`video_window_client/`):**
   - `lib/src/protocol/*.dart` - Client-side model classes
   - `lib/src/endpoint/*.dart` - Endpoint client classes
   - Type-safe API client methods

3. **Shared Package (`video_window_shared/`):**
   - Shared model definitions used by both client and server

### Example Output

```
Analyzing protocol files...
✓ Found 15 protocol files
✓ Generating server code...
✓ Generating client code...
✓ Generating shared code...
✓ Formatting generated files...

Code generation complete! (2.1s)
Generated:
  - 45 server files
  - 30 client files
  - 15 shared files
```

### Testing Generation

```bash
# Run generation
cd video_window_server
serverpod generate

# Verify no errors
echo $?  # Should output: 0

# Check generated files exist
ls -la lib/src/generated/
ls -la ../video_window_client/lib/src/protocol/
```

---

## Flutter Code Generation

### When to Run

Execute `melos run generate` after:
- ✅ Adding `@JsonSerializable()` annotations
- ✅ Creating new `@freezed` classes
- ✅ Adding `build_runner` code generation annotations
- ✅ Modifying any files with `.g.dart` or `.freezed.dart` counterparts

### Command

```bash
# From project root OR video_window_flutter directory
melos run generate
```

### What Gets Generated

This runs `build_runner` across all packages that have code generation needs:

- **JSON serialization:** `*.g.dart` files for JSON serialization/deserialization
- **Freezed classes:** `*.freezed.dart` files for immutable data classes
- **Injectable dependencies:** Dependency injection registration
- **Route generation:** Type-safe navigation routes

### Melos Configuration

The `melos.yaml` configuration:

```yaml
scripts:
  generate:
    description: Run code generation
    run: melos exec --dart run build_runner build --delete-conflicting-outputs
    packageFilters:
      dirExists: lib

  generate:watch:
    description: Run code generation in watch mode
    run: melos exec --dart run build_runner watch --delete-conflicting-outputs
    packageFilters:
      dirExists: lib
```

### Watch Mode

For active development, use watch mode to automatically regenerate on file changes:

```bash
# From project root or video_window_flutter
melos run generate:watch
```

This keeps generated files synchronized as you develop.

---

## Validation

### Manual Validation

**Step 1: Check for uncommitted generated files**

```bash
# From project root
git status

# Generated files should NOT appear as modified unless protocol changed
# If they do appear, run generation again
```

**Step 2: Verify Serverpod generation is fresh**

```bash
cd video_window_server

# Generate and check for changes
serverpod generate
git diff --exit-code lib/src/generated/
git diff --exit-code ../video_window_client/
git diff --exit-code ../video_window_shared/

# Exit code 0 = no changes (good)
# Exit code 1 = changes detected (need to commit)
```

**Step 3: Verify Flutter generation is fresh**

```bash
# From project root or video_window_flutter
melos run generate

# Check for changes
git diff --exit-code '**/*.g.dart'
git diff --exit-code '**/*.freezed.dart'

# Exit code 0 = no changes (good)
# Exit code 1 = changes detected (need to commit)
```

### Automated Validation Script

A validation script is available at `scripts/validate-generated-code.sh`:

```bash
#!/bin/bash
# Validates that all generated code is up-to-date

set -e

echo "🔍 Validating generated code..."

# Step 1: Serverpod generation
echo "Checking Serverpod generated code..."
cd video_window_server
serverpod generate

if ! git diff --quiet --exit-code lib/src/generated/ ../video_window_client/ ../video_window_shared/; then
  echo "❌ Serverpod generated code is stale!"
  echo "Run: cd video_window_server && serverpod generate"
  exit 1
fi
echo "✅ Serverpod code is fresh"

# Step 2: Flutter generation
echo "Checking Flutter generated code..."
cd ..
melos run generate

if git diff --quiet --exit-code '**/*.g.dart' '**/*.freezed.dart'; then
  echo "✅ Flutter generated code is fresh"
else
  echo "❌ Flutter generated code is stale!"
  echo "Run: melos run generate"
  exit 1
fi

echo "✅ All generated code is up-to-date"
```

---

## Troubleshooting

### Issue: "Command not found: serverpod"

**Cause:** Serverpod CLI not installed or not in PATH

**Solution:**
```bash
# Install Serverpod CLI
dart pub global activate serverpod_cli

# Verify installation
serverpod --version
```

### Issue: "Command not found: melos"

**Cause:** Melos not installed globally

**Solution:**
```bash
# Install Melos globally
dart pub global activate melos

# Verify installation
melos --version
```

### Issue: "Protocol file parse error"

**Cause:** Invalid YAML syntax in protocol file

**Solution:**
1. Check the error message for file and line number
2. Verify YAML syntax (proper indentation, no tabs)
3. Ensure field types are valid Serverpod types
4. Check for typos in field names

**Example Valid Protocol:**
```yaml
class: User
table: users
fields:
  id: int, primary, autoIncrement
  email: String, unique
  displayName: String?
  createdAt: DateTime
```

### Issue: "Build runner conflicts"

**Cause:** Conflicting generated files

**Solution:**
```bash
# Clean and regenerate
melos clean
melos run generate
```

### Issue: "Generated files show as modified"

**Cause:** Generated code is out of sync with source

**Solution:**
```bash
# Regenerate all code
cd video_window_server
serverpod generate

cd ..
melos run generate

# Commit the changes
git add .
git commit -m "chore: update generated code"
```

### Issue: "Import errors after generation"

**Cause:** Package dependencies not updated after generation

**Solution:**
```bash
# Update dependencies
melos run setup

# OR manually
cd video_window_flutter
flutter pub get

cd ../video_window_client
dart pub get
```

---

## CI/CD Integration

### Pre-Commit Validation

**Setup Git Hook:**

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook to validate generated code

./scripts/validate-generated-code.sh

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Pre-commit check failed!"
  echo "Please run code generation and commit the changes:"
  echo "  cd video_window_server && serverpod generate"
  echo "  melos run generate"
  exit 1
fi

echo "✅ Pre-commit validation passed"
```

**Make executable:**
```bash
chmod +x .git/hooks/pre-commit
```

### CI Pipeline Validation

The CI pipeline (`github/workflows/quality-gates.yml`) includes generation validation:

```yaml
jobs:
  quality-checks:
    steps:
      # ... setup steps ...

      - name: Generate code
        run: |
          cd video_window_server
          serverpod generate
          cd ..
          melos run generate

      - name: Check for uncommitted changes
        run: |
          if ! git diff --quiet --exit-code; then
            echo "❌ Generated code is stale!"
            echo "Files with changes:"
            git diff --name-only
            echo ""
            echo "Run code generation locally:"
            echo "  cd video_window_server && serverpod generate"
            echo "  melos run generate"
            exit 1
          fi
          echo "✅ All generated code is up-to-date"
```

### Automated Generation in CI

For development branches, CI can auto-commit generated code:

```yaml
      - name: Auto-fix generated code (dev only)
        if: github.ref == 'refs/heads/develop'
        run: |
          cd video_window_server
          serverpod generate
          cd ..
          melos run generate
          
          if ! git diff --quiet; then
            git config user.name "GitHub Actions"
            git config user.email "actions@github.com"
            git add .
            git commit -m "chore: auto-update generated code [skip ci]"
            git push
          fi
```

---

## Quick Reference

### Common Commands

```bash
# Full code generation workflow
cd video_window_server && serverpod generate && cd .. && melos run generate

# Watch mode for active development
melos run generate:watch

# Validate everything is fresh
./scripts/validate-generated-code.sh

# Clean and regenerate
melos clean && melos run setup && melos run generate
```

### Generated File Patterns

**Never Edit These:**
- `lib/src/generated/**` (Serverpod server)
- `video_window_client/lib/**` (Generated client)
- `video_window_shared/lib/**` (Shared models)
- `**/*.g.dart` (JSON serialization)
- `**/*.freezed.dart` (Freezed classes)

**Edit These:**
- `lib/src/protocol/*.yaml` (Serverpod models)
- `lib/src/endpoints/*.dart` (Serverpod endpoints)
- Regular Dart source files with annotations

---

## Related Documentation

- [Serverpod Code Generation Guide](../frameworks/serverpod/03-code-generation.md)
- [Melos Configuration](../architecture/melos-configuration.md)
- [Development Guide](../development.md)
- [Local Development Setup](./local-development-setup.md)

---

*For issues or improvements to this runbook, contact the DevOps team or file an issue in the repository.*
