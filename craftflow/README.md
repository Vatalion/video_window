# 🚀 CraftFlow Project - Comprehensive Structure Map

**Project Type:** Flutter Monorepo + Serverpod Backend
**Business Domain:** TikTok-style Video Platform for Handmade Creation Process Discovery
**Architecture:** Clean Architecture with SOLID principles & Feature-based Packages
**Current Mode:** ENTERPRISE | Last Updated: 2025-09-15

---

## 🎯 **PROJECT OVERVIEW**

**CraftFlow** is a TikTok-style video platform focused on showcasing the mesmerizing process of creating handmade items. Users can watch satisfying creation videos, discover creators, and optionally purchase items or services.

### **Core Business Functions:**
- 🎥 **Video Discovery:** Infinite scroll feed of creation process videos
- 👤 **Creator Management:** Creator profiles and content management
- 📱 **TikTok Experience:** Pure vertical video, swipe navigation
- 🔐 **Authentication:** User authentication and profile management
- 💬 **Engagement:** Likes, comments, follows, shares
- 🛒 **Optional Commerce:** Subtle purchase features
- 📊 **Analytics:** Video performance and user engagement metrics

---

## 📦 **MONOREPO STRUCTURE**

```
craftflow/                                    # 🏠 Main project root
├── 📱 craftflow_flutter/                     # Flutter frontend application
├── 🖥️  craftflow_server/                      # Serverpod backend server
├── 📡 craftflow_client/                      # Generated API client library
├── 🔧 craftflow_shared/                      # Shared code & utilities
├── 📦 packages/                              # 🎯 Feature-based packages
│   ├── core/                                # 🔧 Core infrastructure packages
│   ├── shared_ui/                           # 🎨 Shared UI components
│   └── features/                            # 🎯 Business feature packages
├── 📋 shared_rules/                          # Development mode management
├── 📊 .tasks/                               # Task management system
├── 📄 docs/                                 # Project documentation
├── 📋 melos.yaml                            # Monorepo management
└── 📝 pubspec.yaml                          # Root dependencies
```

---

## 📱 **CRAFTFLOW_FLUTTER** (Frontend Application)

**Purpose:** Multi-platform Flutter application providing the TikTok-style video experience.

### **Key Features:**
- Cross-platform UI (Mobile, Desktop, Web)
- Clean Architecture with feature-based packages
- Riverpod state management
- Vertical video optimization
- Infinite scroll feed

### **Structure:**
```
craftflow_flutter/
├── lib/
│   ├── app/                                 # 🚀 Application bootstrap
│   │   ├── app.dart                        # Main app widget & routing
│   │   ├── app_module.dart                 # Dependency injection setup
│   │   ├── app_router.dart                 # Auto_route configuration
│   │   └── launch_options.dart             # Environment configuration
│   │
│   └── bootstrap/                          # 📦 Feature package integration
│       ├── features.dart                   # Feature registration
│       ├── themes.dart                     # Theme configuration
│       ├── locales.dart                    # Localization setup
│       └── constants.dart                  # App-wide constants
│
├── android/                               # 🤖 Android platform configuration
├── ios/                                   # 🍎 iOS platform configuration
├── macos/                                 # 🖥️  macOS desktop configuration
├── linux/                                # 🐧 Linux desktop configuration
├── windows/                               # 🪟 Windows desktop configuration
└── web/                                   # 🌐 Web platform configuration
```

---

## 📦 **PACKAGES** (Feature-based Package System)

### **🔧 Core Infrastructure Packages**

```
packages/core/
├── network/                               # 🌐 Network layer
│   ├── lib/src/
│   │   ├── clients/                       # API clients
│   │   ├── interceptors/                  # Request interceptors
│   │   ├── models/                        # Base API models
│   │   └── exceptions/                    # Network exceptions
│   └── test/                              # Network tests
│
├── storage/                               # 💾 Local storage
│   ├── lib/src/
│   │   ├── services/                      # Storage services
│   │   ├── models/                        # Storage models
│   │   └── adapters/                      # Storage adapters
│   └── test/                              # Storage tests
│
├── theme/                                 # 🎨 Theming system
│   ├── lib/src/
│   │   ├── themes/                        # Theme definitions
│   │   ├── colors/                        # Color palettes
│   │   ├── typography/                    # Typography definitions
│   │   └── extensions/                    # Theme extensions
│   └── test/                              # Theme tests
│
├── utils/                                 # 🛠️ Utility functions
│   ├── lib/src/
│   │   ├── extensions/                    # Dart extensions
│   │   ├── helpers/                       # Helper functions
│   │   ├── validators/                    # Validation utilities
│   │   └── constants/                     # App constants
│   └── test/                              # Utility tests
│
└── analytics/                             # 📊 Analytics service
    ├── lib/src/
    │   ├── services/                      # Analytics services
    │   ├── models/                        # Analytics models
    │   └── events/                        # Analytics events
    └── test/                              # Analytics tests
```

