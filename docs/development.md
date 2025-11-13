# Development Guide

## Getting Started

### Prerequisites

Ensure you have the following tools installed:

- Flutter SDK ≥3.19.6 (tested with 3.35.4)
- Dart SDK ≥3.5.6 (tested with 3.9.2)
- Serverpod CLI: `dart pub global activate serverpod_cli`
- Melos: `dart pub global activate melos`
- Docker Desktop (for PostgreSQL and Redis)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/video_window.git
   cd video_window
   ```

2. **Bootstrap the workspace:**
   ```bash
   # From project root
   melos bootstrap
   ```

3. **Start backend services:**
   ```bash
   cd video_window_server
   docker compose up -d
   ```

4. **Run database migrations:**
   ```bash
   cd video_window_server
   dart bin/main.dart --apply-migrations
   ```

## Development Workflow

### Running the Application

**Backend (Serverpod):**
```bash
cd video_window_server
dart bin/main.dart
```

**Flutter App:**
```bash
cd video_window_flutter
flutter run
```

### Code Generation

**Serverpod Code Generation:**
After modifying any protocol files in `video_window_server/lib/src/protocol/`:
```bash
cd video_window_server
serverpod generate
```

This regenerates:
- `video_window_client/` - API client (DO NOT EDIT)
- `video_window_shared/` - Shared types (DO NOT EDIT)

**Flutter Code Generation (via Melos):**
For build_runner code generation across all packages:
```bash
# From project root
melos run generate
```

This runs build_runner on all packages that need it.

### Testing

**Run all tests (recommended):**
```bash
# From project root
melos run test
```

**Run specific test types:**
```bash
# Unit tests only
melos run test:unit

# Widget tests only
melos run test:widget

# Integration tests only
melos run test:integration
```

**Run tests in specific package:**
```bash
# Flutter app tests
cd video_window_flutter && flutter test

# Core package tests
cd video_window_flutter/packages/core && flutter test

# Serverpod tests (requires Docker for integration tests)
cd video_window_server && dart test

# Health endpoint test only (no Docker required)
cd video_window_server && dart test test/health_endpoint_test.dart
```

### Code Quality

**Format all code (via Melos):**
```bash
# From project root
melos run format
```

**Analyze all code (via Melos):**
```bash
# From project root
melos run analyze
```

**Individual package formatting:**
```bash
# If you need to format a specific package
cd video_window_flutter && dart format lib/ test/
cd video_window_server && dart format lib/ test/
```

**Analyze code:**
```bash
# Flutter
cd video_window_flutter
flutter analyze --fatal-infos

# Serverpod
cd video_window_server
dart analyze --fatal-infos
```

## Project Structure

### Workspace Layout

```
video_window/
├── video_window_server/          # Serverpod backend
│   ├── lib/src/endpoints/         # API endpoints
│   │   ├── health_endpoint.dart   # Health check
│   │   ├── identity/              # Authentication (Epic 1)
│   │   ├── story/                 # Content (Epic 4-8)
│   │   ├── offers/                # Marketplace (Epic 9)
│   │   ├── payments/              # Payments (Epic 12)
│   │   └── orders/                # Orders (Epic 13)
│   ├── config/                    # Environment config
│   ├── migrations/                # Database migrations
│   └── test/                      # Backend tests
│
├── video_window_client/           # Generated API client (READ-ONLY)
├── video_window_shared/           # Generated shared types (READ-ONLY)
│
└── video_window_flutter/          # Flutter app
    ├── lib/
    │   ├── main.dart              # App entry point
    │   ├── app_shell/             # App configuration
    │   │   ├── app_config.dart    # Dependencies setup
    │   │   ├── router.dart        # Navigation (GoRouter)
    │   │   └── theme.dart         # Material theme
    │   └── presentation/
    │       └── bloc/              # Global BLoCs
    ├── packages/
    │   ├── core/                  # Data layer, repositories
    │   ├── shared/                # Design system, widgets
    │   └── features/              # Feature packages
    │       ├── auth/              # Authentication
    │       ├── timeline/          # Video editing
    │       ├── commerce/          # Marketplace
    │       └── publishing/        # Publishing
    └── test/                      # Flutter tests
```

### Feature Package Structure

Each feature package follows this pattern:

```
packages/features/<feature>/
├── lib/
│   ├── use_cases/              # Business logic
│   │   └── <use_case>.dart
│   └── presentation/           # UI layer
│       ├── bloc/               # Feature BLoCs
│       ├── pages/              # Screen widgets
│       └── widgets/            # Reusable widgets
├── test/                       # Tests mirror lib/
└── pubspec.yaml                # Dependencies
```

**Important:** Feature packages should NOT contain data layer code (repositories, data sources). All data access goes through `packages/core/`.

## Common Tasks

### Adding a New Endpoint

1. Create endpoint file in `video_window_server/lib/src/endpoints/`
2. Implement endpoint class extending `Endpoint`
3. Run `serverpod generate` to update client
4. Use generated client in Flutter app

### Adding a New Feature Package

1. Create directory in `video_window_flutter/packages/features/<feature>`
2. Add `pubspec.yaml` with dependencies on `core` and `shared`
3. Create `lib/use_cases/` and `lib/presentation/` directories
4. Add the new package to the `workspace` section in the root `pubspec.yaml` file.

### Database Migrations

1. Modify protocol files in `video_window_server/lib/src/protocol/`
2. Run `serverpod generate`
3. Run `serverpod create-migration`
4. Apply with `dart bin/main.dart --apply-migrations`

## Troubleshooting

### "Client out of sync" errors

Run Serverpod code generation:
```bash
cd video_window_server
serverpod generate
```

### Port conflicts

Serverpod default ports:
- 8080: API server
- 8081: Insights (monitoring)
- 5432: PostgreSQL
- 6379: Redis

Change in `video_window_server/config/development.yaml`

### Hot reload not working

Restart the app after changes to:
- `main.dart`
- App shell configuration
- Global BLoC initialization

## Additional Resources

- [Serverpod Documentation](https://docs.serverpod.dev/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Project PRD](prd.md)
- [Architecture Docs](architecture/)
- [Coding Standards](architecture/coding-standards.md)
