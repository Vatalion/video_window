# Melos Integration Guide - Video Window Project

**Version:** Melos 7.3.0+  
**Last Updated:** 2025-11-13  
**Status:** ✅ Active - Sprint 1 Foundation

---

## Overview

This guide documents how Video Window uses **Melos** for managing our Flutter monorepo workspace. This is NOT general Melos documentation - it's our specific patterns, conventions, and workflows.

### Why Melos in Video Window?

- **Monorepo Management:** Coordinate `video_window_flutter/`, `video_window_server/`, and other packages as a single workspace.
- **Script Orchestration:** Single commands execute across all packages (format, analyze, test, generate).
- **Dependency Management:** Shared dependencies and consistent versioning across packages via `pubspec.yaml` workspaces.
- **CI/CD Integration:** Workspace-level quality gates before merge.

### Key Principle
**Melos workspace root = `video_window/` project directory.**

---

## Project Structure

```
video_window/                        # Git repository and Melos workspace root
├── pubspec.yaml                     # Melos workspace configuration
├── video_window_flutter/            # Flutter app
│   ├── pubspec.yaml                 # App dependencies
│   └── lib/                         # Main Flutter app
├── video_window_server/             # Serverpod backend
│   ├── pubspec.yaml                 # Server dependencies
│   └── lib/
└── video_window_client/             # Generated client
```

---

## Essential Melos Commands

### First-Time Setup

```bash
# From the project root directory
melos bootstrap
```

**What it does:**
1. Links all packages defined in the `workspace` section of the root `pubspec.yaml`.
2. Executes `flutter pub get` for all packages.
3. Runs post-bootstrap hooks defined in `pubspec.yaml`.

**When to use:** First clone, after pulling major changes, or when packages seem out of sync.

