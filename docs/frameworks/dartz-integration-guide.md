# Dartz Integration Guide - Video Window

**Version:** dartz 0.10.1  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Core Development Foundation

---

## Overview

**Dartz** provides functional programming tools for Dart, most importantly the **`Either<L, R>` type** for handling errors functionally. In Video Window, we use Either to represent operations that can fail, replacing traditional try-catch with explicit success/failure types.

### Why Dartz in Video Window?

- **Explicit Error Handling:** `Either<Failure, Success>` forces handling both paths
- **Type-Safe Failures:** Domain-specific failure types (`NetworkFailure`, `ServerFailure`)
- **Composable:** Chain operations with `map`, `flatMap`, `fold`
- **No Exceptions Crossing Boundaries:** Repository layer transforms exceptions to Either
- **Testable:** Mock failures without throwing exceptions

### Architecture Role

```
Repository → Either<Failure, Entity> → Use Case → Either<Failure, Entity> → BLoC
```

**Never use Either in:**
- Presentation layer (BLoC emits states, not Either)
- UI widgets
- Pure domain logic (entities, value objects)

**Always use Either in:**
- Repository methods
- Use case `call()` methods
- Any operation that can fail with domain errors

---

## Installation

**Already included in core package:**

```yaml
# packages/core/pubspec.yaml
dependencies:
  dartz: ^0.10.1  # Functional error handling
```

---

## Core Concept: Either<L, R>

`Either` represents a value that is **either Left (failure) or Right (success)**.

```dart
import 'package:dartz/dartz.dart';

// Convention: Left = Error, Right = Success
Either<String, int> divide(int a, int b) {
  if (b == 0) {
    return Left('Division by zero');  // Error path
  }
  return Right(a ~/ b);  // Success path
}
```

**Memory Aid:** "Right" is "right" (correct), "Left" is "left out" (error).

---

## Video Window Pattern: Either<Failure, Success>

### Failure Hierarchy

```dart
// packages/core/lib/domain/failures/failure.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network connection failed']) 
      : super(message);
}

class ServerFailure extends Failure {
  final int? statusCode;
  
  const ServerFailure(String message, [this.statusCode]) : super(message);
  
  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache operation failed']) 
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String resource) 
      : super('$resource not found');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Authentication required']) 
      : super(message);
}
```

---

## Pattern 1: Repository Implementation

**Repositories return `Either<Failure, T>`:**

```dart
// packages/core/lib/data/repositories/user_repository.dart
import 'package:dartz/dartz.dart';
import 'package:core/domain/entities/user.dart';
import 'package:core/domain/failures/failure.dart';
import 'package:video_window_client/video_window_client.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUserById(String id);
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
}

class UserRepositoryImpl implements UserRepository {
  final Client serverpodClient;
  
  UserRepositoryImpl(this.serverpodClient);
  
  @override
  Future<Either<Failure, User>> getUserById(String id) async {
    try {
      final userDto = await serverpodClient.user.getUser(id);
      
      if (userDto == null) {
        return Left(NotFoundFailure('User'));
      }
      
      // Transform DTO → Domain Entity
      final user = User.fromDto(userDto);
      return Right(user);
      
    } on ServerpodException catch (e) {
      if (e.statusCode == 404) {
        return Left(NotFoundFailure('User'));
      }
      if (e.statusCode == 401) {
        return Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(e.message, e.statusCode));
      
    } on NetworkException {
      return Left(NetworkFailure());
      
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, User>> signIn(String email, String password) async {
    try {
      final authResponse = await serverpodClient.auth.signIn(email, password);
      final user = User.fromDto(authResponse.user);
      return Right(user);
      
    } on ServerpodException catch (e) {
      if (e.message.contains('Invalid credentials')) {
        return Left(ValidationFailure('Invalid email or password'));
      }
      return Left(ServerFailure(e.message, e.statusCode));
      
    } on NetworkException {
      return Left(NetworkFailure());
      
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

**Key Patterns:**
- Catch specific exceptions, transform to domain Failures
- Use `Left(failure)` for errors, `Right(success)` for success
- Never let exceptions escape repositories
- Transform DTOs to domain entities before returning

---

## Pattern 2: Use Case Implementation

**Use cases call repositories and return Either:**

```dart
// packages/features/auth/lib/use_cases/sign_in_use_case.dart
import 'package:dartz/dartz.dart';
import 'package:core/domain/entities/user.dart';
import 'package:core/domain/failures/failure.dart';
import 'package:core/domain/value_objects/email_address.dart';
import 'package:core/domain/value_objects/password.dart';
import 'package:core/data/repositories/user_repository.dart';

class SignInUseCase {
  final UserRepository repository;
  
  SignInUseCase(this.repository);
  
