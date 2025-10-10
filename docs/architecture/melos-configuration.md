# Melos Configuration Guide

## Overview

Melos is a tool for managing Dart packages with multiple packages. This document provides the complete Melos configuration for the Craft Video Marketplace project to enable efficient multi-package development, testing, and deployment.

## Melos Setup

### 1. Installation

```bash
# Install Melos globally
dart pub global activate melos

# Verify installation
melos --version
```

### 2. Project Initialization

```bash
# Initialize Melos in project root
melos init

# This creates melos.yaml and sets up basic configuration
```

## Complete Melos Configuration

### melos.yaml
```yaml
name: video_window
description: Craft Video Marketplace - Flutter multi-package workspace
repository: https://github.com/your-org/video_window
sdk: '>=3.8.0 <4.0.0'
environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'

# Package discovery patterns
packages:
  - packages/mobile_client
  - packages/core
  - packages/shared_models
  - packages/design_system
  - packages/features/*
  - serverpod/packages/modules/*

# Command scripts
scripts:
  # Development commands
  setup:
    description: Set up the development environment
    run: |
      melos exec --flutter pub get
      melos exec --dart run build_runner build
      echo "✅ Development environment setup complete"

  clean:
    description: Clean all packages
    run: |
      melos exec --flutter clean
      melos exec --rm -rf .dart_tool
      melos exec --rm -rf build
      echo "✅ All packages cleaned"

  # Analysis and formatting
  analyze:
    description: Analyze all packages for issues
    run: melos exec --flutter analyze --fatal-infos --fatal-warnings
    packageFilters:
      dirExists: lib

  format:
    description: Format all Dart code
    run: melos exec --dart format . --set-exit-if-changed
    packageFilters:
      dirExists: lib

  format-check:
    description: Check if code is properly formatted
    run: melos exec --dart format . --set-exit-if-changed
    packageFilters:
      dirExists: lib

  # Testing commands
  test:
    description: Run all tests
    run: melos exec --flutter test --coverage
    packageFilters:
      dirExists: test

  test:watch:
    description: Run tests in watch mode
    run: melos exec --flutter test --watch
    packageFilters:
      dirExists: test

  test:coverage:
    description: Run tests with coverage report
    run: |
      melos exec --flutter test --coverage
      melos run coverage:merge
      melos run coverage:report

  coverage:merge:
    description: Merge coverage files
    run: |
      mkdir -p coverage
      melos exec --find . -name "lcov.info" -exec cat {} \; > coverage/lcov.info

  coverage:report:
    description: Generate coverage report
    run: |
      if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo "📊 Coverage report generated at coverage/html/index.html"
      else
        echo "⚠️ genhtml not found. Install lcov for HTML reports."
      fi

  # Build commands
  build:
    description: Build all packages
    run: melos exec --flutter build apk --debug
    packageFilters:
      dirExists: lib

  build:release:
    description: Build release versions
    run: melos exec --flutter build apk --release
    packageFilters:
      dirExists: lib

  build:ios:
    description: Build iOS version
    run: melos exec --flutter build ios --release
    packageFilters:
      dirExists: lib

  # Dependency management
  deps:
    description: Get dependencies for all packages
    run: melos exec --flutter pub get
    packageFilters:
      dirExists: pubspec.yaml

  deps:upgrade:
    description: Upgrade dependencies
    run: melos exec --flutter pub upgrade
    packageFilters:
      dirExists: pubspec.yaml

  deps:outdated:
    description: Check for outdated dependencies
    run: melos exec --flutter pub outdated
    packageFilters:
      dirExists: pubspec.yaml

  deps:tree:
    description: Show dependency tree
    run: melos exec --flutter pub deps --style=tree
    packageFilters:
      dirExists: pubspec.yaml

  deps:audit:
    description: Audit dependencies for security issues
    run: melos exec --flutter pub audit
    packageFilters:
      dirExists: pubspec.yaml

  # Code generation
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

  # Package-specific commands
  auth:test:
    description: Run tests for auth package only
    run: flutter test --coverage
    packageFilters:
      name: auth

  timeline:test:
    description: Run tests for timeline package only
    run: flutter test --coverage
    packageFilters:
      name: timeline

  publishing:test:
    description: Run tests for publishing package only
    run: flutter test --coverage
    packageFilters:
      name: publishing

  # Validation commands
  validate:
    description: Run all validation checks
    run: |
      melos run format-check
      melos run analyze
      melos run test
      melos run deps:audit
      echo "✅ All validation checks passed"

  validate:pre-commit:
    description: Fast validation for pre-commit hooks
    run: |
      melos run format-check
      melos run analyze --no-congratulate
      melos run test --coverage
      echo "✅ Pre-commit validation passed"

  # Release commands
  version:
    description: Show version information
    run: |
      echo "📦 Package versions:"
      melos exec --flutter pub deps --style=compact | grep -E "^[^-]"

  version:bump:
    description: Bump package versions
    run: melos exec --dart pub upgrade --major-versions
    packageFilters:
      dirExists: pubspec.yaml

  # Documentation
  docs:
    description: Generate documentation
    run: melos exec --dart doc
    packageFilters:
      dirExists: lib

  docs:serve:
    description: Serve documentation locally
    run: melos exec --dart doc --serve
    packageFilters:
      dirExists: lib

  # Development server
  dev:
    description: Start development server
    run: flutter run --debug
    packageFilters:
      scope: mobile_client

  dev:profile:
    description: Start profile development server
    run: flutter run --profile
    packageFilters:
      scope: mobile_client

# Environment variables
environment:
  FLUTTER_ROOT: /opt/flutter
  MELOS_ROOT_ENV: true

# IDE integration
ide:
  intellij:
    enabled: true
    format: true
  vscode:
    enabled: true
    format: true

# Hooks
hooks:
  postbootstrap: |
    echo "🚀 Workspace bootstrapped successfully"
    echo "📝 Available commands: melos run --help"
    echo "🔍 Common workflows:"
    echo "  melos run setup      # Initial setup"
    echo "  melos run validate    # Full validation"
    echo "  melos run test        # Run all tests"
    echo "  melos run build       # Build all packages"
  precommit: melos run validate:pre-commit
```

