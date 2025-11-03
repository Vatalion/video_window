# Melos Integration Guide - Video Window Project

**Version:** Melos 7.3.0+  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Sprint 1 Foundation

---

## Overview

This guide documents how Video Window uses **Melos** for managing our Flutter monorepo workspace. This is NOT general Melos documentation - it's our specific patterns, conventions, and workflows.

### Why Melos in Video Window?

- **Monorepo Management:** Coordinate `packages/core/`, `packages/shared/`, and `packages/features/*` as a single workspace
- **Script Orchestration:** Single commands execute across all packages (format, analyze, test, generate)
- **Dependency Management:** Shared dependencies and consistent versioning across packages
- **CI/CD Integration:** Workspace-level quality gates before merge

### Key Principle
**Melos workspace root = `video_window_flutter/` directory** (NOT project root)

---

## Project Structure

```
video_window/                        # Git repository root
└── video_window_flutter/            # ← MELOS WORKSPACE ROOT
    ├── melos.yaml                   # Workspace configuration
    ├── pubspec.yaml                 # Flutter app dependencies
    ├── lib/                         # Main Flutter app
    │   ├── app_shell/               # App bootstrap, routing, theme
    │   └── presentation/            # Global BLoCs (auth, app state)
    └── packages/                    # Managed by Melos
        ├── core/                    # Data layer (repositories, services)
        │   ├── pubspec.yaml
        │   └── lib/
        ├── shared/                  # Design system (widgets, theme)
        │   ├── pubspec.yaml
        │   └── lib/
        └── features/                # Feature modules
            ├── auth/
            │   ├── pubspec.yaml
            │   └── lib/
            ├── timeline/
            ├── commerce/
            └── publishing/
```

---

## Essential Melos Commands

### First-Time Setup

```bash
# From video_window_flutter/ directory
melos run setup
```

**What it does:**
1. Runs `melos bootstrap` (links all packages, runs hooks, syncs shared dependencies)
2. Executes `flutter pub get` for all packages
3. Runs code generation (`build_runner`, `serverpod generate`)
4. Validates environment setup

**When to use:** First clone, after pulling major changes, when packages seem out of sync

