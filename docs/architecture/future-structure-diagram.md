# Craft Video Marketplace - Current Architecture Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    📱 MOBILE CLIENT APPLICATION                             │
│                 packages/mobile_client/ (Flutter App)                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Navigation    │  │   Material      │  │   Platform      │             │
│  │   (Go Router)   │  │   Design System │  │   Integrations  │             │
│  │                 │  │                 │  │                 │             │
│  │ • Route         │  │ • Theme System  │  │ • Permissions   │             │
│  │   Management    │  │ • Custom        │  │ • Storage       │             │
│  │ • Deep Linking  │  │   Components    │  │ • Connectivity  │             │
│  │ • Guard         │  │ • Typography    │  │ • Device Info   │             │
│  │   Routes        │  │ • Color Palette │  │ • Package Info  │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       🎯 FEATURE PACKAGES LAYER                             │
│                packages/features/ (Modular Features)                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Auth Feature  │  │   Timeline      │  │   Publishing    │             │
│  │                 │  │   Feature       │  │   Feature       │             │
│  │ • Login/Signup  │  │ • Feed Display  │  │ • Content       │             │
│  │ • Profile       │  │ • Video/Audio   │  │   Creation      │             │
│  │ • Session Mgmt  │  │   Streaming     │  │ • Media Upload  │             │
│  │ • Social Sign-  │  │ • Interactions  │  │ • Draft System  │             │
│  │   In (Google/   │  │ • Comments      │  │ • Publishing    │             │
│  │   Apple)        │  │ • Likes/Shares  │  │   Workflow      │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Marketplace   │  │   Chat Feature  │  │   Notifications │             │
│  │   Feature       │  │                 │  │   Feature       │             │
│  │                 │  │ • Real-time     │  │ • Push          │             │
│  │ • Product       │  │   Messaging     │  │   Notifications │             │
│  │   Listings      │  │ • Media Sharing │  │ • In-app        │             │
│  │ • Shopping Cart │  │ • Group Chats   │  │   Alerts        │             │
│  │ • Payment       │  │ • Message       │  │ • Email         │             │
│  │   Integration   │  │   History       │  │   Digests       │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
│  ┌─────────────────┐                                                         │
│  │   Profile       │                                                         │
│  │   Feature       │                                                         │
│  │ • User Settings │                                                         │
│  │ • Preferences   │                                                         │
│  │ • Privacy       │                                                         │
│  │ • Account Mgmt  │                                                         │
│  └─────────────────┘                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          🧰 CORE FOUNDATION                                 │
│                      packages/core/ (Foundation)                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Base          │  │   Repository    │  │   Network       │             │
│  │   BLoC          │  │   Pattern       │  │   Client        │             │
│  │                 │  │                 │  │                 │             │
│  │ • State Mgmt    │  │ • HTTP Abstr.   │  │ • Dio Client    │             │
│  │ • Error         │  │ • CRUD Ops      │  │ • Interceptors  │             │
│  │   Handling      │  │ • Cache Layer   │  │ • Retry Logic   │             │
│  │ • Common Events │  │ • JSON          │  │ • Timeouts      │             │
│  │ • Safe Ops      │  │   Serialization │  │ • Logging       │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Secure        │  │   Auth Service  │  │   Storage       │             │
│  │   Storage       │  │                 │  │   Service       │             │
│  │                 │  │ • Email/Pass    │  │                 │             │
│  │ • Type-safe     │  │ • Social Sign-  │  │ • File Storage  │             │
│  │ • Key Mgmt      │  │   In            │  │ • Image Cache   │             │
│  │ • JSON Support  │  │ • Token Refresh │  │ • Local DB      │             │
│  │ • Encryption    │  │ • Profile Mgmt  │  │ • Backup/Restore│             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     🎨 SHARED RESOURCES LAYER                               │
│              packages/design_system/ + packages/shared_models/               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Design System │  │   Shared Models │  │   Common        │             │
│  │                 │  │                 │  │   Utilities     │             │
│  │ • Component     │  │ • User Models   │  │                 │             │
│  │   Library      │  │ • Content Models │  │ • Constants     │             │
│  │ • Theme         │  │ • Marketplace   │  │ • Extensions    │             │
│  │   System       │  │   Models        │  │ • Helpers       │             │
│  │ • Typography    │  │ • Chat Models   │  │ • Validators    │             │
│  │ • Colors        │  │ • Notification  │  │ • Formatters    │             │
│  │ • Spacing       │  │   Models        │  │ • Converters    │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      🖥️ SERVERPOD BACKEND                                   │
│                        serverpod/ (Dart Backend)                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Auth Endpoint │  │   User Endpoint │  │   Post Endpoint │             │
│  │                 │  │                 │  │                 │             │
│  │ • Login/Logout  │  │ • Profile Mgmt  │  │ • Content CRUD  │             │
│  │ • Token Mgmt    │  │ • User Search   │  │ • Media Upload  │             │
│  │ • Social Auth   │  │ • Settings      │  │ • Draft Save    │             │
│  │ • Session       │  │   Management    │  │ • Publishing    │             │
│  │   Management    │  │ • Privacy       │  │   Workflow      │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Database      │  │   File Storage  │  │   Real-time     │             │
│  │   Migrations    │  │   System        │  │   Features      │             │
│  │                 │  │                 │  │                 │             │
│  │ • User Tables   │  │ • Media Storage │  │ • WebSocket     │             │
│  │ • Content       │  │ • Image         │  │   Support       │             │
│  │   Tables        │  │   Processing    │  │ • Live Chat     │             │
│  │ • Marketplace   │  │ • CDN Integration│  │ • Notifications │             │
│  │   Tables        │  │ • Backup System │  │ • Status Updates│             │
│  │ • Relations     │  │ • Security      │  │ • Presence      │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        🔧 DEVELOPMENT INFRASTRUCTURE                        │
│                        (Melos Workspace + Tools)                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Melos         │  │   Quality Gates │  │   Git Hooks     │             │
│  │   Workspace     │  │                 │  │                 │             │
│  │                 │  │ • Static        │  │ • Pre-commit    │             │
│  │ • Package Mgmt  │  │   Analysis      │  │ • Pre-push      │             │
│  │ • 40+ Scripts   │  │ • Code Format   │  │ • Security      │             │
│  │ • Build Scripts │  │ • Test Coverage │  │   Checks        │             │
│  │ • CI/CD Ready   │  │ • Dependency    │  │ • File Size     │             │
│  │ • Multi-Pkg     │  │   Audit         │  │   Validation    │             │
│  │   Commands      │  │ • Performance   │  │ • Build Verify  │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Development   │  │   IDE Config    │  │   Testing       │             │
│  │   Scripts       │  │                 │  │   Framework     │             │
│  │                 │  │ • VS Code       │  │                 │             │
│  │ • setup_dev.sh  │  │ • IntelliJ      │  │ • Unit Tests    │             │
│  │ • clean.sh      │  │ • Workspace     │  │ • Widget Tests  │             │
│  │ • Environment   │  │   Settings      │  │ • Integration   │             │
│  │   Setup         │  │ • Launch Configs│  │ • Golden Tests  │             │
│  │ • Dependency    │  │ • Debug Configs │  │ • Performance   │             │
│  │   Mgmt          │  │ • Task Runner   │  │ • Coverage      │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow & Communication Patterns

