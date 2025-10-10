# Package Dependency Governance

## Overview

This document defines the governance model for managing dependencies between packages in the Craft Video Marketplace project. It establishes rules, processes, and tools to maintain clean dependency architecture throughout the development lifecycle.

## Governance Principles

### 1. Dependency Direction Rules
Dependencies must follow a strict hierarchical pattern to prevent circular dependencies and maintain clean architecture.

#### Allowed Dependency Flow
```
┌─────────────────┐
│   Feature       │ ──────┐
│   Packages      │       │
└─────────────────┘       │
          │               │
          ▼               ▼
┌─────────────────┐  ┌──────────────┐
│   Core          │  │ Shared       │
│   Packages      │  │ Models       │
└─────────────────┘  └──────────────┘
          │               │
          └───────┬───────┘
                  ▼
        ┌──────────────┐
        │ Design       │
        │ System       │
        └──────────────┘
```

#### Forbidden Dependencies
- Feature packages depending on other feature packages
- Core packages depending on feature packages
- Shared models depending on feature packages
- Any circular dependency chains

### 2. Dependency Categories

#### Production Dependencies
Runtime dependencies required for the package to function:
- Must be explicitly declared in `dependencies:` section
- Must be version-pinned for stability
- Must have security vulnerability scanning

#### Development Dependencies
Build-time and testing dependencies:
- Must be declared in `dev_dependencies:` section
- Can be version-ranged for flexibility
- Not included in production builds

#### Peer Dependencies
Dependencies that must be provided by the consuming package:
- Used when multiple packages need the same dependency version
- Must be clearly documented
- Must include version compatibility matrix

## Dependency Management Rules

### 1. Adding New Dependencies

#### Evaluation Criteria
Before adding a new dependency, teams must evaluate:

1. **Necessity Assessment**
   - Is the functionality critical to the package?
   - Can it be implemented in-house instead?
   - Is there a lighter-weight alternative?

2. **Impact Assessment**
   - How will this affect package size?
   - What are the security implications?
   - How does this affect build time?

3. **Maintainability Assessment**
   - Is the library actively maintained?
   - Does it have a compatible license?
   - Is there good community support?

#### Approval Process
1. **Create RFC** (Request for Comments) document
2. **Technical review** by architecture team
3. **Security review** by security team
4. **Performance review** by performance team
5. **Final approval** by project maintainers

### 2. Version Management

#### Semantic Versioning Compliance
- Follow semantic versioning (SemVer) for all dependencies
- Pin major versions: `^1.0.0` (allows 1.x.x, not 2.0.0)
- Use compatible ranges for minor versions: `^1.2.0` (allows 1.2.x+)
- Document all version constraints and rationale

#### Update Strategy
1. **Regular Updates**: Monthly dependency update reviews
2. **Security Updates**: Immediate updates for CVEs
3. **Major Version Updates**: Requires migration plan and testing
4. **Breaking Changes**: Requires communication across all dependent packages

### 3. Dependency Conflict Resolution

#### Conflict Detection
Automated tools must detect and alert on:
- Version conflicts between packages
- Transitive dependency conflicts
- License incompatibilities
- Security vulnerabilities

#### Resolution Process
1. **Identify conflict scope** (affected packages)
2. **Evaluate solution options**:
   - Upgrade conflicting dependency
   - Use dependency override
   - Refactor to remove dependency
3. **Test solution** across all affected packages
4. **Document resolution** for future reference

## Implementation Guidelines

### 1. Package Structure for Dependencies

#### pubspec.yaml Template
```yaml
name: feature_auth
description: Authentication feature package
version: 1.0.0

environment:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'

dependencies:
  # Core framework dependencies
  flutter:
    sdk: flutter

  # Internal package dependencies (follow governance rules)
  video_window_core:
    path: ../../core
  video_window_shared_models:
    path: ../../shared_models
  video_window_design_system:
    path: ../../design_system

  # External dependencies (vetted and approved)
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

# Note: serverpod_client should only be added to:
# - packages/shared_models/ (for generated models)
# - packages/core/ (for data layer operations)
# NOT in feature packages (use core repositories instead)

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.1
  very_good_analysis: ^5.1.0
```

### 2. Dependency Injection Patterns

