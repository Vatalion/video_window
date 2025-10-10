# Craft Video Marketplace Coding Standards

Status: v0.2 — Comprehensive development standards enforced alongside architecture and PRD guardrails.

## General Principles
- Favor readability and explicitness over cleverness; document non-obvious decisions with inline comments referencing stories.
- Write deterministic, side-effect-aware code; avoid global state and hidden singletons.
- All new files must declare null-safety (`// @dart=3.8` when needed).
- **Performance First**: Every commit must consider mobile performance implications (memory, CPU, battery).
- **Security by Default**: All user inputs must be validated and sanitized; never trust client-side data.
- **Accessibility Required**: All UI components must meet WCAG 2.1 AA standards from day one.

## Flutter Client
- **Project Structure:** Unified package architecture using Melos workspace:
  - `packages/mobile_client/` - Main Flutter app with global BLoCs
  - `packages/features/<name>/` - Feature packages with clean architecture
  - `packages/core/` - Shared utilities and extensions
  - `packages/shared_models/` - Serverpod-generated models
  - `packages/design_system/` - UI components and theming
- **State Management:** Centralized BLoC architecture. Global BLoCs in mobile_client, feature-specific BLoCs in feature packages. Widgets receive dependencies via constructors, not `GetIt` globals.
- **UI Composition:** Small, testable widgets (<200 lines). Use design system tokens. Respect accessibility: 44x44 tap targets, contrast ≥4.5:1, reduced motion support.
- **Navigation:** Centralized GoRouter in `packages/mobile_client/lib/presentation/routes/`. No ad-hoc navigation strings.
- **API Calls:** Use generated Serverpod client from `shared_models` package. No direct REST calls.
- **Error Surfaces:** Friendly errors with retry actions. Log via analytics with correlation IDs.

### Data Transformation Standards

#### Layer Boundary Rules
- **UI → BLoC:** Convert raw user input to typed events with validation. Never pass primitive strings across layer boundaries.
- **BLoC → Use Cases:** Transform BLoC events to domain objects (value objects) with business validation.
- **Use Cases → Repositories:** Convert domain entities to DTOs for external communication.
- **Repositories → Data Sources:** Map between domain models and external API models with proper error handling.

#### Data Validation Requirements
```dart
// ✅ CORRECT: Validate and transform at boundaries
onChanged: (value) {
  if (EmailValidator.isValid(value)) {
    context.read<AuthBloc>().add(SignInEmailChanged(
      email: EmailAddress(value.trim()) // String → Value Object
    ));
  }
}

// ❌ INCORRECT: Pass raw strings across layers
context.read<AuthBloc>().add(SignInEmailChanged(email: value));
```

#### Error Handling Patterns
- Use `Either<Failure, Success>` patterns for domain operations
- Transform technical exceptions to domain failures at repository boundaries
- Convert domain failures to user-friendly messages in BLoC layer
- Never expose technical details to UI layer

#### Implementation Requirements
- **All transformations must be tested** with unit tests covering edge cases
- **Use immutable objects** for all data passing between layers
- **Document transformation rules** in code comments with examples
- **Handle null safety explicitly** at each transformation point
- **Include correlation IDs** in error messages for debugging

## Serverpod Backend
- **Module Layout:** Each bounded context in `serverpod/packages/modules/<context>/` with `domain`, `application`, `infrastructure` layers.
- **Dependency Injection:** Leverage Serverpod’s `Session` extensions/factories; avoid static service locators.
- **Repositories:** Encapsulate Postgres access in repository classes; keep business logic in service layer. All queries parameterized.
- **Transactions:** Wrap multi-step state transitions (offer→auction, payment flows) in `transaction` blocks; emit domain events via outbox pattern.
- **Validation:** Validate inputs at endpoint boundary; use shared validators for amount thresholds, status transitions.
- **Logging:** Use structured JSON logger with correlation IDs; do not log secrets or raw PII.

## Testing
- **Unit Tests:** Required for new logic; follow AAA pattern; place under matching `test/` path mirroring source folder.
- **Integration Tests:** Use Testcontainers for Postgres/Redis when touching persistence; stub externals (Stripe/Twilio) with WireMock/localstack.
- **Flutter Golden Tests:** Required for core screens (Feed, Story, Offer, Checkout) once UI stabilizes.
- **Mutation/Smoke Tests:** Run minimal smoke tests before merges using `flutter test --no-pub` and Serverpod test harness.

## Naming Conventions

