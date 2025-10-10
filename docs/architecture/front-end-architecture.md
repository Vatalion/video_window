# Front-End Architecture Outline — Craft Video Marketplace

Status: Draft v0.1 (2025-09-30) — Complements `docs/architecture.md` with Flutter-specific guidance.

## Purpose
Provide developers and designers with a shared blueprint for how the Flutter client should be structured, themed, and integrated with backend services and analytics.

## Video Marketplace Unified Package Structure

The video marketplace follows a **unified package architecture** with Melos workspace management:

### Project Structure
```
video_window/                      # Root project directory
├── packages/                     # Flutter packages
│   ├── mobile_client/            # Main Flutter app
│   ├── core/                     # Core utilities
│   ├── shared_models/            # Shared domain models
│   ├── design_system/            # UI components and theming
│   └── features/                 # Feature packages
│       ├── auth/                 # Authentication feature
│       ├── timeline/             # Timeline editing feature
│       ├── publishing/           # Content publishing feature
│       └── commerce/             # Commerce features
├── serverpod/                    # Serverpod backend
├── docs/                         # Documentation
├── melos.yaml                    # Workspace configuration
└── README.md                     # Project documentation
```

### Main Flutter Application (`packages/mobile_client/`)
The mobile client contains the app shell and global state management:

```
packages/mobile_client/
├── lib/
│   ├── main.dart                 # App initialization
│   ├── app.dart                  # App configuration
│   └── presentation/
│       ├── bloc/                 # Global BLoCs
│       │   ├── app_bloc.dart     # Global app state
│       │   ├── auth_bloc.dart    # Global auth state
│       │   └── user_session_bloc.dart # User session management
│       └── routes/               # App routing
│           └── app_router.dart   # GoRouter configuration
└── pubspec.yaml
```

### Feature Package Structure
Each feature follows clean architecture with BLoC state management:

```
packages/features/auth/
├── lib/
│   ├── domain/                   # Business logic
│   │   ├── entities/             # Domain entities
│   │   ├── repositories/         # Repository interfaces
│   │   └── usecases/             # Business use cases
│   ├── data/                     # Data layer
│   │   ├── datasources/          # Data sources
│   │   ├── models/               # Data transfer objects
│   │   └── repositories/         # Repository implementations
│   └── presentation/             # UI layer
│       ├── bloc/                 # Feature-specific BLoCs
│       │   ├── login_bloc.dart   # Login state management
│       │   ├── register_bloc.dart # Registration state
│       │   └── profile_bloc.dart # Profile management
│       ├── pages/                # Screen components
│       └── widgets/              # Feature widgets
└── pubspec.yaml
```

## State Management Architecture

### Centralized BLoC Architecture
- **Global BLoCs** in `packages/mobile_client/lib/presentation/bloc/`:
  - `app_bloc.dart` - Global app state (theme, connectivity, etc.)
  - `auth_bloc.dart` - Global authentication state and user session
  - `user_session_bloc.dart` - User session management and token refresh

- **Feature-specific BLoCs** in `packages/features/<feature>/lib/presentation/bloc/`:
  - `auth/` package: `login_bloc.dart`, `register_bloc.dart`, `profile_bloc.dart`
  - `commerce/` package: `offer_bloc.dart`, `auction_bloc.dart`, `checkout_bloc.dart`
  - `timeline/` package: `timeline_editor_bloc.dart`, `media_preview_bloc.dart`
  - `publishing/` package: `publishing_workflow_bloc.dart`, `content_processing_bloc.dart`

### BLoC Usage Guidelines
- Use BLoC for complex state management (auctions, payments, auth flows)
- Use StatefulWidget for simple UI state (forms, loading states, UI animations)
- Avoid `GetIt` or mutable singletons; BLoC provides testability and clear state transitions
- Derived analytics or UI-specific state should wrap domain models instead of mutating them
- Global BLoCs are provided at the app level and accessible throughout the app
- Feature BLoCs are scoped to their respective feature routes/pages

## Navigation Architecture
- **Global router** in `packages/mobile_client/lib/presentation/routes/app_router.dart` using `GoRouter`
- **Route definitions** centralized in the mobile client package for type safety
- **Deep link handling** via dedicated deep link handler mapping URLs to features
- **Feature route integration**: Feature packages export route constants but mobile client handles routing
- **Route guards**: Maker-only areas protected via auth role checks in route middleware
- **Navigation flow**: Mobile client BLoCs handle navigation state and route changes

## Networking & Data Layer Architecture
- **Serverpod integration**: Generated clients in `packages/shared_models/` package provide type-safe API access
- **Data flow**: Mobile client → Feature BLoCs → Use Cases → Repositories → Serverpod Client
- **Shared models**: All packages import `package:video_window_shared_models/video_window_shared_models.dart`
- **Network abstraction**: UI never calls Serverpod client directly; all calls go through use cases
- **Optimistic updates**: Use StatefulWidget for simple UI state, BLoC for complex flows with rollback capability

### Package Dependencies
- **mobile_client** depends on: `core`, `shared_models`, `design_system`, all feature packages
- **feature packages** depend on: `core`, `shared_models`, `design_system`
- **core** provides: utilities, exceptions, extensions, shared domain logic
- **shared_models** provides: Serverpod-generated models and client code
- **design_system** provides: UI components, themes, design tokens