#### Service Locator Configuration
```dart
// packages/core/lib/services/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:serverpod_client/serverpod_client.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Serverpod client - central communication layer
  sl.registerLazySingleton<ServerpodClient>(() => ServerpodClient(
    'http://localhost:8080/',
    authenticationKeyManager: authenticationKeyManager,
  ));

  // Core data services
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    sl<ServerpodClient>(),
    sl<AuthRemoteDataSource>(),
    sl<AuthLocalDataSource>(),
  ));

  sl.registerLazySingleton<NetworkService>(() => NetworkServiceImpl());
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl());

  // Feature use cases (lazy loaded)
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl<AuthRepository>()));
}
```

#### Package Interface Pattern
```dart
// packages/features/auth/lib/auth.dart
// Public API export - single point of entry

// Feature-specific use cases
export 'use_cases/login_usecase.dart';
export 'use_cases/register_usecase.dart';
export 'use_cases/logout_usecase.dart';

// Presentation exports
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/pages/login_page.dart';
export 'presentation/pages/register_page.dart';
export 'presentation/widgets/auth_form.dart';

// Utilities
export 'utils/auth_validators.dart';
```

### 3. Cross-Package Communication

#### Event Bus Pattern
```dart
// packages/shared_models/lib/events/auth_events.dart
abstract class AuthEvent {}

class UserLoggedInEvent extends AuthEvent {
  final User user;
  UserLoggedInEvent(this.user);
}

class UserLoggedOutEvent extends AuthEvent {}

// Usage in feature package
class AuthService {
  final EventBus _eventBus;

  AuthService(this._eventBus);

  Future<void> login(String email, String password) async {
    // Login logic
    final user = await _performLogin(email, password);
    _eventBus.fire(UserLoggedInEvent(user));
  }
}
```

#### Repository Interface Pattern
```dart
// packages/core/lib/data/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Stream<User?> get userChanges;
}

// Implementation in core package data layer
// packages/core/lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final ServerpodClient _client;
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._client, this._remoteDataSource, this._localDataSource);

  @override
  Future<AuthResult> login(String email, String password) async {
    // Serverpod-first implementation
    final result = await _client.auth.login(email, password);
    return AuthResult.fromServerpod(result);
  }
}

// Feature use case uses core repository
// packages/features/auth/lib/use_cases/login_usecase.dart
class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<AuthResult> call(String email, String password) async {
    return await _authRepository.login(email, password);
  }
}
```

## Tooling and Automation

### 1. Dependency Analysis Tools

#### Melos Configuration
```yaml
# melos.yaml
name: video_window
packages:
  - packages/*
  - packages/features/*

scripts:
  # Dependency analysis
  deps:
    description: Analyze dependency graph
    run: melos exec --flutter pub deps

  deps-tree:
    description: Show dependency tree
    run: melos exec --flutter pub deps --style=tree

  # Security scanning
  audit:
    description: Security audit dependencies
    run: melos exec --flutter pub audit

  # Outdated dependencies
  outdated:
    description: Check for outdated dependencies
    run: melos exec --flutter pub outdated

  # Dependency validation
  validate-deps:
    description: Validate dependency governance rules
    run: dart run dependency_validator

  # Format and analyze
  analyze:
    description: Analyze all packages
    run: melos exec --flutter analyze

  test:
    description: Run all tests
    run: melos exec --flutter test

  # Build validation
  build:
    description: Build all packages
    run: melos exec --flutter build apk --debug
```

#### Custom Dependency Validator
```dart
// tool/dependency_validator.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class DependencyValidator {
  static Future<void> validateDependencies() async {
    final packagesDir = Directory('packages');

    if (!await packagesDir.exists()) {
      print('No packages directory found');
      return;
    }

    final packageDirs = packagesDir
        .listSync()
        .whereType<Directory>()
        .where((dir) => File(path.join(dir.path, 'pubspec.yaml')).existsSync());

    for (final packageDir in packageDirs) {
      await _validatePackage(packageDir);
    }
  }

  static Future<void> _validatePackage(Directory packageDir) async {
    final pubspecFile = File(path.join(packageDir.path, 'pubspec.yaml'));
    final content = await pubspecFile.readAsString();
    final pubspec = loadYaml(content);

    final packageName = pubspec['name'] as String?;
    if (packageName == null) {
      _printError('Package name not found in ${packageDir.path}');
      return;
    }

    // Validate dependency directions
    final dependencies = pubspec['dependencies'] as YamlMap? ?? YamlMap();
    _validateDependencyDirections(packageName, dependencies, packageDir.path);

    // Validate version constraints
    _validateVersionConstraints(dependencies, packageDir.path);
  }

  static void _validateDependencyDirections(
    String packageName,
    YamlMap dependencies,
    String packagePath,
  ) {
    // Implement dependency direction rules validation
    // Check for forbidden dependencies based on package type
  }

  static void _validateVersionConstraints(
    YamlMap dependencies,
    String packagePath,
  ) {
    // Implement version constraint validation
    // Check for proper semantic versioning
  }

  static void _printError(String message) {
    print('❌ $message');
  }

  static void _printWarning(String message) {
    print('⚠️ $message');
  }

  static void _printSuccess(String message) {
    print('✅ $message');
  }
}

void main() async {
  await DependencyValidator.validateDependencies();
}
```