### File Naming
- **Dart Files:** `snake_case.dart` (e.g., `user_repository.dart`, `auth_bloc.dart`)
- **Test Files:** `snake_case_test.dart` (e.g., `user_repository_test.dart`)
- **Golden Test Files:** `snake_case_golden_test.dart`
- **Story Files:** `kebab-case.md` (e.g., `user-sign-in-flow.md`)

### Class/Type Naming
- **Classes:** `PascalCase` (e.g., `UserRepository`, `AuthenticationBloc`)
- **Abstract Classes:** Prefix with `Abstract` or `Base` (e.g., `AbstractRepository`, `BaseWidget`)
- **Mixins:** `PascalCase` with `Mixin` suffix if not obvious (e.g., `ScrollableMixin`)
- **Enums:** `PascalCase` with descriptive members in `camelCase` (e.g., `enum AuthStatus { initial, loading, success, failure }`)

### Variable/Function Naming
- **Variables:** `camelCase` (e.g., `userRepository`, `isLoading`)
- **Constants:** `SCREAMING_SNAKE_CASE` (e.g., `API_BASE_URL`, `DEFAULT_TIMEOUT`)
- **Private Members:** Prefix with `_` (e.g., `_privateMethod`, `_internalState`)
- **Functions:** `camelCase` with descriptive verbs (e.g., `fetchUserData()`, `validateEmail()`)

### BLoC-Specific Naming
- **Events:** `PascalCase` with descriptive names (e.g., `SignInRequested`, `ProfileUpdated`)
- **States:** `PascalCase` with suffix indicating state (e.g., `AuthInitial`, `AuthLoading`, `AuthSuccess`)
- **BLoC Classes:** `PascalCase` with `Bloc` suffix (e.g., `AuthenticationBloc`, `ProfileBloc`)

### Widget Naming
- **Stateless Widgets:** `PascalCase` with descriptive names (e.g., `UserAvatar`, `LoadingSpinner`)
- **Stateful Widgets:** `PascalCase` with descriptive names (e.g., `SignInForm`, `VideoPlayer`)
- **Widget Tests:** `describe('ClassName', ...)` with descriptive test names

### Database/API Naming
- **Database Tables:** `snake_case` plural (e.g., `users`, `auction_bids`)
- **Database Columns:** `snake_case` (e.g., `created_at`, `user_id`)
- **API Endpoints:** `kebab-case` (e.g., `/users/{id}/profile`, `/auctions/create`)
- **JSON Fields:** `camelCase` for client-facing APIs

## Code Organization Patterns

### Feature Package Structure
```
packages/features/auth/
├── lib/
│   ├── use_cases/           # Feature-specific business logic
│   │   ├── sign_in_use_case.dart
│   │   ├── sign_up_use_case.dart
│   │   └── sign_out_use_case.dart
│   └── presentation/        # UI layer only
│       ├── bloc/
│       │   ├── auth_bloc.dart
│       │   ├── auth_event.dart
│       │   └── auth_state.dart
│       ├── pages/
│       │   ├── sign_in_page.dart
│       │   └── sign_up_page.dart
│       └── widgets/
│           ├── sign_in_form.dart
│           └── social_login_buttons.dart
└── pubspec.yaml
```

### Barrel Exports
Each feature package should have a main export file that exports commonly used classes:

```dart
// packages/features/auth/lib/auth.dart
export 'use_cases/sign_in_use_case.dart';
export 'use_cases/sign_up_use_case.dart';
export 'use_cases/sign_out_use_case.dart';
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/pages/sign_in_page.dart';
export 'presentation/pages/sign_up_page.dart';
export 'presentation/widgets/sign_in_form.dart';
```

### Dependency Injection Patterns
- **Constructor Injection**: Preferred for all services and repositories from core package
- **BLoC Provider**: Use `RepositoryProvider` and `BlocProvider` in widget tree
- **Package Dependencies**: Feature packages depend on core, shared_models, design_system
- **Service Locator**: Avoid GetIt - use BLoC and constructor injection instead

**Example: Feature package dependencies**
```dart
// packages/features/auth/pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  video_window_core:
    path: ../../core
  video_window_shared_models:
    path: ../../shared_models
  video_window_design_system:
    path: ../../design_system
  flutter_bloc: ^8.1.5
```

```dart
// Example dependency injection
class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepositoryImpl(
        remoteDataSource: context.read<AuthRemoteDataSource>(),
        localDataSource: context.read<AuthLocalDataSource>(),
      ),
      child: BlocProvider(
        create: (context) => AuthenticationBloc(
          signInUseCase: context.read<SignInUseCase>(),
        ),
        child: SignInView(),
      ),
    );
  }
}
```

