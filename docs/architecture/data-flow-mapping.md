# Data Flow & Transformation Guide — Craft Video Marketplace

**Status:** Draft v0.1 (2025-10-04) — Comprehensive guide to data transformation points across application layers.

## Purpose

This document provides detailed specifications for data transformation, mapping, and flow patterns across all layers of the video marketplace application. It serves as the authoritative reference for implementing clean data flow patterns, ensuring consistency and maintainability across the codebase.

## Overview of Data Flow Architecture

The application follows **Clean Architecture principles** with clear separation of concerns and unidirectional data flow. Each layer has specific responsibilities for data transformation and validation.

### Layer Structure & Data Flow Direction

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Presentation)                    │
│  ┌─────────────┐    Events    ┌─────────────┐    States    │
│  │   Widgets   │ ─────────────→│    BLoC     │ ─────────────→│
│  │             │               │ (Feature)   │               │
│  │   Pages     │ ←─────────────│   States    │ ←─────────────│
│  └──────────────    UI States  └──────────────    Events    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ Use Case Calls
┌─────────────────────────────────────────────────────────────┐
│              Feature Layer (Feature Packages)                  │
│  ┌─────────────┐  Parameters   ┌─────────────┐  Results    │
│  │   BLoCs      │ ─────────────→│  Use Cases  │ ─────────────→│
│  │ (Feature)   │               │ (Feature)   │               │
│  │  Events     │ ←─────────────│   Results   │ ←─────────────│
│  └──────────────    States     └──────────────   Parameters  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ Repository Calls
┌─────────────────────────────────────────────────────────────┐
│                Core Layer (Core Package)                       │
│  ┌─────────────┐  Entities     ┌─────────────┐  DTOs       │
│  │ Use Cases   │ ─────────────→│ Repositories│ ─────────────→│
│  │ (Core)      │               │ (Core)      │               │
│  │ Results     │ ←─────────────│    Results  │ ←─────────────│
│  └──────────────   Domain      └──────────────   Serverpod   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ Generated Client
┌─────────────────────────────────────────────────────────────┐
│           Shared Models Layer (Shared Models Package)           │
│  ┌─────────────┐  Models       ┌─────────────┐  Generated  │
│  │ Repositories│ ─────────────→│ Serverpod   │ ─────────────→│
│  │ (Core)      │               │   Client    │               │
│  │  DTOs       │ ←─────────────│    Models   │ ←─────────────│
│  └──────────────   Generated   └──────────────   API       │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Data Transformation Points

### 1. UI Layer ↔ BLoC Transformations

#### 1.1 UI Events → BLoC Events
**Purpose**: Convert user interactions and UI state changes into typed BLoC events.

**Transformation Pattern**:
```dart
// UI Widget (Example: Sign In Form)
class SignInForm extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Column(
          children: [
            TextFormField(
              onChanged: (value) {
                // UI Input → BLoC Event
                context.read<AuthBloc>().add(SignInEmailChanged(email: value));
              },
            ),
            ElevatedButton(
              onPressed: () {
                // UI Action → BLoC Event
                context.read<AuthBloc>().add(
                  SignInSubmitted(
                    email: _emailController.text,
                    password: _passwordController.text,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
```

**Key Transformation Rules**:
- Validate input format before creating events
- Convert raw strings to appropriate types (email validation, phone formatting)
- Include contextual metadata (source screen, timestamp)
- Handle null/empty values appropriately

#### 1.2 BLoC States → UI State
**Purpose**: Convert BLoC states into renderable UI components with appropriate loading/error states.

**Transformation Pattern**:
```dart
// BLoC State → UI Rendering
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    return state.when(
      initial: () => SignInForm(), // Initial UI state
      loading: () => CircularProgressIndicator(), // Loading indicator
      success: (user) => SuccessMessage(user: user), // Success UI
      failure: (error) => ErrorWidget( // Error handling
        message: error.message,
        onRetry: () => context.read<AuthBloc>().add(SignInRetry()),
      ),
    );
  },
)
```

