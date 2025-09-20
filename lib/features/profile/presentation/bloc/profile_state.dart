part of 'profile_bloc.dart';

import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/social_link_model.dart';
import '../../domain/models/privacy_setting_model.dart';
import '../../domain/models/notification_preference_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserProfileModel profile;
  final List<SocialLinkModel> socialLinks;
  final PrivacySettingModel? privacySettings;
  final NotificationSettings? notificationSettings;

  const ProfileLoaded({
    required this.profile,
    required this.socialLinks,
    this.privacySettings,
    this.notificationSettings,
  });

  @override
  List<Object> get props => [
        profile,
        socialLinks,
        privacySettings ?? '',
        notificationSettings ?? '',
      ];

  ProfileLoaded copyWith({
    UserProfileModel? profile,
    List<SocialLinkModel>? socialLinks,
    PrivacySettingModel? privacySettings,
    NotificationSettings? notificationSettings,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      socialLinks: socialLinks ?? this.socialLinks,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }
}

class ProfileUpdated extends ProfileState {
  final UserProfileModel profile;

  const ProfileUpdated({required this.profile});

  @override
  List<Object> get props => [profile];
}

class ProfileImageUploaded extends ProfileState {
  final String imageUrl;
  final ProfileImageType type;

  const ProfileImageUploaded({
    required this.imageUrl,
    required this.type,
  });

  @override
  List<Object> get props => [imageUrl, type];
}

class ProfileImageRemoved extends ProfileState {
  final ProfileImageType type;

  const ProfileImageRemoved({required this.type});

  @override
  List<Object> get props => [type];
}

class SocialLinksUpdated extends ProfileState {
  final List<SocialLinkModel> socialLinks;

  const SocialLinksUpdated({required this.socialLinks});

  @override
  List<Object> get props => [socialLinks];
}

class PrivacySettingsUpdated extends ProfileState {
  final PrivacySettingModel settings;

  const PrivacySettingsUpdated({required this.settings});

  @override
  List<Object> get props => [settings];
}

class NotificationPreferencesUpdated extends ProfileState {
  final NotificationSettings settings;

  const NotificationPreferencesUpdated({required this.settings});

  @override
  List<Object> get props => [settings];
}

class ProfileDataExported extends ProfileState {
  final String downloadUrl;
  final DataExportFormat format;

  const ProfileDataExported({
    required this.downloadUrl,
    required this.format,
  });

  @override
  List<Object> get props => [downloadUrl, format];
}

class AccountDeleted extends ProfileState {
  const AccountDeleted();
}

class PasswordChanged extends ProfileState {
  const PasswordChanged();
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}