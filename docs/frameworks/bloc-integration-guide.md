# BLoC Integration Guide - Video Window Project

**Version:** flutter_bloc 8.1.3+ / bloc 9.1.0+  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Sprint 1 Foundation

---

## Overview

This guide documents how Video Window uses the **BLoC (Business Logic Component) pattern** for state management. This is NOT general BLoC documentation - it's our specific architecture, base classes, and conventions.

### Why BLoC in Video Window?

- **Predictable State Management:** Events in → States out, fully testable
- **Separation of Concerns:** UI separated from business logic
- **Reusability:** Base BLoC classes shared across features
- **Testability:** Event/State pattern makes unit testing straightforward
- **Time-Travel Debugging:** BlocObserver tracks all state transitions

### Architecture Philosophy
**BLoC pattern bridges presentation (UI) and domain (business logic) layers.**

---

## BLoC Architecture in Video Window

```
┌─────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                     │
│  (Feature Packages: packages/features/auth/presentation/)   │
│                                                              │
│  ┌──────────────┐        ┌──────────────┐                  │
│  │  Widget      │───────>│  BLoC/Cubit  │                  │
│  │  (UI)        │<───────│  (State Mgmt)│                  │
│  └──────────────┘ State  └──────────────┘                  │
│         │ Event                 │                           │
│         └───────────────────────┘                           │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ Use Case
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                         │
│           (Core Package: packages/core/)                     │
│                                                              │
│  ┌──────────────┐        ┌──────────────┐                  │
│  │  Use Case    │───────>│  Repository  │                  │
│  │  (Business   │        │  (Data       │                  │
│  │   Logic)     │        │   Access)    │                  │
│  └──────────────┘        └──────────────┘                  │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ Serverpod Client
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                        BACKEND LAYER                         │
│                    (Serverpod Server)                        │
└──────────────────────────────────────────────────────────────┘
```

---

## BLoC vs Cubit: When to Use Each

### Cubit - Simple State Management

**Use for:** Simple state changes, loading indicators, toggles, counters

**Characteristics:**
- Function-based state changes
- No events, just methods
- Less boilerplate
- Perfect for local UI state

**Example:** Theme toggle, visibility state, simple forms

### BLoC - Event-Driven State Management

**Use for:** Complex workflows, async operations, user actions

**Characteristics:**
- Event-driven architecture
- Full traceability (what caused state change)
- Event transformations (debounce, throttle)
- Best for critical business logic

**Example:** Authentication, API calls, complex forms, search

### Video Window Convention

**Default Choice: BLoC** for all feature-level state management
- Provides better traceability for debugging
- Consistent pattern across codebase
- Easier to add event transformations later

**Use Cubit for:** Local widget state only (pagination indicators, animation controllers)

---

## Base BLoC Classes (Core Package)

Video Window provides reusable base classes in `packages/core/lib/bloc/`:

### 1. BaseBloc (Foundation)

```dart
// packages/core/lib/bloc/base_bloc.dart
import 'package:bloc/bloc.dart';

abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(State initialState) : super(initialState);

  @override
  void onError(Object error, StackTrace stackTrace) {
    // Centralized error logging
    // Log to monitoring service (Sentry, Firebase Crashlytics, etc.)
    super.onError(error, stackTrace);
  }

  @override
  void onTransition(Transition<Event, State> transition) {
    // Log state transitions for debugging
    super.onTransition(transition);
  }
}
```

**Use for:** All BLoCs - provides logging and error handling

---

### 2. BaseListBloc (List/Pagination)

```dart
// packages/core/lib/bloc/base_list_bloc.dart
import 'package:equatable/equatable.dart';
import 'base_bloc.dart';

// States
abstract class ListState<T> extends Equatable {
  const ListState();
}

class ListInitial<T> extends ListState<T> {
  @override
  List<Object> get props => [];
}

class ListLoading<T> extends ListState<T> {
  @override
  List<Object> get props => [];
}

class ListSuccess<T> extends ListState<T> {
  final List<T> items;
  final bool hasMore;
  
  const ListSuccess({required this.items, this.hasMore = true});
  
  @override
  List<Object> get props => [items, hasMore];
}

class ListError<T> extends ListState<T> {
  final String message;
  
  const ListError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Events
abstract class ListEvent extends Equatable {
  const ListEvent();
}

class ListLoad extends ListEvent {
  @override
  List<Object> get props => [];
}

class ListLoadMore extends ListEvent {
  @override
  List<Object> get props => [];
}

class ListRefresh extends ListEvent {
  @override
  List<Object> get props => [];
}

// Base BLoC
abstract class BaseListBloc<T, E extends ListEvent>
    extends BaseBloc<E, ListState<T>> {
  BaseListBloc() : super(ListInitial<T>());

  Future<List<T>> fetchItems({int page = 1, int limit = 20});
}
```