**Key Transformation Rules**:
- Map each state variant to appropriate UI component
- Include loading indicators for async operations
- Provide error states with retry mechanisms
- Handle success states with appropriate feedback

### 2. BLoC ↔ Use Case Transformations

#### 2.1 BLoC Events → Use Case Parameters
**Purpose**: Convert BLoC events into typed use case parameters with proper validation.

**Transformation Pattern**:
```dart
// packages/features/auth/lib/presentation/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;

  AuthBloc(this._signInUseCase) : super(AuthState.initial()) {
    on<SignInSubmitted>(_onSignInSubmitted);
  }

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      // Transform BLoC event to use case parameters
      final result = await _signInUseCase.call(
        SignInParams(
          email: EmailAddress(event.email), // String → Value Object
          password: Password(event.password), // String → Value Object
          rememberMe: event.rememberMe ?? false, // Default handling
        ),
      );

      result.fold(
        (failure) => emit(AuthState.failure(failure)),
        (user) => emit(AuthState.success(user)),
      );
    } catch (e) {
      emit(AuthState.failure(AuthFailure.unknown(e.toString())));
    }
  }
}
```

**Key Transformation Rules**:
- Convert primitive types to value objects (EmailAddress, Password)
- Apply business logic validation before use case calls
- Handle optional parameters with appropriate defaults
- Wrap calls in error handling with proper state transitions

#### 2.2 Use Case Results → BLoC State
**Purpose**: Convert use case results (Either/Result types) into BLoC states.

**Transformation Pattern**:
```dart
// Use Case Result → BLoC State
final result = await _signInUseCase.call(params);

result.fold(
  (failure) => emit(AuthState.failure(
    mapFailureToState(failure), // Domain failure → UI failure
  )),
  (user) => emit(AuthState.success(
    mapEntityToViewModel(user), // Domain entity → View model
  )),
);
```

### 3. Use Case ↔ Repository Transformations

#### 3.1 Use Case Parameters → Repository Interface
**Purpose**: Convert use case parameters to repository interface calls with appropriate data mapping.

**Transformation Pattern**:
```dart
// packages/features/auth/lib/use_cases/sign_in_use_case.dart
class SignInUseCase implements UseCase<User, SignInParams> {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  @override
  Future<Either<AuthFailure, User>> call(SignInParams params) async {
    // Validate parameters
    if (!params.email.isValid()) {
      return left(AuthFailure.invalidEmail(params.email.value));
    }

    try {
      // Domain parameters → Core repository call
      final authResult = await _repository.signIn(
        email: params.email.value, // Value Object → Primitive
        password: params.password.value,
        deviceInfo: _collectDeviceInfo(),
      );

      return authResult.map(
        (userModel) => mapModelToEntity(userModel), // Shared Model → Domain Entity
      );
    } on ServerException catch (e) {
      return left(mapServerExceptionToFailure(e));
    }
  }
}
```

**Key Transformation Rules**:
- Extract primitive values from domain objects for repository calls
- Add technical metadata (device info, timestamps)
- Handle repository-specific exceptions and map to domain failures
- Convert data models to domain entities

#### 3.2 Repository Results → Domain Entities
**Purpose**: Transform external data models into pure domain entities.

**Transformation Pattern**:
```dart
// packages/core/lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final ServerpodClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<Either<AuthFailure, User>> signIn({
    required String email,
    required String password,
    required DeviceInfo deviceInfo,
  }) async {
    try {
      // Core repository → Serverpod client call
      final userModel = await _client.auth.signIn(
        email: email,
        password: password,
        deviceInfo: deviceInfo.toJson(),
      );

      // Shared Model → Domain Entity
      final user = User(
        id: UserId(userModel.id),
        email: EmailAddress(userModel.email),
        username: Username(userModel.username),
        isEmailVerified: userModel.isEmailVerified,
        createdAt: userModel.createdAt,
      );

      return Right(user);
    } on ServerpodException catch (e) {
      return Left(mapServerExceptionToAuthFailure(e));
    }
  }
}
```

