# Package Architecture Requirements# Package Architecture Requirements



## Goals and Background## Goals and Background Context



### Goals### Goals

- Preserve strict boundaries between presentation, domain, and data layers.- Establish clear modular boundaries for maintainable scaling

- Enable parallel feature development without cross-package coupling.- Enable parallel development across feature teams

- Keep Serverpod, Flutter, and shared models synchronized through a predictable structure.- Ensure loose coupling and high cohesion between modules

- Provide clear guardrails for dependency management, testing, and release readiness.- Support independent testing and deployment readiness

- Provide clear guidance for package dependency management

### Background

Craft Video Marketplace is a Serverpod-first modular monolith. The Flutter workspace (`video_window_flutter/`) is managed by Melos and mirrors backend bounded contexts. Centralizing data access inside the core package while limiting feature packages to use cases and presentation keeps the stack consistent with Serverpod’s generated clients.### Background Context

The Craft Video Marketplace requires a modular package architecture to support complex feature interactions while maintaining development velocity. This document defines the complete package separation requirements for both Flutter client and Serverpod backend, ensuring alignment with the modular monolith strategy defined in the main architecture document.

## Functional Requirements (PSR)

- **PSR1**: Feature code lives under `video_window_flutter/packages/features/<feature>/`.## Requirements

- **PSR2**: Each feature package exposes only `use_cases/` and `presentation/` directories. No `data/` or `domain/` folders are permitted inside feature packages.- **PSR2**: Each feature package SHALL contain `use_cases/` and `presentation/` layers only. Data layer operations SHALL be centralized in the core package.

- **PSR3**: `video_window_flutter/packages/core/` owns all repositories, datasources, mappers, services, and value objects.- **PSR3**: Serverpod backend SHALL organize modules as separate packages under `serverpod/packages/modules/`

- **PSR4**: Shared theming, design tokens, and reusable widgets live in `video_window_flutter/packages/shared/`.- **PSR4**: Shared domain models SHALL reside in `packages/shared_models/` for client-server consistency

- **PSR5**: Serverpod-generated protocol models reside in `video_window_shared/` and are regenerated via `serverpod generate`; never edit them manually.- **PSR5**: Core utilities and design system SHALL be isolated in `packages/core/` and `packages/design_system/`

- **PSR6**: Every package exports a single barrel (`lib/<package_name>.dart`) that defines its public API surface.

- **PSR7**: Cross-package contracts must use value objects or strongly typed entities—no raw strings or maps across boundaries.#### Package Interface Requirements

- **PSR8**: Feature packages may depend only on `core`, `shared`, and approved shared utilities. Feature-to-feature dependencies are forbidden.- **PSR6**: Each package SHALL expose a single public API file (`lib/<package_name>.dart`)

- **PSR9**: Core and shared packages may depend on each other only when the dependency flow remains acyclic.- **PSR7**: Package interfaces SHALL define clear input/output contracts for all public methods

- **PSR8**: Internal implementation details SHALL be hidden through proper library privacy

## Non-Functional Requirements (NFR)- **PSR12**: Feature packages MAY depend on core and shared packages only

- **NFR1**: Each package includes a README describing responsibilities, public API, and testing strategy.- **PSR13**: Core packages SHALL NOT depend on feature packages (circular dependency prevention)

- **NFR2**: Package size stays <10k LOC unless reviewed by architecture.#### Maintainability Requirements

- **NFR3**: Unit-test coverage per package ≥80%; critical flows ≥90%.- **NFR1**: Each package SHALL be independently understandable without knowledge of other packages

- **NFR4**: Constructor-level validation ensures value objects are used before data reaches repositories.- **NFR2**: Package size SHALL not exceed 10,000 lines of code without architectural review

- **NFR5**: Breaking changes to public APIs follow semantic versioning rules and ship with documented migration steps.- **NFR3**: Package public API SHALL maintain backward compatibility within major versions

- **NFR6**: Performance budgets (startup, memory, frame times) are documented and validated for core and feature packages during CI.- **NFR7**: Package integration tests SHALL validate cross-package interactions

- **NFR8**: Mock implementations SHALL be provided for all external dependencies

## Workspace Layout- **NFR12**: Package bundle size impact SHALL be tracked and optimized

- **NFR13**: Cross-package communication overhead SHALL not exceed 10ms per call

```### Flutter Client Package Organization

video_window/

├── video_window_flutter/               # Melos workspace root#### Core Packages

│   ├── lib/                            # App shell, global state, routing```

│   │   └── presentation/bloc/          # Global BLoCs (auth, app, session)video_window_flutter/

│   └── packages/├── lib/                               # App shell, global state, routing

│       ├── core/│   ├── main.dart                      # App entry point

│       │   ├── lib/data/               # Datasources, repositories, mappers│   ├── app.dart                       # App configuration

│       │   ├── lib/value_objects/      # Validated primitives│   └── presentation/

│       │   ├── lib/services/           # Cross-cutting services (logging, auth, analytics)│       └── bloc/                      # Global BLoCs (app, auth, session)

│       │   └── lib/core.dart           # Barrel export└── packages/