**Use for:** Feed lists, search results, paginated data (Stories, Offers, Users)

---

### 3. BaseCrudBloc (Create/Read/Update/Delete)

```dart
// packages/core/lib/bloc/base_crud_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'base_bloc.dart';

// States
abstract class CrudState<T> extends Equatable {
  const CrudState();
}

class CrudInitial<T> extends CrudState<T> {
  @override
  List<Object> get props => [];
}

class CrudLoading<T> extends CrudState<T> {
  @override
  List<Object> get props => [];
}

class CrudSuccess<T> extends CrudState<T> {
  final T data;
  
  const CrudSuccess(this.data);
  
  @override
  List<Object> get props => [data!];
}

class CrudError<T> extends CrudState<T> {
  final String message;
  
  const CrudError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Events
abstract class CrudEvent extends Equatable {
  const CrudEvent();
}

class CrudCreate<T> extends CrudEvent {
  final T data;
  
  const CrudCreate(this.data);
  
  @override
  List<Object> get props => [data!];
}

class CrudRead extends CrudEvent {
  final String id;
  
  const CrudRead(this.id);
  
  @override
  List<Object> get props => [id];
}

class CrudUpdate<T> extends CrudEvent {
  final String id;
  final T data;
  
  const CrudUpdate(this.id, this.data);
  
  @override
  List<Object> get props => [id, data!];
}

class CrudDelete extends CrudEvent {
  final String id;
  
  const CrudDelete(this.id);
  
  @override
  List<Object> get props => [id];
}

// Base BLoC
abstract class BaseCrudBloc<T, E extends CrudEvent>
    extends BaseBloc<E, CrudState<T>> {
  BaseCrudBloc() : super(CrudInitial<T>());

  Future<Either<Failure, T>> create(T data);
  Future<Either<Failure, T>> read(String id);
  Future<Either<Failure, T>> update(String id, T data);
  Future<Either<Failure, void>> delete(String id);
}
```

**Use for:** Profile management, story publishing, offer submission

---

### 4. ServerpodBloc (Serverpod Integration)

```dart
// packages/core/lib/bloc/serverpod_bloc.dart
import 'package:dartz/dartz.dart';
import 'base_bloc.dart';

abstract class ServerpodBloc<Event, State> extends BaseBloc<Event, State> {
  ServerpodBloc(State initialState) : super(initialState);

  /// Handle Serverpod-specific errors
  Future<Either<Failure, T>> handleServerpodCall<T>(
    Future<T> Function() call,
  ) async {
    try {
      final result = await call();
      return Right(result);
    } on ServerpodException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
```

**Use for:** All BLoCs calling Serverpod endpoints

---

## Feature BLoC Implementation Pattern

### Step 1: Define Events

```dart
// packages/features/auth/lib/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';
import 'package:core/domain/value_objects/email_address.dart';
import 'package:core/domain/value_objects/password.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object> get props => [];
}

final class SignInRequested extends AuthEvent {
  final EmailAddress email;
  final Password password;
  
  const SignInRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

final class SignUpRequested extends AuthEvent {
  final EmailAddress email;
  final Password password;
  final String displayName;
  
  const SignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
  
  @override
  List<Object> get props => [email, password, displayName];
}

final class SignOutRequested extends AuthEvent {}

final class AuthStatusChecked extends AuthEvent {}
```

**Key Patterns:**
- Use `sealed class` for event base (Dart 3.0+)
- Use `final class` for concrete events
- Extend `Equatable` for value equality
- Use value objects (EmailAddress, Password) not raw strings
- Events are immutable (final fields)

---

### Step 2: Define States

