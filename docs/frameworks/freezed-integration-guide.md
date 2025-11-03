# Freezed Integration Guide - Video Window

**Version:** freezed 2.4.5  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Immutable Models

---

## Overview

**Freezed** generates immutable classes with copyWith, equality, and toString. Used for DTOs and complex domain models in Video Window.

### Why Freezed?

- **Immutability:** Generate const constructors automatically
- **copyWith:** Update immutable objects easily
- **Pattern Matching:** Union types for states/events
- **JSON Serialization:** Integrates with json_serializable
- **Reduces Boilerplate:** 5 lines → 50+ lines generated

---

## Installation

```yaml
# packages/core/pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
```

---

## Pattern 1: Simple Immutable Class

```dart
// packages/core/lib/domain/entities/story.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'story.freezed.dart';

@freezed
class Story with _$Story {
  const factory Story({
    required String id,
    required String title,
    required String description,
    required String videoUrl,
    required String makerId,
    required DateTime createdAt,
    @Default([]) List<String> tags,
  }) = _Story;
}
```

**Generate code:**
```bash
cd video_window_flutter
melos run generate
```

**Usage:**
```dart
final story = Story(
  id: '123',
  title: 'Handmade Pottery',
  description: 'Learn pottery basics',
  videoUrl: 'https://...',
  makerId: 'maker_1',
  createdAt: DateTime.now(),
  tags: ['pottery', 'crafts'],
);

// copyWith for updates
final updated = story.copyWith(title: 'Advanced Pottery');

// Automatic equality
print(story == Story(...));  // Uses generated ==

// Automatic toString
print(story);  // Story(id: 123, title: Handmade Pottery, ...)
```

---

## Pattern 2: With JSON Serialization

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';  // json_serializable

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String displayName,
    DateTime? lastLoginAt,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

**Usage:**
```dart
// From JSON
final user = User.fromJson(jsonDecode(response));

// To JSON
final json = user.toJson();
```

---

## Pattern 3: Union Types (States)

```dart
@freezed
class OfferState with _$OfferState {
  const factory OfferState.initial() = _Initial;
  const factory OfferState.loading() = _Loading;
  const factory OfferState.loaded(List<Offer> offers) = _Loaded;
  const factory OfferState.error(String message) = _Error;
}
```

**Pattern matching:**
```dart
state.when(
  initial: () => const Text('No offers'),
  loading: () => const CircularProgressIndicator(),
  loaded: (offers) => OffersList(offers: offers),
  error: (message) => ErrorWidget(message),
);

// Or maybeWhen
state.maybeWhen(
  loaded: (offers) => OffersList(offers: offers),
  orElse: () => const Placeholder(),
);
```

---

## Pattern 4: Custom Methods

```dart
@freezed
class Money with _$Money {
  const Money._();  // Private constructor for custom methods
  
  const factory Money({
    required double amount,
    @Default('USD') String currency,
  }) = _Money;
  
  // Custom methods
  bool get isZero => amount == 0;
  bool get isPositive => amount > 0;
  String get formatted => '\$$amount $currency';
}
```

---

## Video Window Conventions

### When to Use Freezed

✅ **Use for:**
- DTOs (Data Transfer Objects from Serverpod)
- Complex domain entities (Story, Offer, Auction)
- Union types (states, events with pattern matching)

❌ **Don't use for:**
- Simple value objects (use Equatable instead)
- Performance-critical classes (generate adds overhead)
- Classes with many custom methods

---

## Common Patterns

```dart
// Default values
@Default([]) List<String> tags,
@Default(0) int viewCount,

// Nullable fields
String? description,
DateTime? publishedAt,

// JSON key mapping
@JsonKey(name: 'user_id') String userId,

// Ignore in JSON
@JsonKey(ignore: true) String? cachedData,

// Custom JSON converter
@JsonKey(fromJson: _dateFromTimestamp, toJson: _dateToTimestamp)
DateTime createdAt,
```

---

## Code Generation

```bash
# Generate once
melos run generate

# Watch mode (auto-regenerate)
cd packages/core
dart run build_runner watch --delete-conflicting-outputs
```

---

## Reference

- **Package:** https://pub.dev/packages/freezed
- **Version:** 2.4.5

---

**Last Updated:** 2025-11-03 by Winston  
**Verified Against:** freezed 2.4.5 docs
