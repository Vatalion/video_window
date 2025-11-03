# Flutter Monorepo Integration Guide - Video Window Project

**Version:** Flutter 3.35.4+ / Dart 3.9.2+  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Sprint 1 Foundation

---

## Overview

This guide documents how Video Window organizes its Flutter codebase as a **monorepo** with multiple packages managed by Melos. This is NOT general Flutter package documentation - it's our specific structure, patterns, and conventions.

### Why Monorepo for Video Window?

- **Separation of Concerns:** Feature packages isolate domain logic from infrastructure
- **Code Sharing:** Common UI components and utilities shared across features
- **Independent Testing:** Each package has its own test suite
- **Scalability:** New features added as packages without affecting existing code
- **Team Collaboration:** Multiple developers can work on different packages simultaneously

### Architecture Philosophy
**Feature packages own presentation + use cases. Core package owns data + domain.**

---

## Project Structure

```
video_window_flutter/                    # Flutter app + Melos workspace
├── pubspec.yaml                         # Root app dependencies
├── melos.yaml                           # Melos workspace config
├── lib/
│   ├── main.dart                        # App entry point
│   ├── app_shell/                       # App bootstrap
│   │   ├── app.dart                     # MaterialApp configuration
│   │   ├── router.dart                  # GoRouter setup
│   │   └── theme.dart                   # App theme configuration
│   └── presentation/                    # Global presentation layer
│       └── bloc/                        # Global BLoCs (auth, app state)
│           ├── auth/
│           └── app/
├── test/                                # App-level tests
└── packages/                            # 🎯 MELOS-MANAGED PACKAGES
    ├── core/                            # ⚙️ DATA LAYER
    │   ├── pubspec.yaml
    │   ├── lib/
    │   │   ├── data/                    # Repositories, data sources
    │   │   │   ├── repositories/
    │   │   │   ├── sources/
    │   │   │   └── mappers/
    │   │   ├── domain/                  # Domain entities, value objects
    │   │   │   ├── entities/
    │   │   │   ├── value_objects/
    │   │   │   └── failures/
    │   │   ├── bloc/                    # Base BLoC classes
    │   │   │   ├── base_bloc.dart
    │   │   │   ├── base_list_bloc.dart
    │   │   │   └── serverpod_bloc.dart
    │   │   └── utils/                   # Cross-cutting utilities
    │   └── test/
    │
    ├── shared/                          # 🎨 DESIGN SYSTEM
    │   ├── pubspec.yaml
    │   ├── lib/
    │   │   ├── theme/                   # Theme tokens, colors, typography
    │   │   │   ├── color_palette.dart
    │   │   │   ├── typography.dart
    │   │   │   └── spacing.dart
    │   │   ├── widgets/                 # Reusable UI components
    │   │   │   ├── buttons/
    │   │   │   ├── cards/
    │   │   │   └── inputs/
    │   │   └── extensions/              # Dart extensions
    │   └── test/
    │
    └── features/                        # 🎯 FEATURE MODULES
        ├── auth/
        │   ├── pubspec.yaml
        │   ├── lib/
        │   │   ├── use_cases/           # Business logic
        │   │   │   ├── sign_in_use_case.dart
        │   │   │   └── sign_up_use_case.dart
        │   │   └── presentation/        # UI layer
        │   │       ├── bloc/
        │   │       │   ├── auth_bloc.dart
        │   │       │   ├── auth_event.dart
        │   │       │   └── auth_state.dart
        │   │       ├── pages/
        │   │       │   ├── sign_in_page.dart
        │   │       │   └── sign_up_page.dart
        │   │       └── widgets/
        │   │           ├── email_input.dart
        │   │           └── password_input.dart
        │   └── test/
        │       ├── use_cases/
        │       └── presentation/
        │
        ├── timeline/                    # Video capture/editing feature
        ├── commerce/                    # Marketplace/auction feature
        └── publishing/                  # Content publishing feature
```

---

## Package Types & Responsibilities

### Core Package (`packages/core/`)

**Purpose:** Centralized data layer and shared domain logic

**Contents:**
- `data/repositories/` - Repository implementations (interfaces from domain)
- `data/sources/` - Data sources (Serverpod client, local storage)
- `data/mappers/` - DTO ↔ Domain entity transformations
- `domain/entities/` - Business entities (User, Story, Offer, etc.)
- `domain/value_objects/` - Type-safe wrappers (EmailAddress, Money, etc.)
- `domain/failures/` - Domain failure types
- `bloc/` - Base BLoC classes for reuse across features
- `utils/` - Cross-cutting utilities (logging, date formatting, etc.)

**Key Rules:**
- ✅ ONLY package allowed to import `video_window_client` (Serverpod generated code)
- ✅ All data operations flow through core repositories
- ❌ NO Flutter/UI dependencies
- ❌ NO feature-specific logic

