import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:core/services/analytics_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../analytics/profile_analytics_events.dart';

/// BLoC for managing profile state
/// Implements Story 3-1: Viewer Profile Management
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final AnalyticsService? _analyticsService;

  ProfileBloc(
    this._profileRepository, {
    AnalyticsService? analyticsService,
  })  : _analyticsService = analyticsService,
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
}