## Package-Specific Configurations

### 1. Core Package pubspec.yaml Templates

#### packages/core/pubspec.yaml
```yaml
name: video_window_core
description: Core utilities and base classes for Video Window
version: 1.0.0
homepage: https://github.com/your-org/video_window

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'

dependencies:
  flutter:
    sdk: flutter
  meta: ^1.9.1
  equatable: ^2.0.5
  collection: ^1.17.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.1
  very_good_analysis: ^5.1.0

flutter:
  # No flutter assets - pure Dart package
```

#### packages/shared_models/pubspec.yaml
```yaml
name: video_window_shared_models
description: Serverpod-generated models for Video Window
version: 1.0.0
homepage: https://github.com/your-org/video_window

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'

dependencies:
  flutter:
    sdk: flutter
  serverpod_client: ^2.9.0
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  very_good_analysis: ^5.1.0

flutter:
  # No flutter assets - pure Dart package
```

#### packages/design_system/pubspec.yaml
```yaml
name: video_window_design_system
description: Design system and UI components for Video Window
version: 1.0.0
homepage: https://github.com/your-org/video_window

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'

dependencies:
  flutter:
    sdk: flutter
  video_window_core:
    path: ../core
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  video_window_core:
    path: ../core
  very_good_analysis: ^5.1.0

flutter:
  assets:
    - assets/fonts/
    - assets/icons/
    - assets/images/
```

### 2. Feature Package Template

#### packages/features/auth/pubspec.yaml
```yaml
name: video_window_auth
description: Authentication feature package for Video Window
version: 1.0.0
homepage: https://github.com/your-org/video_window

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Internal dependencies (following governance rules)
  video_window_core:
    path: ../../core
  video_window_shared_models:
    path: ../../shared_models
  video_window_design_system:
    path: ../../design_system

  # External dependencies
  flutter_secure_storage: ^9.2.2
  local_auth: ^2.2.0
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.1
  bloc_test: ^9.1.4
  very_good_analysis: ^5.1.0
  build_runner: ^2.4.7
  json_serializable: ^6.7.1

flutter:
  # No global assets - feature-specific assets in subdirectories
```

## IDE Integration

### 1. VS Code Configuration

#### .vscode/settings.json
```json
{
  "dart.flutterSdkPath": "flutter",
  "dart.lineLength": 80,
  "editor.rulers": [80],
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false,
  "search.exclude": {
    "**/build": true,
    "**/.dart_tool": true,
    "**/.pub-cache": true
  },
  "files.watcherExclude": {
    "**/build": true,
    "**/.dart_tool": true,
    "**/.pub-cache": true
  },
  "melos.scopes": [
    "core",
    "shared_models",
    "design_system",
    "auth",
    "timeline",
    "publishing",
    "commerce",
    "shipping",
    "notifications"
  ]
}
```

#### .vscode/tasks.json
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Melos: Analyze",
      "type": "shell",
      "command": "melos",
      "args": ["run", "analyze"],
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Melos: Test",
      "type": "shell",
      "command": "melos",
      "args": ["run", "test"],
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Melos: Validate",
      "type": "shell",
      "command": "melos",
      "args": ["run", "validate"],
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

### 2. IntelliJ/Android Studio Configuration

#### .idea/modules.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module fileurl="file://$PROJECT_DIR$/.idea/video_window.iml" filepath="$PROJECT_DIR$/.idea/video_window.iml" />
      <module fileurl="file://$PROJECT_DIR$/packages/core/.idea/core.iml" filepath="$PROJECT_DIR$/packages/core/.idea/core.iml" />
      <module fileurl="file://$PROJECT_DIR$/packages/design_system/.idea/design_system.iml" filepath="$PROJECT_DIR$/packages/design_system/.idea/design_system.iml" />
      <module fileurl="file://$PROJECT_DIR$/packages/shared_models/.idea/shared_models.iml" filepath="$PROJECT_DIR$/packages/shared_models/.idea/shared_models.iml" />
    </modules>
  </component>
