part of 'profile_bloc.dart';

import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/social_link_model.dart';
import '../../domain/models/privacy_setting_model.dart';
import '../../domain/models/notification_preference_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;

  const LoadProfile({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final String? displayName;
  final String? bio;
  final String? website;
  final String? location;
  final DateTime? birthDate;
  final ProfileVisibility? visibility;

  const UpdateProfile({
    this.displayName,
    this.bio,
    this.website,
    this.location,
    this.birthDate,
    this.visibility,
  });

  @override
  List<Object> get props => [
        displayName ?? '',
        bio ?? '',
        website ?? '',
        location ?? '',
        birthDate ?? '',
        visibility ?? ProfileVisibility.public,
      ];
}

class UploadProfileImage extends ProfileEvent {
  final String filePath;
  final String mimeType;
  final ProfileImageType type;

  const UploadProfileImage({
    required this.filePath,
    required this.mimeType,
    required this.type,
  });

  @override
  List<Object> get props => [filePath, mimeType, type];
}

class RemoveProfileImage extends ProfileEvent {
  final ProfileImageType type;

  const RemoveProfileImage({required this.type});

  @override
  List<Object> get props => [type];
}

class AddSocialLink extends ProfileEvent {
  final SocialPlatform platform;
  final String url;
  final String? username;

  const AddSocialLink({
    required this.platform,
    required this.url,
    this.username,
  });

  @override
  List<Object> get props => [platform, url, username ?? ''];
}

class UpdateSocialLink extends ProfileEvent {
  final String linkId;
  final SocialPlatform platform;
  final String url;
  final String? username;

  const UpdateSocialLink({
    required this.linkId,
    required this.platform,
    required this.url,
    this.username,
  });

  @override
  List<Object> get props => [linkId, platform, url, username ?? ''];
}

class DeleteSocialLink extends ProfileEvent {
  final String linkId;

  const DeleteSocialLink({required this.linkId});

  @override
  List<Object> get props => [linkId];
}

class ReorderSocialLinks extends ProfileEvent {
  final List<String> linkIds;

  const ReorderSocialLinks({required this.linkIds});

  @override
  List<Object> get props => [linkIds];
}

class LoadPrivacySettings extends ProfileEvent {
  final String userId;

  const LoadPrivacySettings({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdatePrivacySettings extends ProfileEvent {
  final ProfileVisibility? profileVisibility;
  final DataSharingSettings? dataSharing;
  final SearchVisibility? searchVisibility;
  final MessageSettings? messageSettings;
  final ActivitySettings? activitySettings;

  const UpdatePrivacySettings({
    this.profileVisibility,
    this.dataSharing,
    this.searchVisibility,
    this.messageSettings,
    this.activitySettings,
  });

  @override
  List<Object> get props => [
        profileVisibility ?? ProfileVisibility.public,
        dataSharing ?? const DataSharingSettings(),
        searchVisibility ?? SearchVisibility.everyone,
        messageSettings ?? const MessageSettings(),
        activitySettings ?? const ActivitySettings(),
      ];
}

class LoadNotificationPreferences extends ProfileEvent {
  final String userId;

  const LoadNotificationPreferences({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdateNotificationPreference extends ProfileEvent {
  final NotificationType type;
  final bool? enabled;
  final DeliveryMethod? deliveryMethod;
  final bool? quietHoursEnabled;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final int? frequency;

  const UpdateNotificationPreference({
    required this.type,
    this.enabled,
    this.deliveryMethod,
    this.quietHoursEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.frequency,
  });

  @override
  List<Object> get props => [
        type,
        enabled ?? false,
        deliveryMethod ?? DeliveryMethod.push,
        quietHoursEnabled ?? false,
        quietHoursStart ?? '',
        quietHoursEnd ?? '',
        frequency ?? 1,
      ];
}

class ExportProfileData extends ProfileEvent {
  final DataExportFormat format;

  const ExportProfileData({required this.format});

  @override
  List<Object> get props => [format];
}

class DeleteAccount extends ProfileEvent {
  final String password;

  const DeleteAccount({required this.password});

  @override
  List<Object> get props => [password];
}

class ChangePassword extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

enum ProfileImageType {
  profilePhoto,
  coverImage,
}

enum DataExportFormat {
  json,
  csv,
  pdf,
}