### Data Flow & Transformation Patterns

#### Layer Data Transformations
Follow the comprehensive data flow patterns documented in `data-flow-mapping.md`. Key principles:

**UI → BLoC Transformations:**
- Convert user interactions to typed BLoC events with validation
- Transform BLoC states to UI components with loading/error handling
- Include proper error states with retry mechanisms

**BLoC → Use Case Transformations:**
- Map BLoC events to use case parameters with business validation
- Convert use case results (Either/Result) to BLoC states
- Handle domain failures appropriately in state transitions

**Use Case → Repository Transformations:**
- Transform domain entities to repository interface parameters
- Convert repository results to domain entities with proper mapping
- Handle technical exceptions and map to domain failures

**Repository → Data Source Transformations:**
- Convert domain entities to DTOs for external API calls
- Transform API responses to internal data models
- Handle network exceptions and server errors appropriately

#### Implementation Examples

**UI Event to BLoC Event:**
```dart
// User input validation and transformation
onChanged: (value) {
  if (isValidEmail(value)) {
    context.read<AuthBloc>().add(SignInEmailChanged(email: value.trim()));
  }
},
```

**BLoC to Use Case:**
```dart
on<SignInSubmitted>((event, emit) async {
  final result = await _signInUseCase.call(
    SignInParams(
      email: EmailAddress(event.email), // String → Value Object
      password: Password(event.password),
    ),
  );
  // Handle result transformation
});
```

**Repository Data Mapping:**
```dart
// Domain Entity ↔ DTO transformation (using shared models)
import 'package:video_window_shared_models/video_window_shared_models.dart';

Future<Either<AuthFailure, User>> signIn(SignInParams params) async {
  try {
    final userModel = await _dataSource.signIn(
      SignInRequestModel(email: params.email.value), // Domain → DTO
    );
    return Right(User.fromSharedModel(userModel)); // Shared Model → Domain
  } catch (e) {
    return Left(mapExceptionToFailure(e));
  }
}
```

#### Error Handling Across Layers
- Transform technical exceptions to domain failures at repository boundaries
- Convert domain failures to user-friendly messages in BLoC layer
- Display appropriate error states in UI with retry options
- Log detailed errors for debugging while showing simplified messages to users

#### Testing Data Transformations
- Unit test each transformation point with edge cases
- Integration tests for complete data flows (UI → Repository)
- Mock external dependencies for isolated testing
- Golden tests for UI state transformations

## Theming & Design System Architecture
- **Design system package** (`packages/design_system/`) provides centralized theming and components
- **Design tokens** include colors, typography, spacing, radii, and shadows with semantic naming
- **Package imports**: Feature modules import `package:video_window_design_system/video_window_design_system.dart`
- **No hard-coded values**: All design values come from the design system package
- **Dark mode support**: Design system includes dark mode tokens for future implementation
- **Design updates**: Changes to UX mockups are reflected in design system package with story references

## Accessibility
- Follow WCAG 2.1 AA targets: 44x44 tap minimum, focus order defined, semantics via `Semantics` widgets, captions/respect reduced motion.
- Provide `AccessibilityPreview` mode in developer builds to visualize high-contrast and text-scaling scenarios.
- Offer countdown timers must include screen-reader friendly labels (e.g., “Auction ends in 15 minutes”).

## Analytics Instrumentation
- `analytics/analytics_service.dart` wraps event dispatch, ensuring event names align with `docs/analytics/mvp-analytics-events.md`.
- Feature modules call analytics service via injected providers; avoid duplicating event names.
- Include screen view tracking (feed_view, story_view) on `initState` with debouncing to avoid churn.

## Error Handling
- Use shared `ErrorView` components for network/business errors with retry callbacks.
- Convert domain errors into localized messages via `l10n` files (even if English-only for MVP).
- Record severe errors via analytics + optional Sentry integration (toggle via feature flag).

## Testing Strategy (Client)
- Unit test BLoCs with bloc_test package and widgets with flutter_test.
- Widget tests for critical screens (feed, story, offer modal, checkout, maker dashboard) verifying layout and accessibility semantics.
- Golden tests once hi-fi designs finalized; store baselines under `test/goldens/` with story references.

## Collaboration Notes
- Designers provide component specs (padding, states, responsive behavior) in Figma; developers reflect updates in `lib/shared/` within 24h of approval.
- Any discrepancy between frontend and backend schema resolved by updating `shared_models/` first, then regenerating code.
- Keep `docs/wireframes` as living documentation—append hi-fi exports and link to relevant stories.

## Development Workflow
- **Workspace management**: Use `melos bootstrap` for initial setup, `melos run deps` for dependencies
- **Local development**: Use `flutter run` in specific package directories for targeted development
- **Testing**: Run `melos run test` for all packages, `flutter test` for individual packages
- **Building**: Use `melos run build` for release builds across all packages
- **Code generation**: Use `melos run generate` for Serverpod client code and JSON serialization
- **Code organization**: Follow unified package structure with clean architecture boundaries

## Implementation Priorities
1. **Foundation packages**: Create `core`, `shared_models`, `design_system` packages first
2. **Mobile client**: Set up global BLoCs and routing structure
3. **Auth feature**: Implement authentication package as reference implementation
4. **Core features**: Implement timeline, publishing, and commerce packages
5. **Integration testing**: Ensure all packages work together seamlessly

