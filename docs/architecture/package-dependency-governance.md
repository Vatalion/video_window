# Package Dependency Governance# Package Dependency Governance



## Purpose## Overview

This document defines how packages inside the Craft Video Marketplace monorepo depend on one another. The goal is to keep the Flutter workspace (`video_window_flutter/`) in lockstep with the Serverpod backend while avoiding cyclic or implicit dependencies.

This document defines the governance model for managing dependencies between packages in the Craft Video Marketplace project. It establishes rules, processes, and tools to maintain clean dependency architecture throughout the development lifecycle.

## Canonical Dependency Flow

```## Governance Principles

Feature Packages  ─────▶  Core

Feature Packages  ─────▶  Shared (design system)### 1. Dependency Direction Rules

Core              ─────▶  Shared (UI/analytics only)Dependencies must follow a strict hierarchical pattern to prevent circular dependencies and maintain clean architecture.

video_window_shared (generated models) → Core (read-only)

```#### Allowed Dependency Flow

```

Rules:┌─────────────────┐

- Feature ⇄ Feature dependencies are **not allowed**.│   Feature       │ ──────┐

- Core must never depend on a feature package.│   Packages      │       │

- Shared never depends on Core to avoid data ↔️ UI tangles.└─────────────────┘       │

- Generated protocol code (`video_window_shared/`) is consumed by `core` repositories but is never modified.          │               │

          ▼               ▼

## Dependency Categories┌─────────────────┐  ┌──────────────┐

- **Production dependencies**: Declared under `dependencies:`; must be pinned (`^x.y.z` or exact versions) and security-scanned.│   Core          │  │ Shared       │

- **Development dependencies**: Declared under `dev_dependencies:`; may use looser version ranges but must not leak into production builds.│   Packages      │  │ Models       │

- **Build/Tooling dependencies**: Added only to the root workspace or package-specific `tool/` scripts. They may not introduce runtime imports.└─────────────────┘  └──────────────┘

          │               │

## Adding a New Dependency          └───────┬───────┘

1. **Check the DAG**                  ▼

   - Does the new dependency introduce a forbidden edge (e.g., feature → feature)?        ┌──────────────┐

   - Is the dependency already exposed via another package (reuse before add)?        │ Design       │

2. **Evaluate cost**        │ System       │

   - Bundle size, cold-start impact, code size.        └──────────────┘

   - Maintenance signal (release cadence, community support, license).```

3. **File an ADR or lightweight RFC**

   - Required when introducing networking, persistence, crypto, or analytics libraries.#### Forbidden Dependencies

4. **Security & compliance review**- Feature packages depending on other feature packages

   - Mandatory for dependencies touching auth, payment, or personal data.- Core packages depending on feature packages

5. **Document the rationale** in the package README and update the dependency matrix below.- Shared models depending on feature packages

- Any circular dependency chains

## Dependency Matrix Template

| Package | Allowed Dependencies | Notes |### 2. Dependency Categories

|---------|----------------------|-------|

| `core` | Flutter SDK, `serverpod_client`, shared utilities, analytics SDKs, HTTP/storage libraries | Owns repositories, datasources, value objects |#### Production Dependencies

| `shared` | Flutter SDK, accessibility helpers, design-system dependencies | No data/storage/networking libraries |Runtime dependencies required for the package to function:

| `features/<feature>` | `core`, `shared`, Flutter SDK, feature-specific blocs/use cases | No direct HTTP/database packages |- Must be explicitly declared in `dependencies:` section

- Must be version-pinned for stability

## pubspec Template (Feature Package)- Must have security vulnerability scanning