**Dependencies:**
```yaml
dependencies:
  video_window_client:
    path: ../../video_window_client  # Serverpod generated
  dartz: ^0.10.1                      # Functional programming (Either)
  equatable: ^2.0.5                   # Value equality
```

---

### Shared Package (`packages/shared/`)

**Purpose:** Design system and reusable UI components

**Contents:**
- `theme/` - Color palettes, typography, spacing tokens
- `widgets/` - UI components used across features (buttons, cards, inputs)
- `extensions/` - Dart/Flutter extensions (BuildContext helpers, etc.)

**Key Rules:**
- ✅ Flutter UI code allowed
- ✅ Generic, feature-agnostic components only
- ❌ NO business logic
- ❌ NO data operations
- ❌ NO feature-specific widgets (those go in feature packages)

**Dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
```

---

### Feature Packages (`packages/features/*/`)

**Purpose:** Self-contained feature modules with use cases + presentation

**Contents:**
- `use_cases/` - Feature-specific business logic (orchestrates repositories)
- `presentation/bloc/` - Feature BLoCs (extend core base classes)
- `presentation/pages/` - Full-screen pages
- `presentation/widgets/` - Feature-specific widgets

**Key Rules:**
- ✅ Depend on `core` for data access
- ✅ Depend on `shared` for UI components
- ✅ Own their feature's BLoC state management
- ❌ NO direct Serverpod client access (use core repositories)
- ❌ NO data/repository implementations (use core)
- ❌ NO cross-feature dependencies (auth ❌→ timeline)

**Dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../../core
  shared:
    path: ../../shared
  flutter_bloc: ^8.1.3
```

---

## Package Dependency Rules

### Allowed Dependencies

```
Main App
  ↓ depends on
Feature Packages (auth, timeline, commerce, publishing)
  ↓ depends on
Core Package (data + domain)
  ↓ depends on
Serverpod Client (video_window_client)
  
Feature Packages & Main App
  ↓ depends on
Shared Package (UI components)
```

### Forbidden Dependencies

```
❌ Feature → Feature (auth → timeline)
❌ Shared → Core (UI depending on data)
❌ Feature → Serverpod Client (bypass data layer)
❌ Core → Feature (circular dependency)
```

---

## Creating a New Feature Package

### Step 1: Scaffold Package Structure

```bash
cd video_window_flutter/packages/features
mkdir -p my_feature/{lib/{use_cases,presentation/{bloc,pages,widgets}},test/{use_cases,presentation}}
cd my_feature
```

### Step 2: Create `pubspec.yaml`

```yaml
name: my_feature
description: Description of my feature
publish_to: none  # Never publish internal packages

environment:
  sdk: '>=3.5.6 <4.0.0'
  flutter: '>=3.19.6'

dependencies:
  flutter:
    sdk: flutter
  
  # Internal dependencies
  core:
    path: ../../core
  shared:
    path: ../../shared
  
  # External dependencies
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

### Step 3: Create Package Entry Point

```dart
// lib/my_feature.dart
library my_feature;

// Export use cases
export 'use_cases/my_use_case.dart';

// Export presentation
export 'presentation/bloc/my_bloc.dart';
export 'presentation/pages/my_page.dart';
```

### Step 4: Link in Melos Workspace

```bash
cd ../../..  # Back to video_window_flutter/
melos bootstrap
```

Melos automatically discovers packages matching `packages/**` in `melos.yaml`.

---

## Using Packages in the Main App

### Importing Feature Packages

```dart
// lib/app_shell/router.dart
import 'package:auth/auth.dart';  // Feature package
import 'package:core/core.dart';  // Core package
import 'package:shared/shared.dart';  // Shared package

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInPage(),  // From auth package
    ),
  ],
);
```

### Dependency Injection Pattern

```dart
// lib/main.dart
void main() {
  // Initialize core services
  final serverpodClient = Client('http://localhost:8080/');
  final userRepository = UserRepositoryImpl(serverpodClient);  // From core
  
  // Create feature BLoCs
  final authBloc = AuthBloc(
    signInUseCase: SignInUseCase(userRepository),  // From auth package
    signUpUseCase: SignUpUseCase(userRepository),
  );
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## Testing Package Boundaries

### Unit Test: Use Case Depends on Core Repository

```dart
// packages/features/auth/test/use_cases/sign_in_use_case_test.dart
import 'package:core/core.dart';
import 'package:auth/use_cases/sign_in_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late SignInUseCase useCase;
  late MockUserRepository repository;
  
  setUp(() {
    repository = MockUserRepository();
    useCase = SignInUseCase(repository);  // ✅ Depends on core interface
  });
  
  test('calls repository with correct credentials', () async {
    // Test implementation
  });
}
```

### Widget Test: Feature Page Uses Shared Widgets

```dart
// packages/features/auth/test/presentation/pages/sign_in_page_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/widgets/buttons/primary_button.dart';  // ✅ Shared widget
import 'package:auth/presentation/pages/sign_in_page.dart';

void main() {
  testWidgets('renders PrimaryButton from shared package', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));
    
    expect(find.byType(PrimaryButton), findsOneWidget);  // ✅ Finds shared widget
  });
}
```

---

## Common Patterns

### Pattern 1: Feature BLoC Extends Core Base Class

```dart
// packages/core/lib/bloc/base_bloc.dart
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    // Centralized error logging
    super.onError(error, stackTrace);
  }
}

// packages/features/auth/lib/presentation/bloc/auth_bloc.dart
import 'package:core/bloc/base_bloc.dart';

class AuthBloc extends BaseBloc<AuthEvent, AuthState> {  // ✅ Extends base
  AuthBloc({required this.signInUseCase}) : super(AuthInitial());
  
  final SignInUseCase signInUseCase;
}
```

### Pattern 2: Use Case Calls Core Repository

```dart
// packages/core/lib/data/repositories/user_repository.dart
abstract class UserRepository {
  Future<Either<Failure, User>> signIn(EmailAddress email, Password password);
}

// packages/features/auth/lib/use_cases/sign_in_use_case.dart
import 'package:core/core.dart';

class SignInUseCase {
  final UserRepository repository;  // ✅ Depends on core interface
  
  SignInUseCase(this.repository);
  
  Future<Either<Failure, User>> call(EmailAddress email, Password password) {
    return repository.signIn(email, password);  // ✅ Delegates to core
  }
}
```

### Pattern 3: Feature Widget Uses Shared Components

```dart
// packages/features/auth/lib/presentation/pages/sign_in_page.dart
import 'package:shared/widgets/buttons/primary_button.dart';
import 'package:shared/widgets/inputs/email_input.dart';

class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          EmailInput(/* ... */),  // ✅ Shared widget
          PrimaryButton(/* ... */),  // ✅ Shared widget
        ],
      ),
    );
  }
}
```

---

## Package Configuration Details

### `pubspec.yaml` Required Fields

```yaml
name: package_name        # Must match directory name
description: Brief description
publish_to: none          # CRITICAL: Prevents accidental pub.dev publish