### **🎨 Shared UI Package**

```
packages/shared_ui/
├── lib/src/
│   ├── widgets/                           # 🎯 Reusable widgets
│   │   ├── video/                         # Video-related widgets
│   │   │   ├── video_player.dart          # Custom video player
│   │   │   ├── video_controls.dart       # Video controls
│   │   │   └── video_overlay.dart         # Video overlay widgets
│   │   ├── buttons/                       # Button variants
│   │   ├── inputs/                        # Input fields
│   │   ├── loading/                       # Loading indicators
│   │   └── cards/                         # Card widgets
│   │
│   ├── layouts/                           # 📱 Layout templates
│   │   ├── feed_layout.dart              # Feed layout
│   │   ├── profile_layout.dart           # Profile layout
│   │   └── responsive_layout.dart       # Responsive layout
│   │
│   ├── themes/                            # 🎨 Shared themes
│   │   ├── app_theme.dart                 # Main app theme
│   │   ├── dark_theme.dart                # Dark theme
│   │   └── light_theme.dart               # Light theme
│   │
│   └── extensions/                        # 🔧 UI extensions
│       ├── context_extensions.dart       # Context extensions
│       └── widget_extensions.dart        # Widget extensions
│
├── assets/                                # 📁 Shared assets
│   ├── images/                            # Shared images
│   ├── icons/                             # Shared icons
│   └── fonts/                             # Shared fonts
│
└── test/                                  # 🧪 UI tests
    ├── widgets/                           # Widget tests
    └── golden/                            # Golden tests
```

### **🎯 Feature Packages**

```
packages/features/
├── video_feed/                            # 📱 Video feed feature
│   ├── lib/src/
│   │   ├── data/                          # 📊 Data layer
│   │   ├── domain/                        # 🔧 Domain layer
│   │   └── presentation/                  # 🎨 Presentation layer
│   ├── test/                              # 🧪 Feature tests
│   └── example/                           # 📱 Example usage
│
├── video_player/                          # 🎥 Video player feature
│   ├── lib/src/
│   │   ├── data/                          # Video data management
│   │   ├── domain/                        # Video business logic
│   │   └── presentation/                  # Video player UI
│   ├── test/                              # Video player tests
│   └── example/                           # Video player examples
│
├── creator_studio/                        # 🎨 Creator studio feature
│   ├── lib/src/
│   │   ├── data/                          # Creator data management
│   │   ├── domain/                        # Creator business logic
│   │   └── presentation/                  # Creator studio UI
│   ├── test/                              # Creator studio tests
│   └── example/                           # Creator studio examples
│
├── authentication/                        # 🔐 Authentication feature
│   ├── lib/src/
│   │   ├── data/                          # Auth data management
│   │   ├── domain/                        # Auth business logic
│   │   └── presentation/                  # Auth UI (Login/Signup)
│   ├── test/                              # Authentication tests
│   └── example/                           # Auth examples
│
├── user_profile/                          # 👤 User profile feature
│   ├── lib/src/
│   │   ├── data/                          # Profile data management
│   │   ├── domain/                        # Profile business logic
│   │   └── presentation/                  # Profile UI
│   ├── test/                              # Profile tests
│
├── engagement/                            # 💬 Engagement feature
│   ├── lib/src/
│   │   ├── data/                          # Engagement data management
│   │   ├── domain/                        # Engagement business logic
│   │   └── presentation/                  # Engagement UI
│   ├── test/                              # Engagement tests
│   └── example/                           # Engagement examples
│
├── search_discovery/                      # 🔍 Search & discovery feature
│   ├── lib/src/
│   │   ├── data/                          # Search data management
│   │   ├── domain/                        # Search business logic
│   │   └── presentation/                  # Search UI
│   ├── test/                              # Search tests
│   └── example/                           # Search examples
│
└── commerce/                              # 🛒 Commerce feature (optional)
    ├── lib/src/
    │   ├── data/                          # Commerce data management
    │   ├── domain/                        # Commerce business logic
    │   └── presentation/                  # Commerce UI
    ├── test/                              # Commerce tests
    └── example/                           # Commerce examples
```

