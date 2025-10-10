# Craft Video Marketplace - Project Structure Implementation Guide

## Current State Analysis

### Existing Project Structure
```
video_window/
├── lib/
│   └── main.dart                # Basic app entry point
├── pubspec.yaml                 # Dependencies configured for Serverpod-first approach
└── docs/                        # Comprehensive architecture documentation
```

**Current Implementation**: Clean Flutter project with Serverpod-first dependency configuration and comprehensive architecture documentation.

**Target Implementation**: Comprehensive marketplace platform with unified package architecture, Serverpod backend, and full e-commerce capabilities.

---

## Target Project Structure

### Unified Package Architecture

**Package structure follows the specifications defined in `package-architecture-requirements.md`.**

```
video_window/                          # Root project directory
├── packages/                          # Flutter packages managed by Melos
│   ├── core/                          # Core utilities, data layer, base classes
│   ├── shared/                        # Shared models, design system, common widgets
│   ├── features/                      # Feature packages
│   │   ├── auth/                      # Authentication feature
│   │   ├── timeline/                  # Timeline editing feature
│   │   ├── publishing/                # Content publishing feature
│   │   ├── commerce/                  # Commerce features
│   │   └── notifications/             # Notification management
│   └── mobile_client/                 # Main Flutter application
├── serverpod/                         # Serverpod backend
│   ├── packages/
│   │   └── modules/                   # Serverpod modules
│   │       ├── identity/              # User authentication and management
│   │       ├── story/                 # Story content management
│   │       ├── offers/                # Offers and auctions
│   │       ├── payments/              # Payment processing
│   │       └── orders/                # Order fulfillment
├── docs/                              # Architecture documentation
├── melos.yaml                         # Workspace configuration
└── README.md                          # Project documentation
```

**Note**: This implements the simplified 3-level structure (core, shared, features) as recommended for better maintainability.

### Main Flutter Application Structure (`packages/mobile_client/`)

The mobile client contains the app shell and global state management:

```
packages/mobile_client/
├── lib/
│   ├── main.dart                      # App initialization
│   ├── app.dart                       # App configuration and providers
│   └── presentation/
│       ├── bloc/                      # Global BLoCs
│       │   ├── app_bloc.dart          # Global app state
│       │   ├── auth_bloc.dart         # Global authentication state
│       │   └── user_session_bloc.dart # User session management
│       └── routes/
│           └── app_router.dart        # GoRouter configuration
├── android/                           # Android platform configuration
├── ios/                               # iOS platform configuration
├── macos/                             # macOS platform configuration
├── linux/                             # Linux platform configuration
├── windows/                           # Windows platform configuration
└── test/                              # Integration and widget tests
```

### Feature Package Structure

**Feature packages follow the simplified structure defined in PSR2 (see `package-architecture-requirements.md#feature-packages`).**

According to **PSR2**: "Each feature package SHALL contain `use_cases/` and `presentation/` layers only. Data layer operations SHALL be centralized in the core package."

**For detailed feature structure examples, see:**
- `package-architecture-requirements.md#feature-packages` - Complete structure specification
- `coding-standards.md#feature-package-structure` - Implementation examples

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

