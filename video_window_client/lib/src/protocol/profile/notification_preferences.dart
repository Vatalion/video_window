/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class NotificationPreferences implements _i1.SerializableModel {
  NotificationPreferences._({
    this.id,
    required this.userId,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.inAppNotifications,
    this.settings,
    this.quietHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferences({
    int? id,
    required int userId,
    required bool emailNotifications,
    required bool pushNotifications,
    required bool inAppNotifications,
    String? settings,
    String? quietHours,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationPreferencesImpl;

  factory NotificationPreferences.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return NotificationPreferences(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      emailNotifications: jsonSerialization['emailNotifications'] as bool,
      pushNotifications: jsonSerialization['pushNotifications'] as bool,
      inAppNotifications: jsonSerialization['inAppNotifications'] as bool,
      settings: jsonSerialization['settings'] as String?,
      quietHours: jsonSerialization['quietHours'] as String?,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  bool emailNotifications;

  bool pushNotifications;

  bool inAppNotifications;

  String? settings;

  String? quietHours;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [NotificationPreferences]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationPreferences copyWith({
    int? id,
    int? userId,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? inAppNotifications,
    String? settings,
    String? quietHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'inAppNotifications': inAppNotifications,
      if (settings != null) 'settings': settings,
      if (quietHours != null) 'quietHours': quietHours,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationPreferencesImpl extends NotificationPreferences {
  _NotificationPreferencesImpl({
    int? id,
    required int userId,
    required bool emailNotifications,
    required bool pushNotifications,
    required bool inAppNotifications,
    String? settings,
    String? quietHours,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
          id: id,
          userId: userId,
          emailNotifications: emailNotifications,
          pushNotifications: pushNotifications,
          inAppNotifications: inAppNotifications,
          settings: settings,
          quietHours: quietHours,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [NotificationPreferences]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationPreferences copyWith({
    Object? id = _Undefined,
    int? userId,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? inAppNotifications,
    Object? settings = _Undefined,
    Object? quietHours = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      inAppNotifications: inAppNotifications ?? this.inAppNotifications,
      settings: settings is String? ? settings : this.settings,
      quietHours: quietHours is String? ? quietHours : this.quietHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