---

## 🖥️ **CRAFTFLOW_SERVER** (Backend Server)

**Purpose:** Serverpod-based backend providing APIs, real-time features, and video processing.

### **Key Features:**
- Video upload and processing pipeline
- Real-time engagement (likes, comments, follows)
- Feed algorithm and recommendation engine
- Authentication and authorization
- Video streaming and CDN integration
- Creator analytics and insights

### **Structure:**
```
craftflow_server/
├── bin/main.dart                          # 🚀 Server entry point
├── lib/src/                              # 📁 Server implementation
│   ├── endpoints/                         # 🌐 API endpoint definitions
│   │   ├── video/                         # 🎥 Video operations
│   │   ├── user/                          # 👤 User management
│   │   ├── creator/                       # 🎨 Creator operations
│   │   ├── engagement/                    # 💬 Engagement operations
│   │   ├── feed/                          # 📱 Feed operations
│   │   ├── search/                        # 🔍 Search operations
│   │   └── commerce/                      # 🛒 Commerce operations
│   │
│   ├── models/                            # 📊 Data models & entities
│   ├── services/                          # 🔧 Business services
│   └── web/                              # 🌐 Web assets & templates
│
├── config/                               # ⚙️  Server configuration
├── migrations/                           # 🗄️  Database schema changes
└── deploy/                               # 🚀 Deployment configurations
```

---

## 📡 **CRAFTFLOW_CLIENT** (Generated API Client)

**Purpose:** Auto-generated Dart client library for type-safe server communication.

### **Key Features:**
- Auto-generated from server protocol
- Type-safe API calls
- Automatic serialization/deserialization
- Error handling & retry logic

### **Structure:**
```
craftflow_client/
├── lib/
│   ├── craftflow_client.dart              # 📡 Main client export
│   └── src/protocol/                     # 🔗 Generated protocol definitions
│       ├── video.dart                     # Video API models
│       ├── user.dart                      # User API models
│       ├── creator.dart                   # Creator API models
│       ├── engagement.dart                # Engagement API models
│       ├── feed.dart                      # Feed API models
│       └── commerce.dart                  # Commerce API models
└── doc/endpoint.md                       # 📖 API documentation
```

---

## 🔧 **CRAFTFLOW_SHARED** (Shared Utilities)

**Purpose:** Common code, utilities, and models shared across packages.

### **Structure:**
```
craftflow_shared/
└── lib/src/
    ├── models/                           # 📊 Shared data models
    │   ├── common/                       # Common DTOs & value objects
    │   ├── video/                        # Video-related models
    │   ├── user/                         # User-related models
    │   └── enums/                        # Shared enumerations
    └── utils/                            # 🛠️  Utility functions
        ├── extensions/                    # Dart extensions
        ├── constants/                    # Shared constants
        └── helpers/                      # Helper functions
```

---

## 📋 **DEVELOPMENT MODE MANAGEMENT** (shared_rules/)

**Purpose:** Advanced development workflow management with mode switching capabilities.

### **Current Active Mode: ENTERPRISE**

### **🚀 Enterprise Mode Features:**
- Epic task orchestration (10-500+ hours)
- Cross-machine synchronization with git branching
- Priority interrupt system with graceful suspension
- Auto-save daemon (15-minute intervals)
- Real-time monitoring & state preservation

### **Available Tools:**
- `./enterprise_task_management.sh` - Main orchestrator
- Epic management with checkpoint system
- Cross-machine state synchronization
- Priority-based task interruption
- Automated backup & recovery

---

## 🏗️ **CLEAN ARCHITECTURE IMPLEMENTATION**

### **Layer Separation (per feature package):**
- **🎨 Presentation Layer:** UI components, screens, state management (Riverpod)
- **🔧 Domain Layer:** Business logic, use cases, entities, repository interfaces
- **📊 Data Layer:** Repository implementations, API clients, local storage

### **Dependency Flow:**
```
Presentation → Domain ← Data
     ↓           ↑        ↑
  Widgets   Use Cases   APIs
  Controllers Entities   DBs
  Pages     Rules       Cache
```

### **SOLID Principles:**
- **S** - Single Responsibility: Each class has one reason to change
- **O** - Open/Closed: Open for extension, closed for modification
- **L** - Liskov Substitution: Derived classes are substitutable
- **I** - Interface Segregation: No forced unused dependencies
- **D** - Dependency Inversion: Depend on abstractions, not concretions

