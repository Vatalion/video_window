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
class PrivacySettingsChangedEvent extends AnalyticsEvent {
  final int userId;
  final Map<String, dynamic> changedSettings;
  final DateTime _timestamp;

  PrivacySettingsChangedEvent({
    required this.userId,
    required this.changedSettings,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'privacy_settings_changed';

  @override
  Map<String, dynamic> get properties => {
        'user_id': userId,
        'changed_settings': changedSettings,
      };

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
