# Equatable Integration Guide - Video Window

**Version:** equatable 2.0.7  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Core Development Foundation

---

## Overview

**Equatable** simplifies value-based equality comparisons in Dart by automatically implementing `==` and `hashCode`. This is **essential for BLoC pattern** where events and states must be compared by value, not instance.

### Why Equatable in Video Window?

- **BLoC State Management:** BLoC only rebuilds UI when states change. Without Equatable, `AuthLoading()` != `AuthLoading()` (different instances)
- **Eliminates Boilerplate:** No manual `==` and `hashCode` overrides for every class
- **Immutability Enforcement:** Works only with `final` fields, preventing mutable state bugs
- **Performance:** Efficient equality checks for collections, sets, and maps
- **Debugging:** Optional `stringify` for readable state/event logging

### Alternatives Considered

| Alternative | Why Not Used |
|-------------|-------------|
| Manual `==` override | Too verbose, error-prone for 50+ BLoC events/states |
| `freezed` | Adds code generation complexity; Equatable is runtime-only |
| `built_value` | Overkill for simple value equality |

---

## Installation

**Already included in core package:**

```yaml
# packages/core/pubspec.yaml
dependencies:
  equatable: ^2.0.7  # Value equality for domain entities
```

**No additional setup needed** - all feature packages inherit from core.

---

## Video Window Usage Patterns

### Pattern 1: BLoC Events (MOST COMMON)

**All BLoC events MUST extend Equatable** to enable proper event comparison.

```dart
// packages/features/auth/lib/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';
import 'package:core/domain/value_objects/email_address.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object> get props => [];  // Default empty props
}

final class SignInRequested extends AuthEvent {
  final EmailAddress email;
  final Password password;
  
  const SignInRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];  // Include all fields
}

final class SignOutRequested extends AuthEvent {
  // No fields - uses default empty props from base class
}
```

**Key Patterns:**
- Base class defines `props => []` for events with no data
- Concrete events override `props` with all fields
- Use value objects (EmailAddress, Password) not raw strings
- `const` constructors for immutability

---

### Pattern 2: BLoC States

**All BLoC states MUST extend Equatable** for UI rebuild optimization.

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
  List<Object?> get props => [user];  // User is Equatable
}

final class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

**Critical:** Use `List<Object?>` (nullable) for props with nullable fields.

---

### Pattern 3: Domain Entities

**Core domain entities extend Equatable** for repository caching and comparison.

```dart
// packages/core/lib/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });
  
  @override
  List<Object?> get props => [id, email, displayName, createdAt];
  
  @override
  bool get stringify => true;  // Enable toString for debugging
}
```

---

### Pattern 4: Value Objects

**Value objects use Equatable** for equality based on value, not identity.

```dart
// packages/core/lib/domain/value_objects/email_address.dart
import 'package:equatable/equatable.dart';

class EmailAddress extends Equatable {
  final String value;
  
  const EmailAddress(this.value);
  
  @override
  List<Object> get props => [value];
  
  @override
  bool get stringify => true;  // EmailAddress(user@example.com)
  
  // Validation logic
  bool get isValid => _emailRegex.hasMatch(value);
}
```

**Why Equatable for Value Objects:**
```dart
final email1 = EmailAddress('test@example.com');
final email2 = EmailAddress('test@example.com');

print(email1 == email2);  // true (same value)
print(identical(email1, email2));  // false (different instances)
```

---

## Advanced Patterns

### Nullable Props

**Use `List<Object?>` when fields can be null:**

```dart
class Story extends Equatable {
  final String id;
  final String title;
  final String? description;  // Nullable
  final List<String>? tags;   // Nullable
  
  const Story({
    required this.id,
    required this.title,
    this.description,
    this.tags,
  });
  
  @override
  List<Object?> get props => [id, title, description, tags];  // Object? not Object
}
```

---

### Collections in Props

**Equatable handles lists/maps correctly:**