### 4. Core Repository ↔ Serverpod Transformations

#### 4.1 Repository Parameters → Serverpod Method Calls
**Purpose**: Convert repository parameters to Serverpod method calls with proper serialization.

**Transformation Pattern**:
```dart
// packages/core/lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final ServerpodClient _client;

  @override
  Future<Either<AuthFailure, User>> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Direct Serverpod method call
      final userModel = await _client.auth.signUp(
        email: email,
        password: password,
        username: username,
      );

      // Serverpod Model → Domain Entity
      return Right(User.fromSharedModel(userModel));
    } on ServerpodException catch (e) {
      return Left(mapServerExceptionToAuthFailure(e));
    }
  }
}
```

#### 4.2 Serverpod Responses → Domain Entities
**Purpose**: Transform Serverpod generated models into pure domain entities.

**Transformation Pattern**:
```dart
// packages/shared_models/lib/extensions/user_extension.dart
extension UserExtension on User {
  static User fromSharedModel(UserModel model) {
    return User(
      id: UserId(model.id),
      email: EmailAddress(model.email),
      username: Username(model.username),
      isEmailVerified: model.isEmailVerified,
      createdAt: model.createdAt,
    );
  }
}
```

### 5. Capability Enablement Data Flow

Unified accounts rely on capability flags (`canPublish`, `canCollectPayments`, `canFulfillOrders`) instead of maker-only roles. Each restricted action follows the transformation chain below:

1. **UI Layer** — Inline guards (publish CTA, checkout button, fulfillment actions) consult `CapabilityBloc`/`CapabilityCenterBloc` to read the latest `UserCapabilities` snapshot. Missing capability triggers the guided checklist dialog and dispatches a capability request event.
2. **BLoC Layer** — Emits `CapabilityRequested` event containing capability enum, entry point, and optional draft/order identifiers. The BLoC validates client-side prerequisites and delegates to `RequestCapabilityUseCase`.
3. **Use Case Layer** — Normalizes metadata (caps enum strings, trims context) and calls `CapabilityRepository.requestCapability`, attaching idempotency tokens and device fingerprint hash where required.
4. **Repository Layer** — Translates domain objects to Serverpod DTOs, invokes `capability_service.requestCapability`, and maps the `CapabilityStatusDto` response back to domain `UserCapabilities` with blocker messages.
5. **Serverpod Layer** — `capability_service` upserts `capability_requests`, triggers verification tasks (Persona, Stripe), evaluates device trust via `device_trust_service`, and emits audit events (`capability.requested`, `capability.unlocked`).
6. **Client Update** — Repository response updates BLoC state; unlock events remove UI guards. Downstream flows subscribe to capability event stream so publish/checkout buttons enable without full-screen refresh.

**Transformation Rules**
- Treat capability names as enums/value objects to avoid raw string drift.
- Map server-provided blocker codes to localized copy via `CapabilityBlockerMapper` before reaching UI layer.
- Preserve correlation IDs across layers for audit traceability and analytics funnels.
- Device telemetry is redacted client-side; trust scoring occurs server-side with only score/blocker returned.

## Error Handling Across Layer Boundaries

### Error Transformation Chain
```
External API Exception (ServerpodException)
       ↓
Data Source Layer (ServerException)
       ↓
Repository Layer (Domain Failure)
       ↓
Use Case Layer (Either<Failure, Success>)
       ↓
BLoC Layer (State.failure)
       ↓
UI Layer (ErrorWidget with retry)
```

### Error Mapping Examples