```yaml

name: auth#### Development Dependencies

publish_to: 'none'Build-time and testing dependencies:

- Must be declared in `dev_dependencies:` section

environment:- Can be version-ranged for flexibility

  sdk: '>=3.5.6 <4.0.0'- Not included in production builds

  flutter: '>=3.19.6'

#### Peer Dependencies

dependencies:Dependencies that must be provided by the consuming package:

  flutter:- Used when multiple packages need the same dependency version

    sdk: flutter- Must be clearly documented

  core:- Must include version compatibility matrix

    path: ../../core

  shared:## Dependency Management Rules

    path: ../../shared

  flutter_bloc: ^8.1.5### 1. Adding New Dependencies

  equatable: ^2.0.5

#### Evaluation Criteria

dev_dependencies:Before adding a new dependency, teams must evaluate:

  flutter_test:

    sdk: flutter1. **Necessity Assessment**

  bloc_test: ^9.1.7   - Is the functionality critical to the package?

  mocktail: ^1.0.3   - Can it be implemented in-house instead?

```   - Is there a lighter-weight alternative?



> **Reminder:** Feature packages never depend on `serverpod_client` or third-party HTTP clients. All remote access flows through `core` repositories.2. **Impact Assessment**

   - How will this affect package size?

## Dependency Injection Guidance   - What are the security implications?

Constructor injection keeps dependency relationships explicit.   - How does this affect build time?



```dart3. **Maintainability Assessment**

class SignInPage extends StatelessWidget {   - Is the library actively maintained?

  const SignInPage({super.key});   - Does it have a compatible license?

   - Is there good community support?

  @override

  Widget build(BuildContext context) {#### Approval Process

    return BlocProvider(1. **Create RFC** (Request for Comments) document

      create: (_) => AuthBloc(2. **Technical review** by architecture team

        signInWithEmail: SignInWithEmailUseCase(3. **Security review** by security team

          context.read<AuthRepository>(),4. **Performance review** by performance team

        ),5. **Final approval** by project maintainers

      ),

      child: const SignInView(),### 2. Version Management

    );

  }#### Semantic Versioning Compliance

}- Follow semantic versioning (SemVer) for all dependencies

```- Pin major versions: `^1.0.0` (allows 1.x.x, not 2.0.0)

- Use compatible ranges for minor versions: `^1.2.0` (allows 1.2.x+)

- Register repositories/services at the app shell (`video_window_flutter/lib/`) using `RepositoryProvider`.- Document all version constraints and rationale

- No service locators (`GetIt`, etc.) are permitted.

- Avoid global singletons; prefer scoped providers or explicit constructor parameters.#### Update Strategy

1. **Regular Updates**: Monthly dependency update reviews

## Version Management2. **Security Updates**: Immediate updates for CVEs

- Pin majors (`^x.y.z`) and document rationale for overrides in package README files.3. **Major Version Updates**: Requires migration plan and testing

- Schedule monthly "dependency health" reviews to apply patch/minor updates.4. **Breaking Changes**: Requires communication across all dependent packages

- Security advisories trigger immediate upgrades or mitigations.

- Breaking changes require migration notes and CI validation across all packages.### 3. Dependency Conflict Resolution



## Conflict Resolution#### Conflict Detection

1. Detect via `melos exec --flutter pub outdated` or CI dependency graph checks.Automated tools must detect and alert on:

2. Identify shared constraints; prefer upgrading to the newest compatible version.- Version conflicts between packages

3. If necessary, introduce a temporary dependency override in the workspace root and file a follow-up story to remove it.- Transitive dependency conflicts

4. Add a postmortem entry in the dependency log (`docs/architecture/dependency-log.md`, TBD) for historical traceability.- License incompatibilities

- Security vulnerabilities

## Compliance Checklist

- [ ] Dependency appears on the approved library list.#### Resolution Process

- [ ] No forbidden dependency edges introduced.1. **Identify conflict scope** (affected packages)

- [ ] Security review complete (if required).2. **Evaluate solution options**:

- [ ] README updated with rationale and usage notes.   - Upgrade conflicting dependency

- [ ] Tests updated to cover new dependency behavior.   - Use dependency override

   - Refactor to remove dependency

Adhering to these rules keeps the Melos workspace predictable, prevents circular dependencies, and aligns the Flutter client with Serverpod’s modular monolith strategy.3. **Test solution** across all affected packages

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