```dart
// packages/features/auth/lib/presentation/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:core/domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {
  final User user;
  
  const Authenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {}

final class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

**Key Patterns:**
- Use `sealed class` for state base
- Use `final class` for concrete states
- States are immutable
- Include data in success states (Authenticated has User)
- Separate error state with message

---

### Step 3: Implement BLoC

```dart
// packages/features/auth/lib/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/bloc/serverpod_bloc.dart';
import 'package:auth/use_cases/sign_in_use_case.dart';
import 'package:auth/use_cases/sign_up_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends ServerpodBloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
  }) : super(AuthInitial()) {
    // Register event handlers
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await signInUseCase(
      email: event.email,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await signUpUseCase(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(Unauthenticated());
  }

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    // Check stored session
    emit(AuthLoading());
    // ... implementation
  }
}
```

**Key Patterns:**
- Extend `ServerpodBloc` (provides error handling)
- Inject use cases via constructor
- Register event handlers in constructor using `on<Event>`
- Separate handler method for each event type
- Use `Emitter<AuthState>` to emit new states
- Handle Either results from use cases

---

## Using BLoC in UI

### Providing BLoC

```dart
// lib/main.dart
void main() {
  // Initialize dependencies
  final serverpodClient = Client('http://localhost:8080/');
  final userRepository = UserRepositoryImpl(serverpodClient);
  
  final authBloc = AuthBloc(
    signInUseCase: SignInUseCase(userRepository),
    signUpUseCase: SignUpUseCase(userRepository),
  );
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        // Other BLoCs...
      ],
      child: const MyApp(),
    ),
  );
}
```

### BlocBuilder - Rebuild on State Changes

```dart
// packages/features/auth/lib/presentation/pages/sign_in_page.dart
class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is AuthError) {
            return ErrorWidget(message: state.message);
          }
          
          if (state is Authenticated) {
            return const Text('Welcome ${state.user.displayName}');
          }
          
          // Default: show sign-in form
          return const SignInForm();
        },
      ),
    );
  }
}
```

### BlocListener - Side Effects (Navigation, Snackbars)

```dart
class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate to home on successful auth
          context.go('/home');
        }
        
        if (state is AuthError) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: const SignInForm(),
    );
  }
}
```

### BlocConsumer - Combined Builder + Listener

```dart
class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Side effects (navigation, snackbars)
        if (state is Authenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        // UI rendering
        if (state is AuthLoading) {
          return const CircularProgressIndicator();
        }
        return const SignInForm();
      },
    );
  }
}
```

### Adding Events from UI

```dart
// In SignInForm widget
ElevatedButton(
  onPressed: () {
    final email = EmailAddress(emailController.text);
    final password = Password(passwordController.text);
    
    context.read<AuthBloc>().add(
      SignInRequested(email: email, password: password),
    );
  },
  child: const Text('Sign In'),
)
```

---

## Testing BLoC

### Unit Test Example

```dart
// packages/features/auth/test/presentation/bloc/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockSignInUseCase mockSignInUseCase;

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    authBloc = AuthBloc(
      signInUseCase: mockSignInUseCase,
      signUpUseCase: MockSignUpUseCase(),
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('SignInRequested', () {
    final email = EmailAddress('test@example.com');
    final password = Password('password123');
    final user = User(id: '1', email: 'test@example.com');

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when sign in succeeds',
      build: () {
        when(() => mockSignInUseCase(email: email, password: password))
            .thenAnswer((_) async => Right(user));
        return authBloc;
      },
      act: (bloc) => bloc.add(SignInRequested(email: email, password: password)),
      expect: () => [
        AuthLoading(),
        Authenticated(user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when sign in fails',
      build: () {
        when(() => mockSignInUseCase(email: email, password: password))
            .thenAnswer((_) async => Left(ServerFailure('Invalid credentials')));
        return authBloc;
      },
      act: (bloc) => bloc.add(SignInRequested(email: email, password: password)),
      expect: () => [
        AuthLoading(),
        AuthError('Invalid credentials'),
      ],
    );
  });
}
```

---

## Advanced Patterns

### Event Transformations (Debounce)

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

class SearchBloc extends BaseBloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }

  EventTransformer<E> debounce<E>(Duration duration) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    // API call only happens 300ms after user stops typing
    emit(SearchLoading());
    final results = await searchRepository.search(event.query);
    emit(SearchSuccess(results));
  }
}
```

### BlocObserver (Global Logging)

```dart
// lib/bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('onEvent -- ${bloc.runtimeType}, $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('onTransition -- ${bloc.runtimeType}, $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('onError -- ${bloc.runtimeType}, $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose -- ${bloc.runtimeType}');
  }
}

// Register in main.dart
void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}
```

---

## Video Window BLoC Conventions

### File Naming
```
auth_bloc.dart       # BLoC implementation
auth_event.dart      # Event definitions
auth_state.dart      # State definitions
```

### Event Naming
- Past tense for user actions: `SignInRequested`, `OfferSubmitted`
- Present tense for system events: `AuthStatusChecked`, `TimerTicked`

### State Naming
- Use adjectives: `Authenticated`, `Loading`, `Success`
- Include context: `AuthLoading` not just `Loading`
- Success states include data: `Authenticated(user)` not `AuthSuccess`

### BLoC Lifecycle
- Create once in `main.dart` or parent widget
- Provide via `BlocProvider` or `MultiBlocProvider`
- Dispose automatically (BlocProvider handles `close()`)
- Don't create new instances on every build

---

## Common Issues & Solutions

### Issue: BLoC not updating UI

**Cause:** State not properly implementing `Equatable` or `==` operator

**Solution:**
```dart
// ✅ CORRECT - extends Equatable
class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
  
  @override
  List<Object> get props => [user];  // Enables equality comparison
}

// ❌ WRONG - missing Equatable
class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
}
```

### Issue: "BlocProvider.of() called with a context that does not contain a Bloc"

**Cause:** Trying to access BLoC before it's provided

**Solution:**
```dart
// Ensure BlocProvider is ancestor in widget tree
BlocProvider<AuthBloc>(
  create: (_) => authBloc,
  child: SignInPage(),  // Now can access AuthBloc
);
```

### Issue: Multiple BLoCs need same data

**Cause:** Feature isolation breaking down

**Solution:** Use repository pattern, not BLoC-to-BLoC communication
```dart
// ✅ CORRECT - both BLoCs use same repository
final userRepository = UserRepositoryImpl();

BlocProvider<AuthBloc>(
  create: (_) => AuthBloc(userRepository),
),
BlocProvider<ProfileBloc>(
  create: (_) => ProfileBloc(userRepository),
),
```

---

## Reference Links

- **Official Docs:** https://bloclibrary.dev/
- **Our Melos Guide:** `docs/frameworks/melos-integration-guide.md`
- **Our Monorepo Guide:** `docs/frameworks/flutter-monorepo-guide.md`
- **Architecture:** `docs/architecture/coding-standards.md`

---

## Quick Reference

### BLoC vs Cubit Decision Matrix

| Use Case | Choice | Reason |
|----------|--------|--------|
| User authentication | BLoC | Traceability critical |
| API data fetching | BLoC | Async with errors |
| Form validation | BLoC | Multiple events |
| Theme toggle | Cubit | Simple boolean |
| Pagination indicator | Cubit | Local UI state |
| Search with debounce | BLoC | Event transformations |

### Essential Packages

```yaml
dependencies:
  flutter_bloc: ^8.1.3      # Flutter widgets
  bloc: ^9.1.0              # Core BLoC library
  equatable: ^2.0.5         # Value equality

dev_dependencies:
  bloc_test: ^9.1.0         # Testing utilities
  mocktail: ^1.0.0          # Mocking
```

---

**Next Steps for Developers:**
1. Read this guide + understand base classes in core package
2. Review auth BLoC implementation during Story 1.1
3. Follow patterns when implementing new features
4. Use `bloc_test` for comprehensive BLoC testing

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial integration guide created for Sprint 1, verified against bloc 9.1.0 docs | Winston (Architect) + Amelia (Developer) |

---

**Related Documentation:**
- `packages/core/lib/bloc/` - Base BLoC class implementations
- `docs/frameworks/melos-integration-guide.md` - Workspace management
- `docs/frameworks/flutter-monorepo-guide.md` - Package structure
- `docs/architecture/coding-standards.md` - Code conventions
