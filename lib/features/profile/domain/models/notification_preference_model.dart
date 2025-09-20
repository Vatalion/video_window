import 'package:equatable/equatable.dart';

class NotificationPreferenceModel extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final bool enabled;
  final DeliveryMethod deliveryMethod;
  final bool quietHoursEnabled;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final int frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferenceModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.enabled,
    required this.deliveryMethod,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.frequency = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      enabled: json['enabled'] as bool,
      deliveryMethod: DeliveryMethod.values.firstWhere(
        (e) => e.name == json['delivery_method'],
        orElse: () => DeliveryMethod.push,
      ),
      quietHoursEnabled: json['quiet_hours_enabled'] as bool,
      quietHoursStart: json['quiet_hours_start'] != null
          ? DateTime.parse(json['quiet_hours_start'] as String)
          : null,
      quietHoursEnd: json['quiet_hours_end'] != null
          ? DateTime.parse(json['quiet_hours_end'] as String)
          : null,
      frequency: json['frequency'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'enabled': enabled,
      'delivery_method': deliveryMethod.name,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart?.toIso8601String(),
      'quiet_hours_end': quietHoursEnd?.toIso8601String(),
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
        id,
        userId,
        type,
        enabled,
        deliveryMethod,
        quietHoursEnabled,
        quietHoursStart ?? '',
        quietHoursEnd ?? '',
        frequency,
        createdAt,
        updatedAt,
      ];
}

enum NotificationType {
  system,
  messages,
  friendRequests,
  comments,
  likes,
  mentions,
  follows,
  commerce,
  security,
  marketing,
  updates,
}

enum DeliveryMethod {
  push,
  email,
  inApp,
  sms,
}

class NotificationSettings extends Equatable {
  final List<NotificationPreferenceModel> preferences;
  final bool globalEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool ledEnabled;
  final bool badgeEnabled;

  const NotificationSettings({
    required this.preferences,
    this.globalEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.ledEnabled = true,
    this.badgeEnabled = true,
  });

  NotificationPreferenceModel? getPreferenceForType(NotificationType type) {
    try {
      return preferences.firstWhere((p) => p.type == type);
    } catch (e) {
      return null;
    }
  }

  bool isTypeEnabled(NotificationType type) {
    if (!globalEnabled) return false;
    final preference = getPreferenceForType(type);
    return preference?.enabled ?? true;
  }

  @override
  List<Object> get props => [
        preferences,
        globalEnabled,
        soundEnabled,
        vibrationEnabled,
        ledEnabled,
        badgeEnabled,
      ];
}