```dart
// 1. External Exception → Domain Failure
AuthFailure mapServerExceptionToFailure(ServerException exception) {
  switch (exception.statusCode) {
    case 401:
      return AuthFailure.invalidCredentials();
    case 403:
      return AuthFailure.accessDenied();
    case 429:
      return AuthFailure.tooManyRequests();
    case 500:
      return AuthFailure.serverError();
    default:
      return AuthFailure.unknown(exception.message);
  }
}

// 2. Domain Failure → UI Message
String mapFailureToMessage(AuthFailure failure) {
  return failure.when(
    invalidEmail: () => 'Please enter a valid email address',
    invalidCredentials: () => 'Invalid email or password',
    accessDenied: () => 'Access denied. Please contact support.',
    tooManyRequests: () => 'Too many attempts. Please try again later.',
    serverError: () => 'Server error. Please try again.',
    networkError: () => 'Network connection error',
    unknown: (message) => 'An error occurred: $message',
  );
}
```

## Data Validation Points

### 1. Input Layer Validation (UI)
- Format validation (email, phone numbers)
- Required field validation
- Length constraints
- Character set validation

### 2. Domain Layer Validation (Use Cases)
- Business rule validation
- Cross-field validation
- Domain-specific constraints
- Authorization checks

### 3. Data Layer Validation (Repository)
- Data consistency checks
- Referential integrity
- Transaction boundaries
- Retry logic for transient failures

## Testing Strategies for Data Transformations

### 1. Unit Tests for Each Transformation
```dart
test('should map SignInRequest to use case parameters correctly', () {
  // Arrange
  final event = SignInSubmitted(email: 'test@example.com', password: 'password123');

  // Act
  final params = mapEventToParams(event);

  // Assert
  expect(params.email.value, equals('test@example.com'));
  expect(params.password.value, equals('password123'));
});
```

### 2. Integration Tests for Flow End-to-End
```dart
test('should complete sign in flow from UI to repository', () async {
  // Arrange
  mockDataSource.signIn.mockReturnValue(mockUserModel);

  // Act
  final result = await signInUseCase.call(mockParams);

  // Assert
  expect(result.isRight(), true);
  verify(mockDataSource.signIn(any)).called(1);
});
```

### 3. Golden Tests for UI State Transformations
```dart
testWidgets('should display loading state during sign in', (tester) async {
  // Arrange
  when(mockSignInUseCase.call(any)).thenAnswer((_) async => Future.delayed(Duration(seconds: 1)));

  // Act
  await tester.pumpWidget(SignInScreen());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.byType(SignInForm), findsNothing);
});
```

## Performance Considerations

### 1. Lazy Transformations
- Defer expensive transformations until needed
- Use cached transformation results where appropriate
- Implement efficient collection mapping

### 2. Memory Management
- Dispose of transformation objects properly
- Use weak references for cached transformations
- Avoid memory leaks in event streams

### 3. Asynchronous Operations
- Use proper async/await patterns
- Implement cancellation tokens for long operations
- Handle concurrent operations safely

## Security Considerations

### 1. Data Sanitization
- Sanitize inputs before transformation
- Remove sensitive data from logs
- Validate data integrity at boundaries

### 2. Error Information Leakage
- Transform technical errors to user-friendly messages
- Avoid exposing internal system details
- Log detailed errors separately from user feedback

## Monitoring and Observability

### 1. Transformation Metrics
- Track transformation success/failure rates
- Monitor transformation latency
- Log transformation errors with context

### 2. Data Flow Tracing
- Use correlation IDs across layer boundaries
- Track data lineage for debugging
- Implement distributed tracing for complex flows

## Best Practices Summary

### DO:
- ✅ Use typed objects for all data transformations
- ✅ Handle errors gracefully at each boundary
- ✅ Write comprehensive tests for each transformation point
- ✅ Use functional programming patterns (Either/Result)
- ✅ Implement proper logging and monitoring
- ✅ Document transformation rules and business logic

### DON'T:
- ❌ Pass raw primitive types across layer boundaries
- ❌ Mix concerns (UI logic in domain layer)
- ❌ Skip error handling at transformation points
- ❌ Use exceptions for expected business logic flows
- ❌ Ignore performance implications of transformations
- ❌ Forget to test edge cases and null values

This guide should be referenced when implementing any new features or modifying existing data flow patterns to ensure consistency and maintainability across the application.