## Performance Guidelines

### Widget Performance
- **Const Constructors**: Use `const` wherever possible for immutable widgets
- **Avoid Unnecessary Rebuilds**: Use `const`, `memoized`, and proper `build` method optimization
- **Image Optimization**: Use `cached_network_image` with proper sizing and placeholder strategies
- **List Performance**: Use `ListView.builder` for long lists, implement proper item extent

```dart
// GOOD: Efficient list implementation
ListView.builder(
  itemCount: items.length,
  itemExtent: 80.0, // Fixed height for better performance
  itemBuilder: (context, index) {
    return ItemWidget(item: items[index]);
  },
)

// BAD: Inefficient list without builder
Column(
  children: items.map((item) => ItemWidget(item: item)).toList(),
)
```

### Memory Management
- **Dispose Resources**: Always dispose controllers, streams, and animation controllers
- **Stream Management**: Use `StreamSubscription.cancel()` in dispose methods
- **Image Caching**: Configure proper cache limits for image-heavy applications
- **Large Data Handling**: Use pagination and lazy loading for large datasets

### Network Optimization
- **Request Batching**: Group multiple small requests into single larger requests
- **Caching Strategy**: Implement appropriate HTTP caching headers
- **Timeout Management**: Set reasonable timeouts for network requests (default: 30 seconds)
- **Retry Logic**: Implement exponential backoff for failed requests

### Database Optimization
- **Query Optimization**: Use proper indexes and avoid N+1 query problems
- **Connection Pooling**: Configure appropriate pool sizes for database connections
- **Transaction Management**: Keep transactions short and focused

## Environment-Specific Guidelines

### Configuration Management
- **Environment Variables**: Use `--dart-define` for environment-specific values
- **Feature Flags**: Centralize feature flag configuration for easy toggling
- **Secret Management**: Never commit secrets; use platform-specific secure storage

```dart
// Environment configuration example
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.craft.marketplace',
  );

  static const bool isDebugMode = kDebugMode;
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: false,
  );
}
```

### Development vs Production
- **Development**: Enable debug logs, feature toggles, mock data
- **Staging**: Production-like environment with testing features enabled
- **Production**: Optimized builds with minimal logging and security hardening

### Build Configurations
- **Debug**: Full debugging capabilities, no optimizations
- **Profile**: Debugging enabled with some optimizations
- **Release**: Full optimizations, no debugging, obfuscated code

## Mobile-Specific Best Practices

### Platform Integration
- **Permissions**: Request permissions at appropriate times with clear explanations
- **Background Processing**: Use proper background task management
- **Push Notifications**: Handle notification permissions and payload properly
- **Deep Linking**: Implement proper deep linking with route guards

### Performance on Mobile
- **Battery Life**: Minimize background processing and unnecessary network calls
- **Data Usage**: Implement data compression and offline-first strategies
- **Memory Usage**: Monitor memory usage and implement proper cleanup
- **Startup Time**: Optimize app initialization time

### Platform-Specific Code
```dart
// Platform-specific implementations
if (Platform.isIOS) {
  // iOS-specific code
  await iOSSpecificPermission.request();
} else if (Platform.isAndroid) {
  // Android-specific code
  await AndroidSpecificPermission.request();
}
```

### Responsive Design
- **Screen Sizes**: Support various screen sizes using LayoutBuilder and MediaQuery
- **Orientation**: Handle both portrait and landscape orientations appropriately
- **Safe Areas**: Use SafeArea widget to respect system UI elements

## Documentation Standards

### Code Documentation
- **Public APIs**: All public classes and methods must have dartdoc comments
- **Complex Logic**: Document non-obvious business logic with inline comments
- **TODO Comments**: Use `TODO(user): description` format with assigned responsibility

```dart
/// Handles user authentication with email and password.
///
/// Throws [AuthException] if authentication fails.
/// Returns [User] object on successful authentication.
///
/// Example:
/// ```dart
/// final user = await authService.signIn(email, password);
/// ```
Future<User> signIn({
  required String email,
  required String password,
}) async {
  // TODO(john): Implement rate limiting for sign-in attempts
  // Complex authentication logic here
}
```

### API Documentation
- **Endpoint Documentation**: Use OpenAPI/Swagger for REST APIs
- **Schema Documentation**: Document all data models and their relationships
- **Example Usage**: Provide clear examples for all major operations

### README Templates
Each major module should include a README.md with:
- Purpose and responsibilities
- Key classes and their roles
- Usage examples
- Testing guidelines

## Version Control and Collaboration

### Commit Message Format
Follow Conventional Commits with project-specific additions:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes (formatting, etc.)
- refactor: Code refactoring
- test: Adding or updating tests
- chore: Maintenance tasks
- perf: Performance improvements
- security: Security-related changes

Scopes:
- auth: Authentication related changes
- feed: Feed functionality
- video: Video player and processing
- auction: Auction and bidding logic
- payment: Payment processing
- ui: UI/UX improvements
- infra: Infrastructure and deployment

Examples:
feat(auth): implement email verification flow
fix(video): resolve memory leak in video player
docs(api): update authentication endpoint documentation
```

