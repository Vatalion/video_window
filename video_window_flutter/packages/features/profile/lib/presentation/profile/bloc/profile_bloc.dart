import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:core/data/repositories/profile/profile_media_repository.dart';
import 'package:core/services/analytics_service.dart';
import 'dart:io';
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
      final updatedSettings = await _profileRepository.updatePrivacySettings(
        event.userId,
        event.settingsData,
      );

      // Emit analytics event for privacy settings change
      _analyticsService?.trackEvent(
        PrivacySettingsChangedEvent(
          userId: event.userId,
          changedSettings: event.settingsData,
        ),
      );

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

      // Emit analytics event for notification preferences change
      _analyticsService?.trackEvent(
        NotificationPreferencesUpdatedEvent(
          userId: event.userId,
          changedPreferences: event.prefsData,
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
      final uploadUrlData = await _mediaRepository!.getAvatarUploadUrl(
        userId: event.userId,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSize,
      );

      final presignedUrl = uploadUrlData['presignedUrl'] as String;
      final mediaId = uploadUrlData['mediaId'] as int;

      // Upload file with progress tracking
      await _mediaRepository!.uploadToS3(
        presignedUrl: presignedUrl,
        file: file,
        onProgress: (progress) {
          add(AvatarUploadProgressed(event.userId, progress));
        },
      );

      // Poll for virus scan completion
      await _mediaRepository!.pollVirusScanStatus(mediaId: mediaId);

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
