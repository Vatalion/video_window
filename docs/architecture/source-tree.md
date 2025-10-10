# Source Tree Structure

```text
video_window/                                    # Project root
├── packages/
│   ├── mobile_client/                         # Main Flutter application
│   │   ├── lib/
│   │   │   ├── main.dart                      # App entry point
│   │   │   ├── app.dart                       # App configuration
│   │   │   └── presentation/                 # Global presentation layer
│   │   │       ├── bloc/                     # Global BLoCs (app, auth)
│   │   │       └── routes/                   # App routing
│   │   └── pubspec.yaml                       # Flutter app dependencies
│   ├── core/                                 # Core utilities and base classes
│   │   ├── lib/
│   │   │   ├── utils/                        # Utility functions
│   │   │   ├── exceptions/                   # Custom exceptions
│   │   │   ├── extensions/                   # Dart extensions
│   │   │   └── core.dart                     # Public API export
│   │   └── pubspec.yaml                       # Core package dependencies
│   ├── shared_models/                        # Shared domain models
│   │   ├── lib/
│   │   │   ├── models/                       # Domain entities
│   │   │   ├── enums/                        # Shared enumerations
│   │   │   ├── constants/                    # Domain constants
│   │   │   └── shared_models.dart            # Public API export
│   │   └── pubspec.yaml                       # Shared models dependencies
│   ├── design_system/                        # UI components and theming
│   │   ├── lib/
│   │   │   ├── theme/                        # Design tokens and themes
│   │   │   ├── widgets/                      # Reusable UI components
│   │   │   ├── tokens/                       # Design tokens (colors, typography)
│   │   │   └── design_system.dart            # Public API export
│   │   └── pubspec.yaml                       # Design system dependencies
│   └── features/                             # Feature packages
│       ├── auth/                             # Authentication feature
│       │   ├── lib/
│       │   │   ├── domain/                   # Business logic and entities
│       │   │   │   ├── entities/             # Domain entities
│       │   │   │   ├── repositories/         # Repository interfaces
│       │   │   │   └── usecases/             # Business use cases
│       │   │   ├── data/                     # Data layer implementation
│       │   │   │   ├── datasources/          # Data sources
│       │   │   │   ├── models/               # Data transfer objects
│       │   │   │   └── repositories/         # Repository implementations
│       │   │   └── presentation/             # UI layer
│       │   │       ├── pages/                # Screen components
│       │   │       ├── widgets/              # Feature-specific widgets
│       │   │       ├── bloc/                 # Feature-specific BLoCs
│       │   │       └── routes/               # Feature routes
│       │   └── pubspec.yaml                   # Auth feature dependencies
│       ├── timeline/                         # Timeline editing feature
│       ├── publishing/                       # Content publishing feature
│       ├── commerce/                         # Commerce and marketplace features
│       ├── shipping/                         # Shipping and fulfillment features
│       └── notifications/                    # Notification management features
├── serverpod/                                 # Serverpod backend
│   ├── config/
│   │   ├── development.yaml                 # Development configuration
│   │   └── production.yaml                  # Production configuration
│   ├── lib/
│   │   └── src/
│   │       ├── generated/                    # Generated code
│   │       ├── endpoints/                    # API endpoints
│   │       ├── models/                       # Database models
│   │       └── web/                          # Web endpoints (if any)
│   └── packages/
│       └── modules/                         # Serverpod modules
│           ├── identity/                     # Identity and access management
│           │   ├── lib/
│           │   │   ├── endpoints/             # Auth endpoints
│           │   │   ├── models/                # User models
│           │   │   └── tables/                # Database tables
│           ├── story/                        # Story management
│           ├── media_pipeline/               # Media processing
│           ├── offers/                       # Offers and auctions
│           ├── payments/                     # Payment processing
│           ├── orders/                       # Order management
│           └── notifications/                # Notification services
├── docs/                                      # Documentation
│   ├── architecture/                        # Architecture documentation
│   │   ├── offers-auction-orders-model.md
│   │   ├── story-component-mapping.md
│   │   ├── front-end-architecture.md
│   │   ├── coding-standards.md
│   │   ├── source-tree.md
│   │   ├── project-structure-implementation.md
│   │   ├── package-architecture-requirements.md
│   │   ├── package-dependency-governance.md
│   │   ├── melos-configuration.md
│   │   ├── serverpod-integration-guide.md
│   │   ├── decision-framework.md
│   │   └── CRITICAL-ISSUES-ANALYSIS.md
│   ├── prd.md                                # Product requirements
│   └── qa/                                   # Quality assurance
├── tools/                                     # Development tools and scripts
├── melos.yaml                                 # Melos workspace configuration
├── README.md                                  # Project README
└── .gitignore                                # Git ignore file
```

## Package Architecture Overview

This repository follows a **unified package structure** with clear separation of concerns:

### Core Principles

1. **Monorepo with Melos**: All packages managed through Melos workspace
2. **Feature-based organization**: Each major feature is its own package
3. **Shared packages**: Core utilities, models, and design system are shared
4. **Serverpod integration**: Backend modules mirror Flutter feature packages
5. **Clean architecture**: Each feature follows domain/data/presentation layers

### Package Responsibilities

- **mobile_client**: Main Flutter app, global state, navigation
- **core**: Shared utilities, exceptions, extensions
- **shared_models**: Domain entities shared across client/server
- **design_system**: UI components, theming, design tokens
- **features/**: Feature-specific business logic and UI
- **serverpod/modules/**: Backend business logic and data persistence

### Development Workflow

1. **Setup**: `melos bootstrap` to initialize workspace
2. **Development**: Work within specific packages
3. **Testing**: `melos run test` for all packages
4. **Building**: `melos run build` for release builds
5. **Code Generation**: `melos run generate` for generated code

This structure enables parallel development, clear boundaries, and scalable architecture as the project grows.