### Branch Protection Rules
- **Main Branches**: `main`, `develop` protected - require PR review
- **Feature Branches**: `feature/<description>` or `story/<id>-<description>`
- **Release Branches**: `release/<version>` for production preparation
- **Hotfix Branches**: `hotfix/<description>` for critical fixes

### Pull Request Guidelines
- **Title**: Follow commit message format
- **Description**: Include what changed, why it changed, and how to test
- **Testing**: All tests must pass before merge
- **Review**: Minimum one reviewer for all changes
- **Documentation**: Update relevant documentation

### Code Review Checklist
- [ ] Code follows project coding standards
- [ ] Tests are included and passing
- [ ] Documentation is updated if needed
- [ ] No sensitive data is committed
- [ ] Performance implications considered
- [ ] Security implications considered
- [ ] Accessibility requirements met
- [ ] Build passes on CI/CD

## Enhanced Accessibility Standards

### WCAG 2.1 AA Requirements
- **Color Contrast**: Minimum 4.5:1 for normal text, 3:1 for large text
- **Touch Targets**: Minimum 44x44dp for interactive elements
- **Focus Management**: Logical focus order and visible focus indicators
- **Screen Reader Support**: Semantic widgets and proper labels

### Flutter Accessibility Implementation
```dart
// GOOD: Accessible button with semantic label
ElevatedButton(
  onPressed: () => _submitForm(),
  child: Text('Submit'),
).addSemantics(
  label: 'Submit registration form',
  button: true,
);

// GOOD: Accessible form field with proper labeling
TextField(
  decoration: InputDecoration(
    labelText: 'Email Address',
    hintText: 'Enter your email address',
    errorText: _emailError,
  ),
  onChanged: (value) => _updateEmail(value),
  semanticsLabel: 'Email address input field',
)

// GOOD: Accessible image with description
Image.network(
  imageUrl,
  semanticLabel: 'Product photo: ${product.name}',
)
```

### Testing Accessibility
- **Screen Reader Testing**: Test with VoiceOver (iOS) and TalkBack (Android)
- **High Contrast Mode**: Test with high contrast mode enabled
- **Text Scaling**: Test with large text sizes (200% scaling)
- **Keyboard Navigation**: Test tab navigation and keyboard shortcuts

## Internationalization (i18n) Standards

### Implementation Requirements
- **String Externalization**: All user-facing strings must be externalized
- **Localization Files**: Use ARB files for translations
- **Context Support**: Provide context for translators when needed

```dart
// GOOD: Using localized strings
Text(AppLocalizations.of(context).welcomeMessage)

// GOOD: Pluralization support
Text(AppLocalizations.of(context).itemCount(itemCount))

// GOOD: Parameterized strings
Text(AppLocalizations.of(context).userName(userName))
```

### RTL Language Support
- **Layout Direction**: Use Directionality widgets for RTL support
- **Icon Mirroring**: Mirror icons appropriately for RTL languages
- **Text Alignment**: Handle text alignment for different writing directions

### Date/Number Formatting
- **Locale-Aware Formatting**: Use locale-specific date and number formatting
- **Currency Display**: Format currency based on locale and currency code
- **Time Zones**: Handle time zone conversions appropriately

### Testing Internationalization
- **Pseudo-Localization**: Test with pseudo-localized strings
- **Multiple Locales**: Test with supported language combinations
- **Text Expansion**: Test UI with longer strings (German, Finnish)
- **RTL Layout**: Test layout behavior with RTL languages

## Security Guidelines

### Input Validation and Sanitization
- **Client-Side Validation**: Validate all user inputs for format and length
- **Server-Side Validation**: Never trust client-side validation alone
- **Data Sanitization**: Sanitize all user inputs before processing or display
- **SQL Injection Prevention**: Use parameterized queries for database operations

### Data Protection
- **Encryption**: Encrypt sensitive data at rest and in transit
- **PII Handling**: Minimize collection of personally identifiable information
- **Data Retention**: Implement appropriate data retention policies
- **Secure Storage**: Use platform-specific secure storage for sensitive data