  Future<Either<Failure, User>> call({
    required EmailAddress email,
    required Password password,
  }) async {
    // Validate inputs
    if (!email.isValid) {
      return Left(ValidationFailure('Invalid email format'));
    }
    
    if (!password.isValid) {
      return Left(ValidationFailure('Password must be at least 8 characters'));
    }
    
    // Call repository
    return await repository.signIn(email.value, password.value);
  }
}
```

---

## Pattern 3: BLoC Integration

**BLoCs consume Either and emit states:**

```dart
// packages/features/auth/lib/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/use_cases/sign_in_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  
  AuthBloc({required this.signInUseCase}) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
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
    
    // Use fold to handle both paths
    result.fold(
      (failure) => emit(AuthError(failure.message)),  // Left path
      (user) => emit(Authenticated(user)),            // Right path
    );
  }
}
```

**Key Pattern:** Use `.fold()` to extract value and emit appropriate state.

---

## Either Methods Reference

### fold - Extract Value (MOST COMMON)

```dart
final result = await repository.getUserById('123');

// Execute different code paths based on Left or Right
result.fold(
  (failure) {
    // Left path - handle error
    print('Error: ${failure.message}');
    return null;
  },
  (user) {
    // Right path - handle success
    print('User: ${user.name}');
    return user;
  },
);
```

---

### getOrElse - Provide Default Value

```dart
final result = await repository.getUserById('123');

// Get value or default
final user = result.getOrElse(() => User.guest());
```

---

### map - Transform Success Value

```dart
final result = await repository.getUserById('123');

// Transform User → String (only if Right)
final Either<Failure, String> userName = result.map((user) => user.name);
```

---

### flatMap (bind) - Chain Operations

```dart
// Chain multiple Either-returning operations
final result = await repository.getUserById('123')
  .then((userResult) {
    return userResult.flatMap((user) {
      // If getUserById succeeded, fetch profile
      return repository.getUserProfile(user.id);
    });
  });

// Result is Either<Failure, Profile>
// Short-circuits on first Left
```

---

### isLeft / isRight - Check State

```dart
final result = await repository.getUserById('123');

if (result.isLeft()) {
  print('Operation failed');
}

if (result.isRight()) {
  print('Operation succeeded');
}
```

---

### getOrElse with Throw (Anti-Pattern)

```dart
// ❌ WRONG - Defeats purpose of Either
final user = result.getOrElse(() => throw Exception('Failed'));

// ✅ CORRECT - Handle error properly
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (user) => emit(SuccessState(user)),
);
```

---

## Advanced Patterns

### Pattern: Multiple Repository Calls

```dart
class GetUserWithProfileUseCase {
  final UserRepository userRepo;
  final ProfileRepository profileRepo;
  
  GetUserWithProfileUseCase(this.userRepo, this.profileRepo);
  
  Future<Either<Failure, UserProfile>> call(String userId) async {
    // Get user
    final userResult = await userRepo.getUserById(userId);
    
    // Short-circuit if user fetch failed
    if (userResult.isLeft()) {
      return Left(userResult.fold((f) => f, (_) => throw UnreachableError()));
    }
    
    final user = userResult.getOrElse(() => throw UnreachableError());
    
    // Get profile
    final profileResult = await profileRepo.getProfile(user.id);
    
    // Combine results
    return profileResult.map((profile) => UserProfile(user, profile));
  }
}
```

**Better with flatMap:**

```dart
Future<Either<Failure, UserProfile>> call(String userId) async {
  final userResult = await userRepo.getUserById(userId);
  
  return Future.value(userResult).then((result) {
    return result.fold(
      (failure) async => Left(failure),
      (user) async {
        final profileResult = await profileRepo.getProfile(user.id);
        return profileResult.map((profile) => UserProfile(user, profile));
      },
    );
  }).then((future) => future);
}
```

---

### Pattern: Validation Before Repository Call

```dart
class CreateStoryUseCase {
  final StoryRepository repository;
  
  Future<Either<Failure, Story>> call(String title, String content) async {
    // Validate inputs
    if (title.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    
    if (content.length < 100) {
      return Left(ValidationFailure('Content must be at least 100 characters'));
    }
    
    // Validation passed, call repository
    return await repository.createStory(title, content);
  }
}
```

---

### Pattern: Transform Failure Type

```dart
// Change Left type while preserving Right
final Either<NetworkFailure, User> result = await repository.getUserById('123');

final Either<String, User> simplified = result.leftMap((failure) => failure.message);
```

---

## Testing with Either

### Unit Test Example

```dart
// packages/core/test/data/repositories/user_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockServerpodClient extends Mock implements Client {}

void main() {
  late UserRepositoryImpl repository;
  late MockServerpodClient mockClient;
  
  setUp(() {
    mockClient = MockServerpodClient();
    repository = UserRepositoryImpl(mockClient);
  });
  
  group('getUserById', () {
    test('returns Right(User) on success', () async {
      // Arrange
      final userDto = UserDto(id: '123', name: 'Test User');
      when(() => mockClient.user.getUser('123'))
          .thenAnswer((_) async => userDto);
      
      // Act
      final result = await repository.getUserById('123');
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not be Left'),
        (user) {
          expect(user.id, '123');
          expect(user.name, 'Test User');
        },
      );
    });
    
    test('returns Left(NotFoundFailure) when user not found', () async {
      // Arrange
      when(() => mockClient.user.getUser('123'))
          .thenAnswer((_) async => null);
      
      // Act
      final result = await repository.getUserById('123');
      
      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (user) => fail('Should not be Right'),
      );
    });
    
    test('returns Left(NetworkFailure) on network error', () async {
      // Arrange
      when(() => mockClient.user.getUser('123'))
          .thenThrow(NetworkException());
      
      // Act
      final result = await repository.getUserById('123');
      
      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (user) => fail('Should not be Right'),
      );
    });
  });
}
```

---

## Common Mistakes & Solutions

### Mistake 1: Not Handling Either in BLoC

```dart
// ❌ WRONG - Doesn't handle Either
Future<void> _onSignInRequested(event, emit) async {
  final result = await signInUseCase(email: event.email, password: event.password);
  // result is Either, but not handled!
  emit(Authenticated(result));  // Type error!
}