```dart
class SearchState extends Equatable {
  final List<Story> results;
  final Set<String> filters;
  final Map<String, dynamic> metadata;
  
  const SearchState({
    required this.results,
    required this.filters,
    required this.metadata,
  });
  
  @override
  List<Object> get props => [results, filters, metadata];
  // Deep equality: compares collection contents, not instance
}
```

---

### EquatableMixin (When You Can't Extend)

**Use mixin when class already has superclass:**

```dart
import 'package:equatable/equatable.dart';

class EquatableDateTime extends DateTime with EquatableMixin {
  EquatableDateTime(int year, [int month = 1, int day = 1])
      : super(year, month, day);
  
  @override
  List<Object> get props => [year, month, day, hour, minute, second];
}
```

**Video Window Use Case:** Custom Serverpod model extensions

---

### Stringify for Debugging

**Enable `stringify` for readable logging:**

```dart
class AuthState extends Equatable {
  // ... fields
  
  @override
  List<Object> get props => [/* fields */];
  
  @override
  bool get stringify => true;  // AuthState(user: User(...), isLoading: false)
}
```

**Global Configuration (in main.dart):**
```dart
import 'package:equatable/equatable.dart';

void main() {
  EquatableConfig.stringify = true;  // Enable for all Equatable classes
  runApp(const MyApp());
}
```

**Video Window Convention:**
- Enable `stringify` for **domain entities** (User, Story, Offer)
- Enable `stringify` for **error states** (easier debugging)
- Disable for **list states** (too verbose with many items)

---

## Testing with Equatable

### Unit Test Example

```dart
// packages/features/auth/test/presentation/bloc/auth_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/presentation/bloc/auth_event.dart';
import 'package:core/domain/value_objects/email_address.dart';

void main() {
  group('SignInRequested', () {
    test('two events with same props are equal', () {
      final email = EmailAddress('test@example.com');
      final password = Password('password123');
      
      final event1 = SignInRequested(email: email, password: password);
      final event2 = SignInRequested(email: email, password: password);
      
      expect(event1, equals(event2));
    });
    
    test('events with different props are not equal', () {
      final event1 = SignInRequested(
        email: EmailAddress('user1@example.com'),
        password: Password('password123'),
      );
      final event2 = SignInRequested(
        email: EmailAddress('user2@example.com'),
        password: Password('password123'),
      );
      
      expect(event1, isNot(equals(event2)));
    });
    
    test('props returns all fields', () {
      final email = EmailAddress('test@example.com');
      final password = Password('password123');
      final event = SignInRequested(email: email, password: password);
      
      expect(event.props, [email, password]);
    });
  });
}
```

---

## Common Issues & Solutions

### Issue 1: BLoC Not Rebuilding UI

**Symptom:** UI doesn't update when emitting new state

**Cause:** State class missing Equatable or props not including all fields

```dart
// ❌ WRONG - Missing field in props
class AuthState extends Equatable {
  final User user;
  final bool isLoading;
  
  const AuthState(this.user, this.isLoading);
  
  @override
  List<Object> get props => [user];  // Missing isLoading!
}

// ✅ CORRECT - All fields in props
class AuthState extends Equatable {
  final User user;
  final bool isLoading;
  
  const AuthState(this.user, this.isLoading);
  
  @override
  List<Object> get props => [user, isLoading];
}
```

---

### Issue 2: "Failed assertion: 'props != null'"

**Cause:** Forgot to override `props` getter

```dart
// ❌ WRONG - No props override
class MyEvent extends Equatable {
  final String data;
  const MyEvent(this.data);
  // Missing: @override List<Object> get props => [data];
}

// ✅ CORRECT
class MyEvent extends Equatable {
  final String data;
  const MyEvent(this.data);
  
  @override
  List<Object> get props => [data];
}
```

---

### Issue 3: Mutable Fields

**Symptom:** Runtime error "Equatable only works with immutable objects"

```dart
// ❌ WRONG - Mutable field
class User extends Equatable {
  String name;  // Not final!
  
  User(this.name);
  
  @override
  List<Object> get props => [name];
}

// ✅ CORRECT - All fields final
class User extends Equatable {
  final String name;
  
  const User(this.name);
  
  @override
  List<Object> get props => [name];
}
```