> **Note:** As of Dart 3.6.0+, [Pub Workspaces](https://dart.dev/tools/pub/workspaces) automatically links packages. We use `melos bootstrap` to also run our setup scripts and validate the workspace.

---

### Daily Development Workflow

#### Code Generation
```bash
melos run generate
```
- Runs `build_runner` for all packages that need it.
- Use after: Adding freezed models, JSON serialization, or updating generated code.

#### Code Quality
```bash
melos run format      # Auto-format all Dart code
melos run analyze     # Static analysis across workspace
```
- **ALWAYS run before committing.**
- CI will reject PRs that fail these checks.

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
- Use when: Build caching issues, switching branches, or troubleshooting.

---

## Melos Configuration (`pubspec.yaml`)

### Package Discovery

The `workspace` key in the root `pubspec.yaml` file defines the packages in the Melos workspace.

```yaml
# pubspec.yaml
name: video_window
description: Video Window monorepo workspace.
publish_to: none

environment:
  sdk: '>=3.8.0 <4.0.0'

workspace:
  - video_window_flutter
  - video_window_server
  - video_window_client
  - video_window_flutter/packages/core
  - video_window_flutter/packages/shared
  - video_window_flutter/packages/features/*

dev_dependencies:
  melos: ^7.3.0
```

### Script Structure

Scripts are defined under the `melos` key in the root `pubspec.yaml`.

```yaml
# pubspec.yaml
melos:
  scripts:
    setup:
      description: First-time environment setup
      run: |
        melos bootstrap
        melos run generate
    
    generate:
      description: Run code generation
      run: melos exec -- "dart run build_runner build --delete-conflicting-outputs"
      packageFilters:
        dependsOn: build_runner
```

**Key Patterns:**
- `run:` executes a command once at the workspace root.
- `exec:` executes a command in each package.
- `packageFilters:` targets specific packages based on their properties.

---

## Package Dependencies

### Path Dependencies (Internal Packages)

Packages within the workspace can depend on each other using `path` dependencies.

```yaml
# In video_window_flutter/pubspec.yaml
dependencies:
  video_window_client:
    path: ../video_window_client
  core:
    path: packages/core
```

### Shared External Dependencies

To ensure consistent versions, you can use `dependency_overrides` in the root `pubspec.yaml`.

```yaml
# root pubspec.yaml
dependency_overrides:
  flutter_bloc: ^8.1.6
```

---

## Workflow Patterns

### Creating a New Feature Package

1.  **Create the package directory:**
    ```bash
    mkdir -p video_window_flutter/packages/features/my_feature/lib
    ```
2.  **Create the `pubspec.yaml` for the new package:**
    ```yaml
    # video_window_flutter/packages/features/my_feature/pubspec.yaml
    name: my_feature
    description: My new feature.
    publish_to: none

    environment:
      sdk: '>=3.8.0 <4.0.0'

    dependencies:
      flutter:
        sdk: flutter
      core:
        path: ../../core
    ```
3.  **Add the package to the workspace in the root `pubspec.yaml`:**
    ```yaml
    # /pubspec.yaml
    workspace:
      - ...
      - video_window_flutter/packages/features/my_feature
    ```
4.  **Bootstrap the workspace to link the new package:**
    ```bash
    melos bootstrap
    ```

### Running Commands on Specific Packages

```bash
# Run tests only in the core package
melos exec --scope=core -- flutter test

# Format only feature packages
melos exec --scope="*feature*" -- dart format .

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
        run: melos bootstrap
      
      - name: Run quality checks
        run: |
          melos run format --set-exit-if-changed
          melos run analyze
          melos run test
```

---

## Common Issues & Solutions

### Issue: "Package not found" errors

**Symptoms:** Import errors, unresolved dependencies.

**Solution:**
```bash
melos clean
melos bootstrap
```
Then restart your IDE.

### Issue: Code generation not updating

**Symptoms:** Old generated code, build errors.

**Solution:**
```bash
melos run generate
# If still failing:
melos clean
melos bootstrap
```

### Issue: Version conflicts between packages

**Symptoms:** "Version solving failed" errors.

**Solution:**
1.  Use `dependency_overrides` in the root `pubspec.yaml` to force a consistent version.
2.  Run `melos bootstrap` to apply the override.

### Issue: Melos commands fail with "not in workspace"

**Symptoms:** "No packages found" or "current directory does not appear to be a Melos workspace" errors.

**Solution:**
Ensure you are running `melos` commands from the root of the project (`/Volumes/workspace/projects/flutter/video_window`), where the root `pubspec.yaml` with the `workspace` key is located.

---

## Video Window Conventions

### Package Naming
- **Snake case:** `my_feature`, not `myFeature` or `my-feature`.
- **Descriptive:** `auth`, `timeline`, `commerce`, not `feature1`.

### Script Naming
- **Action verbs:** `format`, `analyze`, `test` (not `formatter`, `linter`).
- **Scoped variants:** `test:unit`, `test:widget`, `test:integration`.

### Directory Structure
Every package should have a `pubspec.yaml`, a `lib` directory, and a `test` directory.

---

## Reference Links

- **Official Docs:** https://melos.invertase.dev/
- **Pub Workspaces:** https://dart.dev/tools/pub/workspaces
- **Our Config:** `pubspec.yaml`
- **Architecture Context:** `docs/architecture/project-structure-implementation.md`

---

## Quick Reference Card

```bash
# Essential Commands (from project root)
melos bootstrap          # Link packages and run setup
melos run generate       # Code generation
melos run format         # Format code
melos run analyze        # Static analysis
melos run test           # Run tests
melos clean              # Clean artifacts

# Package-specific
melos exec --scope=core -- flutter test
melos list               # List all packages
```

---

**Next Steps for Developers:**
1. Read this guide fully before starting new work.
2. Run `melos bootstrap` as the first action after cloning.
3. Bookmark for daily reference.
4. Update this guide when discovering new patterns.

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-13 | v2.0 | Updated for Melos 7.x and `pubspec.yaml` workspaces | Gemini |
| 2025-11-03 | v1.0 | Initial integration guide created for Sprint 1 | Winston (Architect) |

---

**Related Documentation:**
- `docs/frameworks/flutter-monorepo-guide.md` - Package structure patterns
- `docs/frameworks/bloc-integration-guide.md` - State management with BLoC
- `docs/architecture/project-structure-implementation.md` - Overall architecture