> **Note:** As of Dart 3.6.0+, [Pub Workspaces](https://dart.dev/tools/pub/workspaces) automatically links packages, making `melos bootstrap` optional for basic linking. However, we still use it for:
> - Shared dependency version enforcement across packages
> - Post-bootstrap hooks (code generation, setup scripts)
> - Explicit workspace validation before development

---

### Daily Development Workflow

#### Code Generation
```bash
melos run generate
```
- Runs `build_runner` for all packages
- Use after: Adding freezed models, JSON serialization, updating generated code

#### Code Quality
```bash
melos run format      # Auto-format all Dart code
melos run analyze     # Static analysis across workspace
```
- **ALWAYS run before committing**
- CI will reject PRs that fail these checks

#### Testing
```bash
melos run test              # All tests with coverage
melos run test:unit         # Unit tests only
melos run test:widget       # Widget tests only
melos run test:integration  # Integration tests only
```

#### Cleanup
```bash
melos run clean       # Clean all package build artifacts
```
- Use when: Build caching issues, switching branches, troubleshooting

---

## Melos Configuration (`melos.yaml`)

### Package Discovery

```yaml
packages:
  - packages/**      # All packages under packages/
  - .                # Root Flutter app
```

**Video Window Pattern:** 
- Feature packages live in `packages/features/*/`
- Core infrastructure in `packages/core/`
- Shared UI in `packages/shared/`

### Script Structure

Our `melos.yaml` defines scripts in this pattern:

```yaml
scripts:
  setup:
    description: First-time environment setup
    run: |
      melos bootstrap
      melos run generate
    
  generate:
    description: Run code generation
    run: flutter pub run build_runner build --delete-conflicting-outputs
    exec:
      concurrency: 1
    packageFilters:
      dependsOn: 'build_runner'
```

**Key Patterns:**
- `run:` executes once at workspace level
- `exec:` executes in each package
- `packageFilters:` targets specific packages

---

## Package Dependencies

### Path Dependencies (Internal Packages)

```yaml
# In packages/features/auth/pubspec.yaml
dependencies:
  core:
    path: ../../core
  shared:
    path: ../../shared
```

**Video Window Rules:**
1. **Feature packages** depend on `core` and `shared` via path dependencies
2. **Never publish** internal packages to pub.dev
3. **Melos manages** version resolution across packages

### Shared External Dependencies

Define once in root `pubspec.yaml`, inherit in packages:

```yaml
# Root pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.3
  
# Package pubspec.yaml  
dependencies:
  flutter_bloc: ^8.1.3  # Match root version
```

**Benefit:** Consistent versions, easier upgrades

---

## Workflow Patterns

### Creating a New Feature Package

```bash
cd video_window_flutter/packages/features
mkdir -p my_feature/lib/{use_cases,presentation/{bloc,pages,widgets}}
cd my_feature

# Create pubspec.yaml
cat > pubspec.yaml << 'EOF'
name: my_feature
description: My feature description
publish_to: none

environment:
  sdk: '>=3.5.6 <4.0.0'
  flutter: '>=3.19.6'

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../../core
  shared:
    path: ../../shared
  flutter_bloc: ^8.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
EOF

# Bootstrap to link dependencies
cd ../../../
melos bootstrap
```

### Running Commands on Specific Packages

```bash
# Run tests only in core package
melos exec --scope=core -- flutter test

# Format only feature packages
melos exec --dir-exists=packages/features -- dart format .

# Analyze packages that depend on flutter_bloc
melos exec --depends-on=flutter_bloc -- flutter analyze
```

---

## CI/CD Integration

### GitHub Actions Pattern

```yaml
# .github/workflows/quality-gates.yml
jobs:
  quality:
    steps:
      - name: Setup Melos
        run: dart pub global activate melos
      
      - name: Bootstrap workspace
        working-directory: video_window_flutter
        run: melos bootstrap
      
      - name: Run quality checks
        working-directory: video_window_flutter
        run: |
          melos run format --set-exit-if-changed
          melos run analyze
          melos run test
```

**Critical:** Always set `working-directory: video_window_flutter` in CI

---

## Common Issues & Solutions

### Issue: "Package not found" errors

**Symptoms:** Import errors, unresolved dependencies

**Solution:**
```bash
cd video_window_flutter
melos clean
melos bootstrap
```

### Issue: Code generation not updating

**Symptoms:** Old generated code, build errors

**Solution:**
```bash
melos run generate
# If still failing:
melos clean
melos run setup
```

### Issue: Version conflicts between packages

**Symptoms:** "Version solving failed" errors

**Solution:**
1. Check all `pubspec.yaml` files use consistent versions
2. Update root dependencies first
3. Run `melos bootstrap` to resolve

### Issue: Melos commands fail with "not in workspace"

**Symptoms:** "No packages found" errors

**Solution:**
```bash
# Ensure you're in workspace root
cd video_window_flutter
# Not project root (video_window/)
```

---

## Video Window Conventions

### Package Naming
- **Snake case:** `my_feature`, not `myFeature` or `my-feature`
- **Descriptive:** `auth`, `timeline`, `commerce`, not `feature1`

### Script Naming
- **Action verbs:** `format`, `analyze`, `test` (not `formatter`, `linter`)
- **Scoped variants:** `test:unit`, `test:widget`, `test:integration`

### Directory Structure
Every package follows this structure:
```
my_package/
├── pubspec.yaml
├── lib/
│   └── (package code)
└── test/
    └── (mirrors lib/ structure)
```

### Dependency Layers
```
Feature Packages (auth, timeline, commerce)
        ↓ depends on
Core Package (repositories, services, models)
        ↓ depends on
Shared Package (UI components, theme, utils)
```

**Never:** Feature packages depending on other feature packages

---

## Performance Tips

### Parallel Execution
```bash
# Melos runs commands in parallel by default
melos run analyze  # Analyzes all packages concurrently
```

### Selective Execution
```bash
# Only run on changed packages (in CI)
melos exec --since=origin/main -- flutter test
```

### Caching
```bash
# Melos caches bootstrap results
# Only re-bootstraps when pubspec.yaml changes
melos bootstrap  # Fast second run
```

---

## Integration with Other Tools

### VS Code Tasks
```json
// .vscode/tasks.json
{
  "label": "Melos: Setup",
  "type": "shell",
  "command": "melos",
  "args": ["run", "setup"],
  "options": {
    "cwd": "${workspaceFolder}/video_window_flutter"
  }
}
```

### Pre-commit Hooks
```bash
# .git/hooks/pre-commit
#!/bin/sh
cd video_window_flutter
melos run format --set-exit-if-changed
melos run analyze
```

---

## Reference Links

- **Official Docs:** https://melos.invertase.dev/
- **Our Config:** `video_window_flutter/melos.yaml`
- **Example Usage:** Story 01.1, 01.3 implementation
- **Architecture Context:** `docs/architecture/project-structure-implementation.md`

---

## Quick Reference Card

```bash
# Essential Commands (from video_window_flutter/)
melos run setup          # First-time setup
melos bootstrap          # Link packages
melos run generate       # Code generation
melos run format         # Format code
melos run analyze        # Static analysis
melos run test           # Run tests
melos clean              # Clean artifacts

# Package-specific
melos exec --scope=core -- flutter test
melos list               # List all packages
melos version            # Version management
```

---

**Next Steps for Developers:**
1. Read this guide fully before starting Sprint 1
2. Run `melos run setup` as first action
3. Bookmark for daily reference
4. Update this guide when discovering new patterns

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial integration guide created for Sprint 1 | Winston (Architect) |

---

**Related Documentation:**
- `docs/frameworks/flutter-monorepo-guide.md` - Package structure patterns
- `docs/frameworks/bloc-integration-guide.md` - State management with BLoC
- `docs/architecture/project-structure-implementation.md` - Overall architecture
