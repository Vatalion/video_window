# Video Window - Craft Video Marketplace

A Flutter-based mobile marketplace enabling video content creators to monetize through auction-based sales.

**Tech Stack:**
- **Frontend**: Flutter 3.19.6 / Dart 3.5.6
- **Backend**: Serverpod 2.9.x (Modular Monolith)
- **Database**: PostgreSQL 15 + Redis 7.2.4

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: 3.19.6 or later
- **Dart SDK**: 3.5.6 or later
- **Serverpod CLI**: `dart pub global activate serverpod_cli`
- **Docker Desktop**: For running PostgreSQL and Redis
- **Git**: For version control

### Verify Installation

```bash
flutter --version   # Should be >=3.19.6
dart --version      # Should be >=3.5.6
serverpod --version # Should be 2.9.x
docker --version    # For database services
```

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/video_window.git
cd video_window
```

### 2. Start Backend Services

```bash
cd video_window_server
docker compose up --build --detach
```

This starts:
- PostgreSQL (port 5432)
- Redis (port 6379)
- Serverpod development server (port 8080)

### 3. Apply Database Migrations

```bash
cd video_window_server
dart bin/main.dart --apply-migrations
```

### 4. Start Serverpod Backend

```bash
cd video_window_server
dart bin/main.dart
```

The server will be running at `http://localhost:8080`

### 5. Run Flutter App

In a new terminal:

```bash
cd video_window_flutter
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
video_window/                           # Repository root
├── video_window_server/                # Serverpod backend
│   ├── lib/src/endpoints/              # API endpoints by domain
│   │   ├── health_endpoint.dart        # Health check endpoint
│   │   ├── identity/                   # Authentication (Epic 1)
│   │   ├── story/                      # Content management (Epic 4-8)
│   │   ├── offers/                     # Marketplace offers (Epic 9)
│   │   ├── payments/                   # Stripe integration (Epic 12)
│   │   └── orders/                     # Order management (Epic 13)
│   ├── config/                         # Environment configurations
│   ├── migrations/                     # Database migrations
│   └── test/                           # Backend tests
│
├── video_window_client/                # Generated API client (DO NOT EDIT)
│
├── video_window_flutter/               # Flutter mobile app
│   ├── lib/
│   │   ├── app_shell/                  # App bootstrap, routing, theme
│   │   ├── presentation/bloc/          # Global BLoCs
│   │   └── main.dart                   # App entry point
│   ├── packages/
│   │   ├── core/                       # Data layer, repositories, domain
│   │   ├── shared/                     # Design system, common widgets
│   │   └── features/                   # Feature packages
│   │       ├── auth/                   # Authentication feature
│   │       ├── timeline/               # Video editing
│   │       ├── commerce/               # Marketplace
│   │       └── publishing/             # Content publishing
│   └── test/                           # Flutter tests
│
├── docs/                               # Project documentation
│   ├── prd.md                          # Product Requirements
│   ├── architecture/                   # Architecture docs
│   ├── stories/                        # User stories (98 stories)
│   ├── process/                        # Development process
│   ├── testing/                        # Test strategy
│   └── frameworks/                     # Framework-specific docs
│       └── serverpod/                  # Serverpod documentation
│
└── bmad/                               # BMAD development methodology
    ├── core/                           # Core tasks and workflows
    ├── bmm/                            # Method agents (PM, Architect, Dev)
    └── cis/                            # Creative Intelligence System
```

---

## 🧪 Running Tests

### Flutter Tests

```bash
cd video_window_flutter
flutter test                    # Run all tests
flutter test test/smoke_test.dart  # Run specific test
```

### Serverpod Tests

```bash
cd video_window_server
dart test
```

---

## 🔧 Development Workflows

### Code Generation

After making changes to Serverpod protocol files:

```bash
cd video_window_server
serverpod generate
```

This regenerates:
- `video_window_client/` - API client
- `video_window_shared/` - Shared models

**⚠️ NEVER edit generated files manually!**

### Database Migrations

Create a new migration:

```bash
cd video_window_server
serverpod create-migration
```

Apply migrations:

```bash
dart bin/main.dart --apply-migrations
```

### Code Quality

```bash
# Format code
cd video_window_flutter
dart format .

# Analyze code
flutter analyze

# Run tests with coverage
flutter test --coverage
```

---

## 🏗️ Architecture Patterns

### State Management
- **BLoC Pattern** for all state management
- Global BLoCs in `video_window_flutter/lib/presentation/bloc/`
- Feature BLoCs in `packages/features/<feature>/lib/presentation/bloc/`

### Package Organization
- **Core Package**: All data access, repositories, domain models
- **Shared Package**: Design system, reusable widgets
- **Feature Packages**: Business logic + UI (no data layer)

### Data Flow
```
UI Widget → BLoC Event → Use Case → Repository → Serverpod Client → Backend
         ← BLoC State ←  Result  ← Domain Entity ← DTO ←
```

---

## 📚 Documentation

- **[PRD](docs/prd.md)** - Product Requirements Document
- **[Tech Stack](docs/architecture/tech-stack.md)** - Technology choices
- **[Coding Standards](docs/architecture/coding-standards.md)** - Code conventions
- **[BLoC Guide](docs/architecture/bloc-implementation-guide.md)** - State management patterns
- **[Serverpod Docs](docs/frameworks/serverpod/README.md)** - Framework integration
- **[Test Strategy](docs/testing/master-test-strategy.md)** - Testing approach
- **[Process Guide](docs/process/README.md)** - Development process

---

## 🔗 Useful Links

- **Serverpod Documentation**: https://docs.serverpod.dev/
- **Flutter Documentation**: https://docs.flutter.dev/
- **Project Epics**: See `docs/stories/` for 20 epics with 98 user stories

---

## 🆘 Troubleshooting

### Docker containers won't start
- **Check**: Docker Desktop is running
- **Check**: Ports 5432, 6379, 8080 are available
- **Fix**: `docker compose down && docker compose up --build`

### "serverpod: command not found"
- **Fix**: `dart pub global activate serverpod_cli`
- **Add to PATH**: `export PATH="$PATH:$HOME/.pub-cache/bin"`

### Generated code out of sync
- **Symptom**: Compile errors in `video_window_client/`
- **Fix**: `cd video_window_server && serverpod generate`

### Flutter package errors
- **Fix**: `flutter pub get` in each package directory
- **Nuclear option**: `flutter clean && flutter pub get`

---

## 📝 Development Status

- ✅ **Story 01.1**: Bootstrap Repository - COMPLETE
- 🔄 **Epic 1-10, 12**: Technically validated, awaiting implementation
- ⏸️ **Epic 8, 11, 13**: Pending validation
- 🚧 **Epic 14-17**: Pending tech specs

See `docs/process/epic-validation-backlog.md` for complete status.

---

## 🤝 Contributing

1. Check `docs/process/definition-of-ready.md` before starting work
2. Follow coding standards in `docs/architecture/coding-standards.md`
3. Run tests and quality checks before committing
4. See `docs/process/story-approval-workflow.md` for approval process

---

## 📄 License

[Your License Here]

---

**Last Updated**: 2025-10-30  
**Version**: 1.0.0 (Bootstrap Complete)