environment:
  sdk: '>=3.5.6 <4.0.0'
  flutter: '>=3.19.6'     # Match project minimum
```

### Path Dependencies Syntax

```yaml
dependencies:
  core:
    path: ../../core        # Relative to package directory
  shared:
    path: ../../shared
```

**Melos resolves these automatically after `melos bootstrap`.**

---

## Troubleshooting

### Issue: "Package not found" errors

**Symptoms:** IDE shows import errors, can't find package

**Solution:**
```bash
cd video_window_flutter
melos clean
melos bootstrap
# Then restart IDE
```

### Issue: Circular dependency detected

**Symptoms:** "Depends on itself" error

**Cause:** Feature A → Feature B → Feature A

**Solution:** Extract shared code to `core` or `shared` package. Features should NEVER depend on each other.

### Issue: Can't access Serverpod client in feature

**Symptoms:** Import error for `video_window_client`

**Solution:** Don't import directly. Use core repository instead:
```dart
// ❌ WRONG
import 'package:video_window_client/video_window_client.dart';

// ✅ CORRECT
import 'package:core/data/repositories/user_repository.dart';
```

---

## Reference Links

- **Official Docs:** https://docs.flutter.dev/packages-and-plugins/developing-packages
- **Our Melos Guide:** `docs/frameworks/melos-integration-guide.md`
- **Architecture Decisions:** `docs/architecture/project-structure-implementation.md`
- **BLoC Patterns:** `docs/frameworks/bloc-integration-guide.md`

---

## Quick Reference

### Package Types Matrix

| Package | Purpose | Can Import | Cannot Import |
|---------|---------|------------|---------------|
| **core** | Data + Domain | Serverpod client, external packages | Flutter UI, features, shared |
| **shared** | UI Components | Flutter, external packages | Core, features, Serverpod |
| **features** | Use Cases + UI | Core, shared, Flutter | Other features, Serverpod |

### Command Reference

```bash
# Create new feature package
mkdir -p packages/features/my_feature/lib/{use_cases,presentation}

# Link new package
melos bootstrap

# Test specific package
melos exec --scope=my_feature -- flutter test

# Run codegen for package with build_runner
melos run generate
```

---

**Next Steps for Developers:**
1. Read this guide + Melos guide before Story 01.1
2. Review existing `core` and `shared` structure during implementation
3. Follow feature package template when adding new features
4. Update this guide with new patterns discovered during development

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial integration guide created for Sprint 1, verified against Flutter 3.35.5 docs | Winston (Architect) |

---

**Related Documentation:**
- `docs/frameworks/melos-integration-guide.md` - Workspace management
- `docs/frameworks/bloc-integration-guide.md` - State management patterns
- `docs/architecture/coding-standards.md` - Code conventions
- `docs/architecture/project-structure-implementation.md` - Overall architecture