### 2. CI/CD Integration

#### GitHub Actions Workflow
```yaml
# .github/workflows/dependency-validation.yml
name: Dependency Validation

on:
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 2 * * 1' # Weekly on Monday

jobs:
  validate-dependencies:
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

      - name: Validate dependencies
        run: melos run validate-deps

      - name: Security audit
        run: melos run audit

      - name: Check for outdated dependencies
        run: melos run outdated

      - name: Analyze packages
        run: melos run analyze
```

## Monitoring and Reporting

### 1. Dependency Metrics

#### Key Performance Indicators
- **Package count**: Total number of packages
- **Dependency depth**: Maximum dependency chain length
- **Circular dependencies**: Number of circular dependency violations
- **Security vulnerabilities**: Number of known CVEs
- **Package size**: Size impact of each package
- **Build time**: Time to build all packages

#### Dashboard Configuration
```yaml
# monitoring/dependency-dashboard.yml
dashboard:
  title: Package Dependency Metrics
  panels:
    - title: Package Count
      type: stat
      query: count(packages)

    - title: Dependency Depth
      type: gauge
      query: max(dependency_depth)

    - title: Security Vulnerabilities
      type: stat
      query: count(severity:critical)

    - title: Package Size Trend
      type: timeseries
      query: avg(package_size) over time
```

### 2. Alerting Rules

#### Alert Conditions
- **New security vulnerability** in any dependency
- **Circular dependency** detected
- **Package size exceeds** 10MB threshold
- **Build time increases** by >20%
- **Dependency graph changes** exceed 10% in single PR

#### Notification Channels
- Slack notifications for critical alerts
- Email summaries for weekly reports
- GitHub issues for dependency updates
- Dashboard updates for real-time monitoring

## Documentation and Training

### 1. Developer Guidelines

#### Onboarding Checklist
- [ ] Understand dependency direction rules
- [ ] Complete dependency governance training
- [ ] Set up local development environment
- [ ] Run dependency validation locally
- [ ] Review package documentation standards

#### Best Practices Document
1. **Minimize dependencies** - Only add what's necessary
2. **Prefer internal packages** - Build in-house when possible
3. **Regular updates** - Keep dependencies current
4. **Security first** - Always consider security implications
5. **Document decisions** - Record rationale for dependencies

### 2. Troubleshooting Guide

#### Common Issues
1. **Circular Dependencies**
   - Symptom: Build fails with circular import error
   - Solution: Refactor to remove cycle, introduce shared package

2. **Version Conflicts**
   - Symptom: Version resolver fails
   - Solution: Use dependency overrides, update packages

3. **Security Vulnerabilities**
   - Symptom: Security scanner finds CVE
   - Solution: Update to patched version, assess impact

#### Escalation Process
1. **Package maintainer** attempts resolution
2. **Architecture team** reviews complex cases
3. **Security team** handles security-related issues
4. **Project maintainers** approve major changes

## Review and Evolution

### 1. Governance Review Cycle

#### Monthly Reviews
- Dependency metrics analysis
- Security vulnerability assessment
- Package size optimization
- Developer feedback collection

#### Quarterly Reviews
- Governance rule effectiveness
- Tooling and automation updates
- Process improvements
- Industry best practices adoption

### 2. Rule Updates

#### Amendment Process
1. **Proposal** - Document suggested change
2. **Review** - Architecture team evaluates impact
3. **Testing** - Validate in development environment
4. **Approval** - Project maintainers approve
5. **Communication** - Update documentation and team

#### Version Control
- Maintain governance document version history
- Tag major governance changes
- Communicate updates to all developers
- Update training materials accordingly

## Conclusion

This dependency governance framework ensures that the Craft Video Marketplace maintains clean, secure, and efficient package architecture throughout its development lifecycle. Regular monitoring, automated validation, and clear processes help prevent technical debt while enabling sustainable growth.

The governance model should evolve with the project, incorporating lessons learned and adapting to new challenges as the application scales in complexity and team size.