</project>
```

## CI/CD Integration

### 1. GitHub Actions Workflow

#### .github/workflows/melos.yml
```yaml
name: Melos CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: 'stable'

      - name: Install Melos
        run: dart pub global activate melos

      - name: Setup Melos
        run: melos bootstrap

      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: |
            ~/.pub-cache
            .dart_tool
            packages/**/.dart_tool
            packages/**/build
          key: ${{ runner.os }}-melos-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: |
            ${{ runner.os }}-melos-

  validate:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Install Melos
        run: dart pub global activate melos

      - name: Setup Melos
        run: melos bootstrap

      - name: Format check
        run: melos run format-check

      - name: Analyze
        run: melos run analyze

      - name: Dependencies audit
        run: melos run deps:audit

  test:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Install Melos
        run: dart pub global activate melos

      - name: Setup Melos
        run: melos bootstrap

      - name: Run tests
        run: melos run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

  build:
    needs: [validate, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Install Melos
        run: dart pub global activate melos

      - name: Setup Melos
        run: melos bootstrap

      - name: Build APK
        run: melos run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: apk
          path: build/app/outputs/flutter-apk/app-debug.apk
```

## Development Workflows

### 1. Daily Development Workflow

```bash
# 1. Start development day
melos run deps:upgrade
melos run generate

# 2. Create new feature branch
git checkout -b feature/new-auth-flow

# 3. Work on specific package
cd packages/features/auth
flutter test --watch
flutter run --debug

# 4. Run validation before committing
melos run validate:pre-commit

# 5. Commit changes
git add .
git commit -m "feat: add new auth flow"
git push origin feature/new-auth-flow
```

### 2. Package Creation Workflow

```bash
# 1. Create new feature package
mkdir packages/features/new_feature
cd packages/features/new_feature

# 2. Create package structure
mkdir -p lib/{domain/{entities,repositories,usecases},data/{datasources,models,repositories},presentation/{pages,widgets,bloc,routes}}
mkdir -p test/{unit,widget,integration}

# 3. Create pubspec.yaml from template
# (copy from auth package and modify)

# 4. Create public API export
cat > lib/new_feature.dart << 'EOF'
// New Feature Package Public API

// Domain exports
export 'domain/entities/example_entity.dart';
export 'domain/repositories/example_repository.dart';
export 'domain/usecases/example_usecase.dart';

// Data exports
export 'data/repositories/example_repository_impl.dart';
export 'data/datasources/example_datasource.dart';

// Presentation exports
export 'presentation/bloc/new_feature_bloc.dart';
export 'presentation/pages/new_feature_page.dart';

// Utilities
export 'utils/new_feature_utils.dart';
EOF

# 5. Add to Melos workspace
# Update melos.yaml to include new package

# 6. Install dependencies
melos run deps

# 7. Run initial tests
melos run test
```

### 3. Release Workflow

```bash
# 1. Update versions
melos run version:bump

# 2. Full validation
melos run validate

# 3. Build release versions
melos run build:release
melos run build:ios

# 4. Generate documentation
melos run docs

# 5. Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Troubleshooting

### 1. Common Issues

#### Dependency Resolution Failures
```bash
# Clear all caches
melos run clean
flutter clean
rm -rf ~/.pub-cache
flutter pub cache clean

# Re-bootstrap
melos bootstrap
```

#### Build Failures
```bash
# Check for specific package issues
melos exec --flutter analyze
melos exec --flutter pub deps

# Fix specific package
cd packages/features/problem_package
flutter clean
flutter pub get
flutter analyze
```

#### Test Failures
```bash
# Run tests with verbose output
melos exec --flutter test --verbose

# Run tests for specific package
cd packages/features/auth
flutter test --coverage --plain-name "specific_test"
```

### 2. Performance Optimization

#### Faster Development Cycles
```bash
# Use selective package execution
melos run test --scope=auth
melos run analyze --scope=auth,timeline

# Use watch mode for development
melos run generate:watch
melos run test:watch
```

#### Build Optimization
```bash
# Build specific targets
melos exec --flutter build apk --debug --target-platform=android-arm64

# Use build cache
flutter build apk --build-cache
```

## Best Practices

### 1. Package Management
- Keep dependencies minimal and purposeful
- Use semantic versioning consistently
- Document all external dependencies
- Regular security audits of dependencies

### 2. Code Organization
- Follow clean architecture principles
- Keep public APIs small and focused
- Use consistent naming conventions
- Provide comprehensive documentation

### 3. Testing Strategy
- Maintain high test coverage (>80%)
- Test package boundaries thoroughly
- Use mocking for external dependencies
- Include integration tests for critical paths

### 4. Development Workflow
- Use feature branches for development
- Run pre-commit validation locally
- Keep CI/CD pipeline fast and reliable
- Document all package interfaces

This Melos configuration provides a solid foundation for efficient multi-package development in the Craft Video Marketplace project.