### **Feature Package Independence:**
- Each feature is a self-contained package
- Minimal dependencies between features
- Shared dependencies through core packages
- Easy to add, remove, or modify features

---

## 📊 **PROJECT STATISTICS**

- **📦 Total Packages:** 12+ (flutter, server, client, shared, core packages, feature packages)
- **🎯 Feature Packages:** 8 feature modules
- **🌐 API Endpoints:** 20+ server endpoints
- **📝 Dart Files:** 0+ total files
- **🚀 Platforms Supported:** 6 (iOS, Android, Web, macOS, Windows, Linux)
- **☁️  Deployment Targets:** AWS, Google Cloud Platform
- **🗄️  Database:** PostgreSQL with versioned migrations

---

## 🛠️ **DEVELOPMENT COMMANDS**

### **Monorepo Management (Melos):**
```bash
melos bootstrap        # Setup all packages & dependencies
melos clean           # Clean all packages
melos test            # Run tests across all packages
melos analyze         # Static analysis for all packages
melos run build_runner # Generate code for all packages
```

### **Mode Management:**
```bash
# Switch development modes
./shared_rules/mode-manager.sh [simplified|enterprise]

# View current system status
./shared_rules/mode-manager.sh status

# Enterprise task management
./shared_rules/enterprise_task_management.sh [command]
```

### **Server Development:**
```bash
cd craftflow_server
serverpod run         # Start development server
serverpod generate    # Generate client protocol
serverpod create-migration  # Create database migration
```

### **Flutter Development:**
```bash
cd craftflow_flutter
flutter run           # Run on current platform
flutter build [platform]  # Build for specific platform
flutter test          # Run unit & widget tests
```

### **Feature Package Development:**
```bash
# Add new feature package
melos create feature:new_feature

# Run tests for specific feature
melos test --scope="*feature_name*"

# Build specific feature
melos build --scope="*feature_name*"
```

---

## 🎯 **FEATURE PACKAGE TEMPLATES**

### **Standard Feature Package Structure:**
```
packages/features/feature_name/
├── pubspec.yaml                          # Package dependencies
├── lib/
│   └── src/
│       ├── data/                        # Data layer
│       ├── domain/                      # Domain layer
│       ├── presentation/                # Presentation layer
│       └── feature_name.dart           # Main export
├── test/                                # Test files
└── example/                             # Example usage
```

### **Feature Package Dependencies:**
```yaml
dependencies:
  core_network: ^1.0.0
  core_storage: ^1.0.0
  core_theme: ^1.0.0
  shared_ui: ^1.0.0
  riverpod: ^2.0.0
  freezed: ^2.0.0
  json_annotation: ^4.0.0
```

---

## 🎯 **NEXT STEPS FOR AI AGENTS**

When working with this project, AI agents should:

1. **🔍 Understand the Business Domain:** TikTok-style video platform for creation process discovery
2. **📐 Follow Clean Architecture:** Respect layer boundaries and SOLID principles
3. **🎯 Work with Features:** Each feature is a self-contained package
4. **🔄 Use Mode Management:** Leverage simplified/enterprise modes based on task scope
5. **🧪 Test Thoroughly:** Unit tests for domain, widget tests for UI, integration tests for flows
6. **📦 Package Independence:** Each feature package should be independently testable and deployable
7. **🌐 Serverpod Integration:** Leverage auto-generated client code for type-safe API communication

---

## 🚀 **DEVELOPMENT ROADMAP**

### **Phase 1: Core Infrastructure (4-6 weeks)**
- Set up monorepo structure
- Implement core packages (network, storage, theme)
- Create shared UI package
- Set up Serverpod backend
- Implement authentication feature

### **Phase 2: Video Features (6-8 weeks)**
- Video upload and processing
- Video player feature
- Video feed feature
- Basic engagement features

### **Phase 3: Creator Features (4-6 weeks)**
- Creator studio feature
- User profile feature
- Advanced engagement features
- Search and discovery

### **Phase 4: Advanced Features (4-6 weeks)**
- Feed algorithm and recommendations
- Commerce features (optional)
- Analytics and insights
- Performance optimization

---

*🤖 Auto-generated by mode-manager.sh - 2025-09-15*
*📋 Current development mode: ENTERPRISE | Switch modes: `./mode-manager.sh [simplified|enterprise`*