```
User → Mobile Client → Feature BLoCs → Core Services → Repository Pattern → Serverpod Endpoints → Database
  ↑                                                                                      ↓
  └────────────────────── State Updates (BLoC) ← HTTP Responses ← Backend Services ──────┘
```

## 📦 Package Dependencies (Current Structure)

```
packages/
├── mobile_client/              # Main Flutter app (depends on all below)
├── core/                      # Base BLoC, Repository, Network, Auth, Storage
├── shared_models/             # Data models used across all packages
├── design_system/             # UI components, themes, typography
└── features/
    ├── auth/                  # Authentication & user management
    ├── timeline/              # Feed, content streaming, interactions
    ├── publishing/            # Content creation & publishing workflow
    ├── marketplace/           # E-commerce functionality
    ├── chat/                  # Real-time messaging
    ├── profile/               # User settings & preferences
    └── notifications/         # Push notifications & alerts

serverpod/                      # Dart backend with endpoints & database
```

## 🎯 Current Architectural Principles

- **Feature-First Architecture**: Modular feature packages with clear boundaries
- **BLoC State Management**: Reactive state with predictable patterns
- **Repository Pattern**: Clean data access with HTTP abstraction
- **Shared Foundation**: Common models, design system, and core utilities
- **Type Safety**: Strong typing throughout with comprehensive models
- **Testability**: Multi-level testing with automated quality gates
- **Developer Experience**: Melos workspace with 40+ automation scripts
- **Security**: Secure storage, input validation, dependency auditing

This is the **actual architecture** we've built - a comprehensive Craft Video Marketplace with feature-driven development, robust state management, and production-ready infrastructure.