import 'package:equatable/equatable.dart';

/// Events for profile management
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load profile data
class ProfileLoadRequested extends ProfileEvent {
  final int userId;

  const ProfileLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update profile
class ProfileUpdateRequested extends ProfileEvent {
  final int userId;
  final Map<String, dynamic> profileData;

  const ProfileUpdateRequested(this.userId, this.profileData);

  @override
  List<Object?> get props => [userId, profileData];
}

/// Load privacy settings
class PrivacySettingsLoadRequested extends ProfileEvent {
  final int userId;

  const PrivacySettingsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update privacy settings
class PrivacySettingsUpdateRequested extends ProfileEvent {
  final int userId;
  final Map<String, dynamic> settingsData;

  const PrivacySettingsUpdateRequested(this.userId, this.settingsData);

  @override
  List<Object?> get props => [userId, settingsData];
}

/// Load notification preferences
class NotificationPreferencesLoadRequested extends ProfileEvent {
  final int userId;

  const NotificationPreferencesLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update notification preferences
class NotificationPreferencesUpdateRequested extends ProfileEvent {
  final int userId;
  final Map<String, dynamic> prefsData;

  const NotificationPreferencesUpdateRequested(this.userId, this.prefsData);

  @override
  List<Object?> get props => [userId, prefsData];
}

/// Export user data (DSAR)
class ExportUserDataRequested extends ProfileEvent {
  final int userId;

  const ExportUserDataRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Delete user data (DSAR)
class DeleteUserDataRequested extends ProfileEvent {
  final int userId;

  const DeleteUserDataRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