---

### Issue 4: Nested Equatable Objects

**Symptom:** Deep equality not working for nested objects

```dart
// ❌ WRONG - Nested object not Equatable
class Address {  // Missing Equatable
  final String street;
  const Address(this.street);
}

class User extends Equatable {
  final Address address;
  const User(this.address);
  
  @override
  List<Object> get props => [address];  // Won't compare correctly!
}

// ✅ CORRECT - Nested object also Equatable
class Address extends Equatable {
  final String street;
  const Address(this.street);
  
  @override
  List<Object> get props => [street];
}

class User extends Equatable {
  final Address address;
  const User(this.address);
  
  @override
  List<Object> get props => [address];  // Deep equality works!
}
```

---

## Video Window Conventions

### File Organization
```
packages/core/lib/domain/
├── entities/              # Domain entities (extend Equatable)
│   ├── user.dart
│   ├── story.dart
│   └── offer.dart
├── value_objects/         # Value objects (extend Equatable)
│   ├── email_address.dart
│   ├── password.dart
│   └── money.dart
└── failures/              # Error types (extend Equatable)
    ├── failure.dart
    └── network_failure.dart
```

### Naming Standards
- **Events:** `<Action>Requested`, `<Entity><Action>`
- **States:** Adjectives (`Loading`, `Success`, `Error`)
- **Entities:** Nouns (`User`, `Story`, `Offer`)
- **Value Objects:** Domain terms (`EmailAddress`, `Money`)

### Props Order Convention
List fields in `props` in **constructor parameter order**:

```dart
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  
  const User({
    required this.id,
    required this.email,
    required this.name,
  });
  
  @override
  List<Object> get props => [id, email, name];  // Same order as constructor
}
```

---

## Performance Considerations

### Equatable is Fast
- **O(n)** complexity where n = number of props
- Benchmarks show ~10-20ns per comparison (negligible)
- No runtime overhead vs manual implementation

### When NOT to Use Equatable
- **Extremely large objects** (>50 fields) - consider splitting
- **Objects compared rarely** - manual implementation fine
- **Performance-critical paths** (rare) - profile first

### Optimization Tips
```dart
// ✅ GOOD - Only include fields that affect equality
class CachedStory extends Equatable {
  final String id;
  final String title;
  final DateTime fetchedAt;  // Don't include in props if irrelevant
  
  @override
  List<Object> get props => [id, title];  // fetchedAt excluded
}
```

---

## Reference

### Official Documentation
- **Package:** https://pub.dev/packages/equatable
- **API Docs:** https://pub.dev/documentation/equatable/latest/
- **Version Used:** 2.0.7

### Related Video Window Guides
- **BLoC Integration:** `docs/frameworks/bloc-integration-guide.md`
- **Value Objects:** `docs/architecture/coding-standards.md#value-objects`
- **Domain Entities:** `packages/core/README.md`

---

## Quick Reference

### Checklist for New Equatable Classes

- [ ] Class is immutable (all fields `final`)
- [ ] Extends `Equatable` or uses `EquatableMixin`
- [ ] Overrides `props` getter with all relevant fields
- [ ] Uses `List<Object?>` if any fields are nullable
- [ ] Uses `const` constructor when possible
- [ ] Nested objects are also Equatable
- [ ] Includes `stringify => true` for debugging (optional)

### Common Patterns

```dart
// Empty props (no fields)
@override
List<Object> get props => [];

// Simple props
@override
List<Object> get props => [id, name, email];

// Nullable props
@override
List<Object?> get props => [id, name, optionalField];

// Collection props
@override
List<Object> get props => [id, items, tags];

// With stringify
@override
bool get stringify => true;
```

---

**Last Updated:** 2025-11-03 by Winston (Architect)  
**Verified Against:** equatable 2.0.7 (pub.dev)  
**Next Review:** On equatable 3.0.0 release

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial integration guide for Video Window, verified against equatable 2.0.7 | Winston (Architect) |