│       ├── shared/  ├── core/                          # Centralized data layer + shared utilities

│       │   ├── lib/theme/              # Design tokens, typography, color ramps  │   ├── lib/

│       │   ├── lib/widgets/            # Accessible, reusable UI components  │   │   ├── data/                  # Datasources, repositories, mappers

│       │   └── lib/shared.dart         # Barrel export  │   │   ├── value_objects/         # Validated primitives

│       └── features/  │   │   ├── services/              # Cross-cutting services

│           ├── auth/  │   │   └── core.dart              # Public API export

│           │   ├── lib/use_cases/  │   └── pubspec.yaml

│           │   └── lib/presentation/   # bloc/, pages/, widgets/  ├── shared/                        # Design system + shared widgets

│           ├── timeline/  │   ├── lib/

│           ├── commerce/  │   │   ├── theme/                 # Tokens, typography, color ramps

│           ├── publishing/  │   │   ├── widgets/               # Reusable UI components

│           └── notifications/  │   │   └── shared.dart            # Public API export

├── video_window_server/                # Serverpod backend modules  │   └── pubspec.yaml

└── video_window_shared/                # Generated protocol code (read-only)  └── features/                      # Feature packages expose only use_cases + presentation

```    ├── auth/

    │   ├── lib/

> **Reminder:** Feature packages must never introduce `data/` or custom repository logic. All persistence, caching, and networking remains in `packages/core/`.    │   │   ├── use_cases/

    │   │   │   ├── sign_in_use_case.dart

### Serverpod Alignment    │   │   │   └── sign_out_use_case.dart

- Backend modules live under `video_window_server/lib/src/endpoints/<context>/` and share protocol definitions with `video_window_shared/`.    │   │   └── presentation/

- Any change to protocol YAML or Serverpod models requires `serverpod generate`, followed by a commit that captures regenerated client/shared code.    │   │       ├── bloc/

    │   │       ├── pages/

## Barrel Export Template    │   │       └── widgets/

    │   └── pubspec.yaml

```dart    ├── timeline/

// video_window_flutter/packages/features/auth/lib/auth.dart    ├── commerce/

library auth;    ├── publishing/

    └── notifications/

export 'use_cases/sign_in_use_case.dart';```

export 'use_cases/sign_out_use_case.dart';

export 'presentation/bloc/auth_bloc.dart';> **Note:** Serverpod-generated protocol models live outside the Flutter workspace in `video_window_shared/` and are consumed via the core package repositories. These files are regenerated via `serverpod generate` and must not be edited manually.

export 'presentation/pages/sign_in_page.dart';

export 'presentation/widgets/sign_in_form.dart';### Serverpod Backend Module Organization

```

#### Module Structure

Core and shared packages follow the same pattern, re-exporting only supported public APIs.```

serverpod/packages/modules/

## Dependency Graph├── identity/                # Identity and access management

│   ├── lib/

```│   │   ├── endpoints/      # API endpoints

Feature ─────▶ Core│   │   ├── models/         # Database models

Feature ─────▶ Shared│   │   ├── services/       # Business logic

Core   ─────▶ Shared (UI + analytics only)│   │   └── migrations/     # Database migrations

Shared ────┐│   └── pubspec.yaml

            └▶ (no dependencies on Core or Features)├── story/                   # Story management

video_window_shared (generated) ⇄ Core (read-only usage)├── media_pipeline/          # Media processing pipeline

```├── offers/                  # Offer and auction management

├── payments/                # Payment processing

Rules:├── orders/                  # Order and fulfillment

- Feature ⇄ Feature dependencies are prohibited.├── notifications/           # Notification services

- Core never depends on any feature package.└── analytics/               # Analytics and reporting

- Shared does not depend on Core to prevent widget/data tangling.```

- Core consumes `video_window_shared` DTOs but never mutates generated code.

## Package Interface Contracts

## Dependency Injection & Composition

### Standard Package API Template

Constructor injection is mandatory. Compose dependencies with `RepositoryProvider`, `BlocProvider`, or explicit parameters.Each package SHALL expose its functionality through a single public API file with the following structure:



```dart```dart

class AppRoot extends StatelessWidget {// lib/package_name.dart

  const AppRoot({super.key, required this.serverpodClient});// Export feature-specific use cases

export 'use_cases/auth_usecase.dart';

  final ServerpodClient serverpodClient;export 'use_cases/login_usecase.dart';



  @override// Export main UI components

