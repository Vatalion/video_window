enum NotificationType {
  profileView,
  follower,
  message,
  commerce,
  system,
  security,
}

enum DeliveryMethod { push, email, inApp }

class NotificationPreference {
  final String userId;
  final NotificationType notificationType;
  final bool enabled;
  final Set<DeliveryMethod> deliveryMethods;
  final DateTime updatedAt;

  NotificationPreference({
    required this.userId,
    required this.notificationType,
    this.enabled = true,
    Set<DeliveryMethod>? deliveryMethods,
    required this.updatedAt,
  }) : deliveryMethods = deliveryMethods ?? {DeliveryMethod.inApp};

  NotificationPreference copyWith({
    NotificationType? notificationType,
    bool? enabled,
    Set<DeliveryMethod>? deliveryMethods,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      userId: userId,
      notificationType: notificationType ?? this.notificationType,
      enabled: enabled ?? this.enabled,
      deliveryMethods: deliveryMethods ?? this.deliveryMethods,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get displayName {
    switch (notificationType) {
      case NotificationType.profileView:
        return 'Profile Views';
      case NotificationType.follower:
        return 'New Followers';
      case NotificationType.message:
        return 'Messages';
      case NotificationType.commerce:
        return 'Commerce';
      case NotificationType.system:
        return 'System Updates';
      case NotificationType.security:
        return 'Security Alerts';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'notificationType': notificationType.name,
      'enabled': enabled,
      'deliveryMethods': deliveryMethods.map((e) => e.name).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      userId: json['userId'] as String,
      notificationType: NotificationType.values.firstWhere(
        (e) => e.name == json['notificationType'],
        orElse: () => NotificationType.system,
      ),
      enabled: json['enabled'] as bool? ?? true,
      deliveryMethods: (json['deliveryMethods'] as List<dynamic>?)
              ?.map((e) => DeliveryMethod.values.firstWhere(
                    (d) => d.name == e,
                    orElse: () => DeliveryMethod.inApp,
                  ))
              .toSet() ??
          {DeliveryMethod.inApp},
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}