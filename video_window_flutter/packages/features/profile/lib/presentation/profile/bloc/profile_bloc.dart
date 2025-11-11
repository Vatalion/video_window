import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:core/data/repositories/profile/profile_media_repository.dart';
import 'package:core/services/analytics_service.dart';
import 'dart:convert';
import 'profile_event.dart';
import 'profile_state.dart';
import '../analytics/profile_analytics_events.dart';

/// BLoC for managing profile state
/// Implements Story 3-1: Viewer Profile Management
/// Extends Story 3-2: Avatar & Media Upload System
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final ProfileMediaRepository? _mediaRepository;
  final AnalyticsService? _analyticsService;

  ProfileBloc(
    this._profileRepository, {
    ProfileMediaRepository? mediaRepository,
    AnalyticsService? analyticsService,
  })  : _mediaRepository = mediaRepository,
        _analyticsService = analyticsService,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<PrivacySettingsLoadRequested>(_onPrivacySettingsLoadRequested);
    on<PrivacySettingsUpdateRequested>(_onPrivacySettingsUpdateRequested);
    on<NotificationPreferencesLoadRequested>(
        _onNotificationPreferencesLoadRequested);
    on<NotificationPreferencesUpdateRequested>(
        _onNotificationPreferencesUpdateRequested);
    on<ExportUserDataRequested>(_onExportUserDataRequested);
    on<DeleteUserDataRequested>(_onDeleteUserDataRequested);
    on<DSARExportRequested>(_onDSARExportRequested);
    on<AccountDeletionRequested>(_onAccountDeletionRequested);
    on<RevokeAllSessionsRequested>(_onRevokeAllSessionsRequested);
    on<AvatarUploadRequested>(_onAvatarUploadRequested);
    on<AvatarUploadProgressed>(_onAvatarUploadProgressed);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final profile = await _profileRepository.getMyProfile(event.userId);
      if (profile == null) {
        emit(const ProfileError(message: 'Profile not found'));
        return;
      }

      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to load profile: $e',
        errorCode: 'LOAD_ERROR',
      ));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final updatedProfile = await _profileRepository.updateMyProfile(
        event.userId,
        event.profileData,
      );

      // Emit analytics event for profile update
      final changedFields = event.profileData.keys.toList();
      _analyticsService?.trackEvent(
        ProfileUpdatedEvent(
          userId: event.userId,
          changedFields: changedFields,
        ),
      );

      emit(ProfileUpdated(profile: updatedProfile));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to update profile: $e',
        errorCode: 'UPDATE_ERROR',
      ));
    }
  }

  Future<void> _onPrivacySettingsLoadRequested(
    PrivacySettingsLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final settings =
          await _profileRepository.getPrivacySettings(event.userId);
      emit(PrivacySettingsUpdated(settings: settings));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to load privacy settings: $e',
        errorCode: 'PRIVACY_LOAD_ERROR',
      ));
    }
  }

  Future<void> _onPrivacySettingsUpdateRequested(
    PrivacySettingsUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Load previous settings to track changes (AC4: analytics event format)
      Map<String, dynamic>? previousSettings;
      try {
        previousSettings =
            await _profileRepository.getPrivacySettings(event.userId);
      } catch (_) {
        // If we can't load previous settings, continue anyway
      }

      final updatedSettings = await _profileRepository.updatePrivacySettings(
        event.userId,
        event.settingsData,
      );

      // AC4: Emit analytics event with setting_name, old_value, new_value format
      // Emit individual events for each changed setting
      if (_analyticsService != null && previousSettings != null) {
        for (final entry in event.settingsData.entries) {
          final settingName = entry.key;
          final newValue = entry.value;
          final oldValue = previousSettings[settingName];

          // Only emit if value actually changed
          if (oldValue != newValue) {
            _analyticsService.trackEvent(
              PrivacySettingsChangedEvent(
                userId: event.userId,
                settingName: settingName,
                oldValue: oldValue?.toString() ?? 'null',
                newValue: newValue?.toString() ?? 'null',
              ),
            );
          }
        }
      } else if (_analyticsService != null) {
        // Fallback: emit single event with all changes if we can't compare
        _analyticsService.trackEvent(
          PrivacySettingsChangedEvent(
            userId: event.userId,
            changedSettings: event.settingsData,
          ),
        );
      }

      emit(PrivacySettingsUpdated(settings: updatedSettings));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to update privacy settings: $e',
        errorCode: 'PRIVACY_UPDATE_ERROR',
      ));
    }
  }

  Future<void> _onNotificationPreferencesLoadRequested(
    NotificationPreferencesLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final prefs =
          await _profileRepository.getNotificationPreferences(event.userId);
      emit(NotificationPreferencesUpdated(preferences: prefs));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to load notification preferences: $e',
        errorCode: 'NOTIFICATION_LOAD_ERROR',
      ));
    }
  }

  Future<void> _onNotificationPreferencesUpdateRequested(
    NotificationPreferencesUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final updatedPrefs =
          await _profileRepository.updateNotificationPreferences(
        event.userId,
        event.prefsData,
      );

      // AC5: Emit analytics event with channel + frequency metadata
      final analyticsData = <String, dynamic>{
        'emailNotifications': event.prefsData['emailNotifications'],
        'pushNotifications': event.prefsData['pushNotifications'],
        'inAppNotifications': event.prefsData['inAppNotifications'],
      };

      // Include channel metadata if provided
      if (event.prefsData.containsKey('channelMetadata')) {
        analyticsData['channelMetadata'] = event.prefsData['channelMetadata'];
      }

      // Include quiet hours info
      if (event.prefsData.containsKey('quietHours')) {
        try {
          final quietHours =
              json.decode(event.prefsData['quietHours'] as String)
                  as Map<String, dynamic>;
          analyticsData['quietHours'] = {
            'enabled': quietHours['enabled'],
            'start': quietHours['start'],
            'end': quietHours['end'],
          };
        } catch (_) {
          // Ignore parsing errors
        }
      }

      _analyticsService?.trackEvent(
        NotificationPreferencesUpdatedEvent(
          userId: event.userId,
          changedPreferences: analyticsData,
        ),
      );

      emit(NotificationPreferencesUpdated(preferences: updatedPrefs));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to update notification preferences: $e',
        errorCode: 'NOTIFICATION_UPDATE_ERROR',
      ));
    }
  }

  Future<void> _onExportUserDataRequested(
    ExportUserDataRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final exportData = await _profileRepository.exportUserData(event.userId);

      // Emit analytics event for DSAR export
      _analyticsService?.trackEvent(
        DsarOperationEvent(
          userId: event.userId,
          operationType: 'export',
        ),
      );

      emit(UserDataExported(exportData: exportData));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to export user data: $e',
        errorCode: 'EXPORT_ERROR',
      ));
    }
  }

  Future<void> _onDeleteUserDataRequested(
    DeleteUserDataRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.deleteUserData(event.userId);

      // Emit analytics event for DSAR deletion
      _analyticsService?.trackEvent(
        DsarOperationEvent(
          userId: event.userId,
          operationType: 'delete',
        ),
      );

      emit(const UserDataDeleted());
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to delete user data: $e',
        errorCode: 'DELETE_ERROR',
      ));
    }
  }

  /// Handle DSAR export request (Story 3-5)
  /// AC2: DSAR export generates downloadable package within 24 hours and surfaces status/progress in UI with polling
  Future<void> _onDSARExportRequested(
    DSARExportRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Request DSAR export - this initiates async processing
      final result = await _profileRepository.requestDSARExport(event.userId);
      final exportId = result['exportId'] as String? ?? '';

      // Emit analytics event for DSAR export request
      _analyticsService?.trackEvent(
        DsarOperationEvent(
          userId: event.userId,
          operationType: 'export_requested',
        ),
      );

      // Emit in-progress state to trigger polling
      emit(DSARExportInProgress(
        exportId: exportId,
        statusMessage: 'Preparing your data export...',
        estimatedCompletionAt: DateTime.now().add(const Duration(hours: 24)),
      ));

      // Poll for completion (this will be handled by DSARExportPollingCubit)
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to request DSAR export: $e',
        errorCode: 'DSAR_EXPORT_ERROR',
      ));
    }
  }

  /// Handle account deletion request (Story 3-5)
  /// AC3: Account deletion workflow anonymizes profile, revokes tokens, deletes media, and queues background cleanup
  Future<void> _onAccountDeletionRequested(
    AccountDeletionRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.deleteAccount(event.userId);

      // Emit analytics event for account deletion
      _analyticsService?.trackEvent(
        DsarOperationEvent(
          userId: event.userId,
          operationType: 'account_deletion',
        ),
      );

      emit(const AccountDeletionCompleted());
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to delete account: $e',
        errorCode: 'ACCOUNT_DELETION_ERROR',
      ));
    }
  }

  /// Handle revoke all sessions request (Story 3-5)
  /// AC1: Account settings tab offers session revocation
  Future<void> _onRevokeAllSessionsRequested(
    RevokeAllSessionsRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.revokeAllSessions(event.userId);

      emit(const SessionsRevoked());
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to revoke sessions: $e',
        errorCode: 'SESSION_REVOCATION_ERROR',
      ));
    }
  }

  /// Handle avatar upload request (Story 3-2)
  /// AC1: Presigned upload flow with chunked transfer
  /// AC4: Upload UI provides progress indicator
  Future<void> _onAvatarUploadRequested(
    AvatarUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (_mediaRepository == null) {
      emit(const ProfileError(
        message: 'Media repository not available',
        errorCode: 'MEDIA_REPO_ERROR',
      ));
      return;
    }

    try {
      final startTime = DateTime.now();
      emit(const AvatarUploading(0.0));

      // Get file metadata
      final file = event.imageFile;
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      // Get presigned upload URL
      final uploadUrlData = await _mediaRepository.getAvatarUploadUrl(
        userId: event.userId,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSize,
      );

      final presignedUrl = uploadUrlData['presignedUrl'] as String;
      final mediaId = uploadUrlData['mediaId'] as int;

      // Upload file with progress tracking
      await _mediaRepository.uploadToS3(
        presignedUrl: presignedUrl,
        file: file,
        onProgress: (progress) {
          add(AvatarUploadProgressed(event.userId, progress));
        },
      );

      // Poll for virus scan completion
      await _mediaRepository.pollVirusScanStatus(mediaId: mediaId);

      // Reload profile to get updated avatar URL
      final profile = await _profileRepository.getMyProfile(event.userId);
      final avatarUrl = profile?['avatarUrl'] as String?;

      if (avatarUrl == null) {
        throw Exception('Avatar URL not found after upload');
      }

      // Emit analytics event
      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;
      _analyticsService?.trackEvent(
        AvatarUploadedEvent(
          userId: event.userId,
          fileSizeBytes: fileSize,
          mimeType: mimeType,
          processingTimeMs: processingTime,
        ),
      );

      emit(AvatarUploadCompleted(avatarUrl));
    } catch (e) {
      emit(ProfileError(
        message: 'Failed to upload avatar: $e',
        errorCode: 'AVATAR_UPLOAD_ERROR',
      ));
    }
  }

  /// Handle avatar upload progress (Story 3-2)
  /// AC4: Upload UI provides progress indicator
  void _onAvatarUploadProgressed(
    AvatarUploadProgressed event,
    Emitter<ProfileState> emit,
  ) {
    emit(AvatarUploading(event.progress));
  }

  /// Get MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