  Widget build(BuildContext context) {export 'presentation/bloc/auth_bloc.dart';

    return RepositoryProvider<AuthRepository>(export 'presentation/pages/auth_page.dart';

      create: (_) => AuthRepositoryImpl(client: serverpodClient),export 'presentation/widgets/auth_form.dart';

      child: BlocProvider(

        create: (context) => AuthBloc(// Export any public utilities

          signInWithEmail: SignInWithEmailUseCase(context.read<AuthRepository>()),export 'utils/package_utils.dart';

        ),```

        child: const AppRouter(),

      ),### Cross-Package Communication Patterns

    );

  }#### Event-Driven Communication

}- **Pattern**: Packages communicate through typed events

```- **Implementation**: Use `package:event_bus` or similar

- **Contract**: Event definitions shared in `shared_models`

No service locators (`GetIt`, etc.) are permitted. Features receive dependencies via constructors to keep coupling explicit.- **Implementation**: Feature packages use use cases to coordinate with core repositories

- **Contract**: Repository interfaces defined in core package

## Communication Patterns- **Implementation**: Use `get_it` or similar DI framework

- Repositories return `Either<Failure, Success>` to encode domain outcomes.- **Contract**: Services registered at app initialization

- Value objects in `core/value_objects` enforce validation before data leaves presentation.### Allowed Dependency Directions

- Feature BLoCs map domain failures to user-safe messaging and analytics events.```

- Cross-feature collaboration happens through core services or Serverpod endpoints, never by importing another feature package directly.Feature Packages → Core Packages ✓

Feature Packages → Shared Models ✓

## Tooling & CIFeature Packages → Design System ✓

Core Packages → Feature Packages ✗

### Melos (`video_window_flutter/melos.yaml`)Shared Models → Feature Packages ✗

```yamlDesign System → Feature Packages ✗

name: video_window_flutter```

packages:

  - packages/core### Dependency Management Guidelines

  - packages/shared

  - packages/features/*#### Adding New Dependencies

1. **Check if dependency already exists** in core packages

scripts:2. **Evaluate impact** on package size and performance

  setup: |3. **Consider alternative** implementations

    melos exec --flutter pub get4. **Document rationale** in package README

    melos exec --dart run build_runner build5. **Update documentation** and examples

  analyze: melos exec --flutter analyze --fatal-infos --fatal-warnings

  format: melos exec --dart format . --set-exit-if-changed#### Version Management

  test: melos run test:unit1. **Pin major versions** for shared dependencies

  test:unit: melos exec --flutter test test/unit --coverage2. **Use compatible ranges** for minor versions

3. **Test compatibility** across all dependent packages

environment:4. **Document upgrade procedures** with breaking changes

  sdk: '>=3.5.6 <4.0.0'

  flutter: '>=3.19.6'## Development Workflow

```

### Multi-Package Development Process

### CI Quality Gates

- Format + analyze + unit tests run per package prior to merge.#### Local Development

- Dependency graph checks reject cycles or unauthorized edges.1. **Use Flutter workspaces** or Melos for package management

- `melos run test:coverage:check` enforces coverage thresholds.2. **Link packages** via path dependencies for development

- Regeneration of `video_window_client/` and `video_window_shared/` is validated on protocol changes.3. **Run tests** across all packages with single command

4. **Hot reload** should work across package boundaries

## Migration Checklist

1. Scaffold package directories under `video_window_flutter/` per structure above.#### Testing Strategy

2. Move all repositories/datasources into `packages/core/` and expose clean interfaces.1. **Unit tests** within each package

3. Refactor feature packages to depend on use cases, not repositories.2. **Integration tests** for package interactions

4. Update imports to consume barrel exports (`package:auth/auth.dart`, `package:core/core.dart`, etc.).3. **End-to-end tests** for complete user flows

5. Document package responsibilities and tests in each package README.4. **Performance tests** for package boundaries



Following these guardrails keeps the Flutter workspace aligned with the Serverpod monolith, enabling scalable teamwork without drifting into tightly coupled or duplicate data layers.#### Build and Release

1. **Independent package builds** for parallel development
2. **Dependency verification** before release
3. **Automated testing** across all packages
4. **Version tagging** with semantic versioning

### Tooling Configuration

#### Melos Configuration (melos.yaml)
```yaml
name: video_window
packages:
  - packages/*
  - packages/features/*

scripts:
  analyze: melos exec -- flutter analyze
  test: melos exec -- flutter test
  build: melos exec -- flutter build apk
  format: melos exec -- dart format .

environments:
  sdk: '>=3.8.0 <4.0.0'
  flutter: '>=3.35.0'
```

#### CI/CD Pipeline
1. **Parallel package analysis** and testing
2. **Dependency vulnerability scanning**
3. **Package size monitoring**
4. **Cross-package integration testing**

## Migration Strategy

### Phase 1: Foundation Setup
- Create package directory structure
- Set up Melos/Flutter workspace
- Migrate existing code to core packages
- Maintain backward compatibility during migration
- Update imports and dependencies
- Implement cross-package communication patterns
- Add comprehensive package tests
### Package Compliance Checklist
- [ ] Single public API file exists
- [ ] No circular dependencies
- [ ] Unit test coverage >= 80%
2. **Package size monitoring** with alerts
3. **Test coverage enforcement** via CI
4. **Performance regression testing**
5. **Security vulnerability scanning**

## Conclusion

These package architecture requirements provide the foundation for a scalable, maintainable, and well-structured Flutter + Serverpod application. Following these guidelines will ensure that the Craft Video Marketplace can grow in complexity while maintaining code quality and developer productivity.

Regular reviews of these requirements should occur as the application evolves and new patterns emerge in the Flutter ecosystem.