### Authentication and Authorization
- **Password Security**: Use strong hashing algorithms (bcrypt, Argon2)
- **Session Management**: Implement secure session handling with expiration
- **Multi-Factor Authentication**: Require MFA for sensitive operations
- **Permission Checks**: Validate permissions for all protected resources

## Enhanced Error Handling

### Error Classification
- **User Errors**: Validation failures, authentication errors
- **System Errors**: Network failures, database errors
- **Business Logic Errors**: Constraint violations, state conflicts
- **Critical Errors**: Security violations, data corruption

### Error Reporting
- **Structured Logging**: Use structured logging with correlation IDs
- **Error Aggregation**: Aggregate similar errors for analysis
- **Alert Thresholds**: Set appropriate alert thresholds for error rates
- **User Feedback**: Provide clear, actionable error messages to users

### Recovery Strategies
- **Automatic Retry**: Implement retry logic for transient failures
- **Graceful Degradation**: Provide fallback functionality when possible
- **User Guidance**: Guide users on how to resolve common errors
- **Offline Support**: Implement offline functionality where appropriate

## Performance Monitoring and Optimization

### Key Metrics
- **App Startup Time**: Target < 3 seconds for cold start
- **Screen Load Time**: Target < 1 second for screen transitions
- **Memory Usage**: Monitor and optimize memory consumption
- **Network Latency**: Optimize API response times
- **Battery Impact**: Minimize battery drain

### Monitoring Tools
- **Firebase Performance**: Use Firebase Performance Monitoring
- **Custom Metrics**: Implement custom performance metrics
- **Crash Reporting**: Use crash reporting with proper context
- **User Analytics**: Track user interaction patterns

### Optimization Strategies
- **Code Splitting**: Split code into smaller, focused modules
- **Lazy Loading**: Load resources only when needed
- **Caching**: Implement appropriate caching strategies
- **Image Optimization**: Optimize images for mobile delivery

This comprehensive coding standards document should be regularly reviewed and updated as the project evolves and new best practices emerge.

### Data Transformation Testing Requirements

#### Unit Testing Requirements
- **Every transformation point must have unit tests** covering:
  - Happy path transformations
  - Error cases (invalid inputs, null values, edge cases)
  - Boundary conditions (empty strings, max lengths, special characters)
  - Exception handling and error mapping

```dart
test('should map SignInRequest to use case parameters with validation', () {
  // Arrange
  final event = SignInSubmitted(email: 'test@example.com', password: 'validPassword123');

  // Act
  final result = mapEventToParams(event);

  // Assert
  expect(result.email.value, equals('test@example.com'));
  expect(result.isRight(), true);
});

test('should return failure for invalid email format', () {
  // Arrange
  final event = SignInSubmitted(email: 'invalid-email', password: 'password123');

  // Act
  final result = mapEventToParams(event);

  // Assert
  expect(result.isLeft(), true);
  expect(result.fold((l) => l, (r) => r), isA<ValidationFailure>());
});
```

#### Integration Testing Requirements
- **Test complete data flows** from UI to repository boundaries
- **Verify error transformation chains** work correctly across all layers
- **Test asynchronous transformations** with proper loading states
- **Include performance tests** for critical transformation paths

#### Test Coverage Requirements
- **Minimum 90% coverage** for all transformation code
- **100% coverage** for error handling and validation logic
- **Test edge cases** that could cause data corruption or security issues

## Tooling & Automation
- Run `dart format --output=none --set-exit-if-changed .` before commits.
- Run `flutter analyze --fatal-infos --fatal-warnings` and `flutter test --no-pub` locally; CI will block on failures.
- Enable IDE linting (`analysis_options.yaml`) and fix warnings; treat warnings as errors.
- Update story files (`docs/stories/...`) with Dev Status and QA notes as part of Done criteria.

## Commit & Branch Hygiene
- Branch naming: `story/<id>-<slug>` for story work; `feature|fix|chore/<slug>` for infrastructure tasks.
- Commit messages follow Conventional Commits with story reference, e.g., `feat(story-05.01): scaffold offer flow`.
- Squash merges into `develop` unless instructed; ensure CI green before merge.

## Documentation
- Significant decisions belong in ADRs under `docs/architecture/adr/` referencing story ids.
- Update `docs/architecture/story-component-mapping.md` when adding/removing modules or services.
- Maintain `docs/prd.md` Change Log when requirements shift.

Deviations require architect approval and must be documented in relevant story change logs.
