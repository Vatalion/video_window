import 'package:core/services/analytics_service.dart';

/// Analytics event for profile updates
class ProfileUpdatedEvent extends AnalyticsEvent {
  final int userId;
  final List<String> changedFields;
  final DateTime _timestamp;

  ProfileUpdatedEvent({
    required this.userId,
    required this.changedFields,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'profile_updated';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'changed_fields': changedFields,
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for privacy settings changes
/// AC4: Emit event with setting_name, old_value, new_value
class PrivacySettingsChangedEvent extends AnalyticsEvent {
  final int userId;
  final String? settingName;
  final String? oldValue;
  final String? newValue;
  final Map<String, dynamic>? changedSettings; // Fallback for batch updates
  final DateTime _timestamp;

  PrivacySettingsChangedEvent({
    required this.userId,
    this.settingName,
    this.oldValue,
    this.newValue,
    this.changedSettings,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'privacy_settings_changed';

  @override
  Map<String, dynamic> get properties {
    // AC4: Format with setting_name, old_value, new_value if available
    if (settingName != null && oldValue != null && newValue != null) {
      return {
        'user_id': userId,
        'setting_name': settingName,
        'old_value': oldValue,
        'new_value': newValue,
      };
    }
    // Fallback to batch format if individual values not provided
    return {
      'user_id': userId,
      'changed_settings': changedSettings ?? {},
    };
  }

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for notification preferences changes
class NotificationPreferencesUpdatedEvent extends AnalyticsEvent {
  final int userId;
  final Map<String, dynamic> changedPreferences;
  final DateTime _timestamp;

  NotificationPreferencesUpdatedEvent({
    required this.userId,
    required this.changedPreferences,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'notification_preferences_updated';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'changed_preferences': changedPreferences,
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for profile completion metrics
class ProfileCompletionEvent extends AnalyticsEvent {
  final int userId;
  final double completionPercentage;
  final List<String> missingFields;
  final DateTime _timestamp;

  ProfileCompletionEvent({
    required this.userId,
    required this.completionPercentage,
    required this.missingFields,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'profile_completion';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'completion_percentage': completionPercentage,
        'missing_fields': missingFields,
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for DSAR operations
class DsarOperationEvent extends AnalyticsEvent {
  final int userId;
  final String operationType; // 'export' or 'delete'
  final DateTime _timestamp;

  DsarOperationEvent({
    required this.userId,
    required this.operationType,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'dsar_operation';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'operation_type': operationType,
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for avatar upload (Story 3-2)
/// AC4: Analytics event avatar_uploaded with metadata
class AvatarUploadedEvent extends AnalyticsEvent {
  final int userId;
  final int fileSizeBytes;
  final String mimeType;
  final int processingTimeMs;
  final DateTime _timestamp;

  AvatarUploadedEvent({
    required this.userId,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.processingTimeMs,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'avatar_uploaded';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'file_size': fileSizeBytes,
        'mime_type': mimeType,
        'processing_time_ms': processingTimeMs,
      };

  @override
  DateTime get timestamp => _timestamp;
}
