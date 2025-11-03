# JSON Serializable Integration Guide - Video Window

**Version:** json_serializable 6.7.1  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - DTO Serialization

---

## Overview

**json_serializable** generates `fromJson`/`toJson` methods for Dart classes. Used with Freezed for Serverpod DTOs.

---

## Installation

```yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
```

---

## Pattern 1: With Freezed (Recommended)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'offer.freezed.dart';
part 'offer.g.dart';

@freezed
class Offer with _$Offer {
  const factory Offer({
    required String id,
    required String storyId,
    required double amount,
    @JsonKey(name: 'buyer_id') required String buyerId,
    required DateTime createdAt,
  }) = _Offer;
  
  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
}
```

---

## Pattern 2: Standalone Class

```dart
import 'package:json_annotation/json_annotation.dart';

part 'auction.g.dart';

@JsonSerializable()
class Auction {
  final String id;
  final double currentBid;
  @JsonKey(name: 'ends_at') final DateTime endsAt;
  
  Auction({
    required this.id,
    required this.currentBid,
    required this.endsAt,
  });
  
  factory Auction.fromJson(Map<String, dynamic> json) => _$AuctionFromJson(json);
  Map<String, dynamic> toJson() => _$AuctionToJson(this);
}
```

---

## Pattern 3: Custom Converters

```dart
// For Serverpod DateTime handling
class TimestampConverter implements JsonConverter<DateTime, int> {
  const TimestampConverter();
  
  @override
  DateTime fromJson(int timestamp) => 
      DateTime.fromMillisecondsSinceEpoch(timestamp);
  
  @override
  int toJson(DateTime date) => date.millisecondsSinceEpoch;
}

// Usage
@JsonSerializable()
class Event {
  @TimestampConverter()
  final DateTime occurredAt;
  
  Event({required this.occurredAt});
  
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);
}
```

---

## Common Annotations

```dart
// Field name mapping
@JsonKey(name: 'user_id') String userId;

// Ignore field
@JsonKey(ignore: true) String? transientData;

// Default value
@JsonKey(defaultValue: []) List<String> tags;

// Nullable handling
@JsonKey(includeIfNull: false) String? optionalField;

// Custom converter
@JsonKey(fromJson: _parseDate, toJson: _formatDate) DateTime date;
```

---

## Code Generation

```bash
# From workspace root
melos run generate

# Or specific package
cd packages/core
dart run build_runner build --delete-conflicting-outputs
```

---

## Video Window Convention

**Use with Freezed** for all DTOs that interact with Serverpod:

```dart
@freezed
class StoryDto with _$StoryDto {
  const factory StoryDto({...}) = _StoryDto;
  factory StoryDto.fromJson(Map<String, dynamic> json) => 
      _$StoryDtoFromJson(json);
}
```

---

## Reference

- **Package:** https://pub.dev/packages/json_serializable
- **Version:** 6.7.1

---

**Last Updated:** 2025-11-03 by Winston
