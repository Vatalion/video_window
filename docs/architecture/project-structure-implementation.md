# Project Structure Implementation Guide# Craft Video Marketplace - Project Structure Implementation Guide



This guide explains how to stand up the canonical workspace layout for Craft Video Marketplace and migrate existing code into it.## Current State Analysis



## Target Layout### Existing Project Structure

``````

video_window/video_window/

├── video_window_server/                # Serverpod backend├── lib/

├── video_window_client/                # Generated Serverpod client (read-only)│   └── main.dart                # Basic app entry point

├── video_window_shared/                # Generated protocol models (read-only)├── pubspec.yaml                 # Dependencies configured for Serverpod-first approach

├── video_window_flutter/               # Flutter Melos workspace└── docs/                        # Comprehensive architecture documentation

│   ├── lib/                            # App shell, routing, global blocs```

│   └── packages/

│       ├── core/                       # Datasources, repositories, services, value objects**Current Implementation**: Clean Flutter project with Serverpod-first dependency configuration and comprehensive architecture documentation.

│       ├── shared/                     # Design system + shared widgets

│       └── features/**Target Implementation**: Comprehensive marketplace platform with unified package architecture, Serverpod backend, and full e-commerce capabilities.

│           ├── auth/

│           │   ├── lib/use_cases/---

│           │   └── lib/presentation/   # bloc/, pages/, widgets/

│           ├── timeline/## Target Project Structure

│           ├── commerce/

│           ├── publishing/### Unified Package Architecture

│           ├── notifications/

│           └── future features…**Package structure follows the specifications defined in `package-architecture-requirements.md`.**

└── docs/                               # Architecture + product documentation

``````

video_window/                          # Root project directory

Key expectations:├── packages/                          # Flutter packages managed by Melos

- Feature packages expose **only** `use_cases/` and `presentation/`. No `data/` or `domain/` folders live inside features.│   ├── core/                          # Core utilities, data layer, base classes

- All persistence, networking, caching, and Serverpod integration lives under `packages/core/`.│   ├── shared/                        # Shared models, design system, common widgets

- Shared UI primitives, tokens, and accessibility utilities live under `packages/shared/`.│   ├── features/                      # Feature packages

- `video_window_client/` and `video_window_shared/` are regenerated via `serverpod generate` and must remain untouched.│   │   ├── auth/                      # Authentication feature

│   │   ├── timeline/                  # Timeline editing feature

## Bootstrap Steps│   │   ├── publishing/                # Content publishing feature

1. `cd video_window`│   │   ├── commerce/                  # Commerce features

2. Create workspace skeleton:│   │   └── notifications/             # Notification management

   ```bash│   └── mobile_client/                 # Main Flutter application

   mkdir -p video_window_flutter/packages/{core,shared,features}├── serverpod/                         # Serverpod backend

   mkdir -p video_window_flutter/lib/presentation/bloc│   ├── packages/

   ```│   │   └── modules/                   # Serverpod modules

3. Initialize Melos in `video_window_flutter/` (see `melos-configuration.md`).│   │       ├── identity/              # User authentication and management

4. Scaffold feature directories:│   │       ├── story/                 # Story content management

   ```bash│   │       ├── offers/                # Offers and auctions

   for feature in auth timeline commerce publishing notifications; do│   │       ├── payments/              # Payment processing

     mkdir -p "video_window_flutter/packages/features/$feature/lib/use_cases"│   │       └── orders/                # Order fulfillment

     mkdir -p "video_window_flutter/packages/features/$feature/lib/presentation/{bloc,pages,widgets}"├── docs/                              # Architecture documentation

   done├── melos.yaml                         # Workspace configuration

   ```└── README.md                          # Project documentation

5. Add minimal `pubspec.yaml` for each package (`core`, `shared`, and every feature). Ensure each package has a unique `name` and `publish_to: 'none'`.```

6. Wire path dependencies:

   ```yaml**Note**: This implements the simplified 3-level structure (core, shared, features) as recommended for better maintainability.

   # Example: video_window_flutter/packages/features/auth/pubspec.yaml

   dependencies:### Main Flutter Application Structure (`packages/mobile_client/`)

     flutter:

       sdk: flutterThe mobile client contains the app shell and global state management:

     core:

       path: ../../core```

     shared:packages/mobile_client/

       path: ../../shared├── lib/

   ```│   ├── main.dart                      # App initialization

7. Create barrel exports (`lib/core.dart`, `lib/shared.dart`, `lib/auth.dart`, etc.).│   ├── app.dart                       # App configuration and providers

│   └── presentation/

## Migrating Existing Code│       ├── bloc/                      # Global BLoCs

1. Move repositories, datasources, and value objects into `packages/core/`.│       │   ├── app_bloc.dart          # Global app state

2. Update imports to use barrel exports (`package:core/core.dart`, `package:auth/auth.dart`).│       │   ├── auth_bloc.dart         # Global authentication state

3. Relocate UI widgets and design tokens into `packages/shared/`.│       │   └── user_session_bloc.dart # User session management

4. Refactor feature-specific logic into use cases + presentation layers.│       └── routes/

5. Ensure global blocs (auth/app/session) live in `video_window_flutter/lib/presentation/bloc/`.│           └── app_router.dart        # GoRouter configuration

6. Run `melos run format`, `melos run analyze`, and `melos run test` to verify migration.├── android/                           # Android platform configuration

├── ios/                               # iOS platform configuration

## Serverpod Alignment├── macos/                             # macOS platform configuration

- Back-end modules mirror front-end features (identity, story, offers, payments, orders, notifications).├── linux/                             # Linux platform configuration

- After modifying protocol YAML or Serverpod models, run:├── windows/                           # Windows platform configuration

  ```bash└── test/                              # Integration and widget tests

  cd video_window_server```

  serverpod generate

  ```### Feature Package Structure

  Commit updated `video_window_client/` and `video_window_shared/` along with your backend changes.

**Feature packages follow the simplified structure defined in PSR2 (see `package-architecture-requirements.md#feature-packages`).**

## Quality Gates

- Each package ships with unit tests (≥80% coverage) and README documentation.According to **PSR2**: "Each feature package SHALL contain `use_cases/` and `presentation/` layers only. Data layer operations SHALL be centralized in the core package."

- No feature package introduces its own HTTP client or database access.

- Dependency graph remains acyclic per [`package-dependency-governance.md`](package-dependency-governance.md).**For detailed feature structure examples, see:**

- CI validates `melos run format`, `melos run analyze`, `melos run test`, and coverage thresholds.- `package-architecture-requirements.md#feature-packages` - Complete structure specification

- `coding-standards.md#feature-package-structure` - Implementation examples

Following this plan keeps the workspace consistent with the documented architecture and prevents regressions as new features are added.

This section focuses on implementation steps for creating feature packages within this architecture.

### Serverpod Backend Structure

**Serverpod backend follows the modular architecture defined in PSR3 (see `package-architecture-requirements.md#serverpod-backend-module-organization`).**

According to **PSR3**: "Serverpod backend SHALL organize modules as separate packages under `serverpod/packages/modules/`."

```
serverpod/
├── config/
│   ├── config.yaml                    # Serverpod configuration
│   ├── database.yaml                  # Database configuration
│   └── redis.yaml                     # Redis configuration
├── packages/
│   └── modules/                      # Modular backend architecture
│       ├── identity/                  # Identity and access management
│       │   ├── lib/
│       │   │   ├── endpoints/         # Auth endpoints
│       │   │   ├── models/            # User/Session models
│       │   │   ├── services/          # Business logic
│       │   │   ├── migrations/        # Database migrations
│       │   │   ├── domain/            # Domain layer
│       │   │   ├── application/       # Application layer
│       │   │   └── infrastructure/    # Infrastructure layer
│       │   └── pubspec.yaml
│       ├── story/                     # Story management
│       ├── media_pipeline/            # Media processing pipeline
│       ├── offers/                    # Offer and auction management
│       ├── payments/                  # Payment processing
│       ├── orders/                    # Order and fulfillment
│       ├── notifications/             # Notification services
│       └── analytics/                 # Analytics and reporting
├── lib/
│   └── src/
│       └── generated/                 # Serverpod generated code
└── bin/
    └── main.dart                      # Serverpod entry point
```

**For detailed module patterns and bounded context implementation, see:**
- `package-architecture-requirements.md#serverpod-backend-module-organization` - Complete module specification
- `coding-standards.md#serverpod-backend` - Implementation patterns and best practices

This modular approach enables bounded contexts, independent module development, and clean separation of backend concerns.

### Package Dependencies

**Dependency rules follow the governance framework defined in `package-dependency-governance.md`.**

- **mobile_client** depends on: `core`, `shared`, all feature packages
- **feature packages** depend on: `core`, `shared`
- **core** provides: utilities, data layer (repositories, datasources), base classes
- **shared** provides: Serverpod-generated models, design system, UI components
- **Serverpod Integration**: All packages use generated client code from `shared` package

**For detailed dependency rules and approval processes, see `package-dependency-governance.md`.**


---

## Implementation Strategy

### Phase 1: Foundation Setup
1. **Configure Melos Workspace**: Set up `melos.yaml` with package structure
2. **Create Core Packages**: Implement `core`, `shared_models`, `design_system` packages
3. **Setup Serverpod Backend**: Initialize Serverpod with modules (identity, story, offers, payments, orders)
4. **Configure Mobile Client**: Set up global BLoCs and routing structure

### Phase 2: Reference Implementation
1. **Authentication Package**: Implement complete auth feature as reference
2. **Serverpod Integration**: Connect Flutter auth package with Serverpod identity module
3. **Code Generation**: Set up Serverpod client code generation workflow
4. **Testing Framework**: Establish testing patterns for packages

### Phase 3: Core Features
1. **Timeline Package**: Implement timeline editing functionality
2. **Publishing Package**: Build content creation and publishing workflow
3. **Commerce Package**: Implement offers, auctions, and payments
4. **Design System**: Expand UI components and theming

### Phase 4: Integration & Polish
1. **Cross-package Integration**: Ensure seamless package interaction
2. **Performance Optimization**: Optimize package size and loading
3. **Comprehensive Testing**: Unit, integration, and E2E tests
4. **Documentation**: Complete API documentation and usage guides
4. **Documentation**: Complete technical documentation

---

## Migration Guidelines

### From Current to Target Structure

**Step 1: Create Melos Workspace**
```bash
# Initialize Melos workspace (run from project root)
melos init

# Create package directories
mkdir -p packages/core
mkdir -p packages/shared
mkdir -p packages/features/auth
mkdir -p packages/features/timeline
mkdir -p packages/features/publishing
mkdir -p packages/features/commerce
mkdir -p packages/mobile_client
```

**Step 2: Create Package Skeletons**
```bash
# For each feature package
for feature in auth timeline publishing commerce notifications; do
  mkdir -p packages/features/$feature/lib/{use_cases,presentation/{pages,widgets,bloc}}
  mkdir -p packages/features/$feature/test/{unit,widget}
done

# Core package structure
mkdir -p packages/core/lib/{utils,exceptions,extensions,data/{datasources,repositories}}
mkdir -p packages/core/test/{unit,integration}

# Shared package structure
mkdir -p packages/shared/lib/{models,design_system/{theme,widgets,tokens}}
mkdir -p packages/shared/test/{unit,widget}
```

**Step 3: Setup Package Dependencies**
```yaml
# packages/features/auth/pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  video_window_core:
    path: ../../core
  video_window_shared:
    path: ../../shared
```

**For detailed Melos configuration, see `melos-configuration.md`.**

---

## Development Workflow

### Package Management
- **Root Workspace**: Use Melos for cross-package commands
- **Flutter Workspace**: Use `flutter pub get` for internal dependencies
- **Shared Models**: Regenerate on schema changes

### Testing Strategy
- **Unit Tests**: Each package has its own test suite
- **Integration Tests**: Cross-package functionality testing
- **Widget Tests**: UI component testing in shared package
- **E2E Tests**: Complete flow testing across all packages

### Build & Deployment
- **Development**: Use Melos to run all package tests
- **Staging**: Build individual packages for testing
- **Production**: Build and deploy all packages together

