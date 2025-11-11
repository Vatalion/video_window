import 'package:equatable/equatable.dart';

/// States for profile management
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded state
class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;
  final Map<String, dynamic>? privacySettings;
  final Map<String, dynamic>? notificationPreferences;

  const ProfileLoaded({
    required this.profile,
    this.privacySettings,
    this.notificationPreferences,
  });

  @override
  List<Object?> get props =>
      [profile, privacySettings, notificationPreferences];
}

/// Profile updated state
class ProfileUpdated extends ProfileState {
  final Map<String, dynamic> profile;

  const ProfileUpdated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Privacy settings updated state
class PrivacySettingsUpdated extends ProfileState {
  final Map<String, dynamic> settings;

  const PrivacySettingsUpdated({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// Notification preferences updated state
class NotificationPreferencesUpdated extends ProfileState {
  final Map<String, dynamic> preferences;

  const NotificationPreferencesUpdated({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

/// User data exported state (DSAR)
class UserDataExported extends ProfileState {
  final Map<String, dynamic> exportData;

  const UserDataExported({required this.exportData});

  @override
  List<Object?> get props => [exportData];
}

/// User data deleted state (DSAR)
class UserDataDeleted extends ProfileState {
  const UserDataDeleted();
}

/// Error state
class ProfileError extends ProfileState {
  final String message;
  final String? errorCode;

  const ProfileError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// Avatar upload in progress state (Story 3-2)
class AvatarUploading extends ProfileState {
  final double progress;

  const AvatarUploading(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Avatar upload completed state (Story 3-2)
class AvatarUploadCompleted extends ProfileState {
  final String avatarUrl;

  const AvatarUploadCompleted(this.avatarUrl);

  @override
  List<Object?> get props => [avatarUrl];
}

/// DSAR export in progress state (Story 3-5)
class DSARExportInProgress extends ProfileState {
  final String exportId;
  final String? statusMessage;
  final DateTime? estimatedCompletionAt;

  const DSARExportInProgress({
    required this.exportId,
    this.statusMessage,
    this.estimatedCompletionAt,
  });

  @override
  List<Object?> get props => [exportId, statusMessage, estimatedCompletionAt];
}

/// DSAR export completed state (Story 3-5)
class DSARExportCompleted extends ProfileState {
  final String? downloadUrl;
  final DateTime? expiresAt;

  const DSARExportCompleted({
    this.downloadUrl,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [downloadUrl, expiresAt];
}

/// Account deletion completed state (Story 3-5)
class AccountDeletionCompleted extends ProfileState {
  const AccountDeletionCompleted();
}

/// Sessions revoked state (Story 3-5)
class SessionsRevoked extends ProfileState {
  const SessionsRevoked();
}