// ✅ CORRECT - Use fold
Future<void> _onSignInRequested(event, emit) async {
  final result = await signInUseCase(email: event.email, password: event.password);
  result.fold(
    (failure) => emit(AuthError(failure.message)),
    (user) => emit(Authenticated(user)),
  );
}
```

---

### Mistake 2: Throwing Exceptions from Repository

```dart
// ❌ WRONG - Throwing exceptions
Future<Either<Failure, User>> getUserById(String id) async {
  final user = await serverpodClient.user.getUser(id);
  if (user == null) {
    throw NotFoundException();  // Don't throw!
  }
  return Right(User.fromDto(user));
}

// ✅ CORRECT - Return Left
Future<Either<Failure, User>> getUserById(String id) async {
  try {
    final user = await serverpodClient.user.getUser(id);
    if (user == null) {
      return Left(NotFoundFailure('User'));  // Return Left
    }
    return Right(User.fromDto(user));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

---

### Mistake 3: Using Either in UI Layer

```dart
// ❌ WRONG - Either in widget
Widget build(BuildContext context) {
  return FutureBuilder<Either<Failure, User>>(
    future: repository.getUserById('123'),  // Don't use repository directly!
    builder: (context, snapshot) { ... },
  );
}

// ✅ CORRECT - Use BLoC
Widget build(BuildContext context) {
  return BlocBuilder<UserBloc, UserState>(
    builder: (context, state) {
      if (state is UserLoaded) {
        return Text(state.user.name);
      }
      // Handle other states...
    },
  );
}
```

---

## Video Window Conventions

### Repository Method Signatures

```dart
abstract class UserRepository {
  // Read operations
  Future<Either<Failure, User>> getUserById(String id);
  Future<Either<Failure, List<User>>> searchUsers(String query);
  
  // Write operations
  Future<Either<Failure, User>> createUser(User user);
  Future<Either<Failure, User>> updateUser(User user);
  Future<Either<Failure, void>> deleteUser(String id);  // void for no return value
}
```

### Use Case Method Signatures

```dart
class SignInUseCase {
  // Always named `call` for consistent invocation
  Future<Either<Failure, User>> call({
    required EmailAddress email,
    required Password password,
  }) async { ... }
}

// Usage:
final result = await signInUseCase(email: email, password: password);
```

### Failure Naming

- **Network issues:** `NetworkFailure`
- **Server errors:** `ServerFailure` (with status code)
- **Not found:** `NotFoundFailure` (with resource name)
- **Validation:** `ValidationFailure` (with specific message)
- **Auth:** `UnauthorizedFailure`, `ForbiddenFailure`
- **Cache:** `CacheFailure`

---

## Performance Notes

- **Either is lightweight:** Minimal overhead vs raw values
- **No runtime penalty:** Compiled away in release mode
- **Stack safe:** Uses trampolining for recursive operations
- **Memory efficient:** Single object allocation

---

## Reference

### Official Documentation
- **Package:** https://pub.dev/packages/dartz
- **API Docs:** https://pub.dev/documentation/dartz/latest/
- **Version Used:** 0.10.1

### Related Video Window Guides
- **BLoC Integration:** `docs/frameworks/bloc-integration-guide.md`
- **Repository Pattern:** `docs/architecture/coding-standards.md#repositories`
- **Value Objects:** `packages/core/README.md#value-objects`

---

## Quick Reference

### Essential Methods

```dart
// Create Either
final success = Right(user);
final failure = Left(NetworkFailure());

// Extract value
result.fold(
  (failure) => handleError(failure),
  (user) => handleSuccess(user),
);

// Default value
final user = result.getOrElse(() => User.guest());

// Transform
final name = result.map((user) => user.name);

// Chain
final profile = result.flatMap((user) => getProfile(user.id));

// Check state
if (result.isRight()) { ... }
if (result.isLeft()) { ... }
```

---

**Last Updated:** 2025-11-03 by Winston (Architect)  
**Verified Against:** dartz 0.10.1 (pub.dev)  
**Next Review:** On dartz major version change

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial integration guide for Video Window, verified against dartz 0.10.1 | Winston (Architect) |
