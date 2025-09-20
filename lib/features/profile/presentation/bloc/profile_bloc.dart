import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/privacy_service.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/social_link_model.dart';
import '../../domain/models/privacy_setting_model.dart';
import '../../domain/models/notification_preference_model.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;
  final PrivacyService _privacyService;
  final NotificationService _notificationService;
  String? _currentUserId;

  ProfileBloc({
    required ProfileService profileService,
    required PrivacyService privacyService,
    required NotificationService notificationService,
  })  : _profileService = profileService,
        _privacyService = privacyService,
        _notificationService = notificationService,
        super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<RemoveProfileImage>(_onRemoveProfileImage);
    on<AddSocialLink>(_onAddSocialLink);
    on<UpdateSocialLink>(_onUpdateSocialLink);
    on<DeleteSocialLink>(_onDeleteSocialLink);
    on<ReorderSocialLinks>(_onReorderSocialLinks);
    on<LoadPrivacySettings>(_onLoadPrivacySettings);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
    on<LoadNotificationPreferences>(_onLoadNotificationPreferences);
    on<UpdateNotificationPreference>(_onUpdateNotificationPreference);
    on<ExportProfileData>(_onExportProfileData);
    on<DeleteAccount>(_onDeleteAccount);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      _currentUserId = event.userId;
      final profile = await _profileService.getUserProfile(event.userId);
      final socialLinks = await _profileService.getSocialLinks(event.userId);

      emit(ProfileLoaded(
        profile: profile,
        socialLinks: socialLinks,
      ));
    } catch (e) {
      emit(ProfileError(message: 'Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final updatedProfile = await _profileService.updateProfile(
        userId: _currentUserId!,
        displayName: event.displayName,
        bio: event.bio,
        website: event.website,
        location: event.location,
        birthDate: event.birthDate,
        visibility: event.visibility,
      );

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(currentState.copyWith(profile: updatedProfile));
      }

      emit(ProfileUpdated(profile: updatedProfile));
    } catch (e) {
      emit(ProfileError(message: 'Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _onUploadProfileImage(UploadProfileImage event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      String imageUrl;
      if (event.type == ProfileImageType.profilePhoto) {
        imageUrl = await _profileService.uploadProfilePhoto(
          userId: _currentUserId!,
          filePath: event.filePath,
          mimeType: event.mimeType,
        );
      } else {
        imageUrl = await _profileService.uploadCoverImage(
          userId: _currentUserId!,
          filePath: event.filePath,
          mimeType: event.mimeType,
        );
      }

      emit(ProfileImageUploaded(imageUrl: imageUrl, type: event.type));
    } catch (e) {
      emit(ProfileError(message: 'Failed to upload image: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveProfileImage(RemoveProfileImage event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      await _profileService.deleteProfileMedia(
        userId: _currentUserId!,
        mediaUrl: '', // Will be determined from current profile
        type: event.type == ProfileImageType.profilePhoto
            ? ProfileMediaType.profilePhoto
            : ProfileMediaType.coverPhoto,
      );

      emit(ProfileImageRemoved(type: event.type));
    } catch (e) {
      emit(ProfileError(message: 'Failed to remove image: ${e.toString()}'));
    }
  }

  Future<void> _onAddSocialLink(AddSocialLink event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final newLink = await _profileService.addSocialLink(
        userId: _currentUserId!,
        platform: event.platform,
        url: event.url,
        username: event.username,
      );

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        final updatedLinks = [...currentState.socialLinks, newLink];
        emit(currentState.copyWith(socialLinks: updatedLinks));
      }

      emit(SocialLinksUpdated(socialLinks: [newLink]));
    } catch (e) {
      emit(ProfileError(message: 'Failed to add social link: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSocialLink(UpdateSocialLink event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final updatedLink = await _profileService.updateSocialLink(
        linkId: event.linkId,
        userId: _currentUserId!,
        platform: event.platform,
        url: event.url,
        username: event.username,
      );

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        final updatedLinks = currentState.socialLinks
            .map((link) => link.id == event.linkId ? updatedLink : link)
            .toList();
        emit(currentState.copyWith(socialLinks: updatedLinks));
      }

      emit(SocialLinksUpdated(socialLinks: [updatedLink]));
    } catch (e) {
      emit(ProfileError(message: 'Failed to update social link: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteSocialLink(DeleteSocialLink event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      await _profileService.deleteSocialLink(event.linkId, _currentUserId!);

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        final updatedLinks = currentState.socialLinks
            .where((link) => link.id != event.linkId)
            .toList();
        emit(currentState.copyWith(socialLinks: updatedLinks));
      }

      emit(SocialLinksUpdated(socialLinks: []));
    } catch (e) {
      emit(ProfileError(message: 'Failed to delete social link: ${e.toString()}'));
    }
  }

  Future<void> _onReorderSocialLinks(ReorderSocialLinks event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      await _profileService.reorderSocialLinks(
        userId: _currentUserId!,
        linkIds: event.linkIds,
      );

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        final Map<String, SocialLinkModel> linkMap = {
          for (var link in currentState.socialLinks) link.id: link
        };

        final reorderedLinks = event.linkIds
            .map((id) => linkMap[id]!)
            .toList();

        emit(currentState.copyWith(socialLinks: reorderedLinks));
      }
    } catch (e) {
      emit(ProfileError(message: 'Failed to reorder social links: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPrivacySettings(LoadPrivacySettings event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final privacySettings = await _privacyService.getPrivacySettings(event.userId);

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(currentState.copyWith(privacySettings: privacySettings));
      }

      emit(PrivacySettingsUpdated(settings: privacySettings));
    } catch (e) {
      emit(ProfileError(message: 'Failed to load privacy settings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePrivacySettings(UpdatePrivacySettings event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final updatedSettings = await _privacyService.updatePrivacySettings(
        userId: _currentUserId!,
        profileVisibility: event.profileVisibility,
        dataSharing: event.dataSharing,
        searchVisibility: event.searchVisibility,
        messageSettings: event.messageSettings,
        activitySettings: event.activitySettings,
      );

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(currentState.copyWith(privacySettings: updatedSettings));
      }

      emit(PrivacySettingsUpdated(settings: updatedSettings));
    } catch (e) {
      emit(ProfileError(message: 'Failed to update privacy settings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadNotificationPreferences(LoadNotificationPreferences event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final notificationSettings = await _notificationService.getNotificationSettings(event.userId);

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(currentState.copyWith(notificationSettings: notificationSettings));
      }

      emit(NotificationPreferencesUpdated(settings: notificationSettings));
    } catch (e) {
      emit(ProfileError(message: 'Failed to load notification preferences: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotificationPreference(UpdateNotificationPreference event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final updatedPreference = await _notificationService.updateNotificationPreference(
        userId: _currentUserId!,
        type: event.type,
        enabled: event.enabled,
        deliveryMethod: event.deliveryMethod,
        quietHoursEnabled: event.quietHoursEnabled,
        quietHoursStart: event.quietHoursStart,
        quietHoursEnd: event.quietHoursEnd,
        frequency: event.frequency,
      );

      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        final currentSettings = currentState.notificationSettings;
        if (currentSettings != null) {
          final updatedPreferences = currentSettings.preferences
              .map((p) => p.type == event.type ? updatedPreference : p)
              .toList();

          final updatedSettings = NotificationSettings(
            preferences: updatedPreferences,
            globalEnabled: currentSettings.globalEnabled,
            soundEnabled: currentSettings.soundEnabled,
            vibrationEnabled: currentSettings.vibrationEnabled,
            ledEnabled: currentSettings.ledEnabled,
            badgeEnabled: currentSettings.badgeEnabled,
          );

          emit(currentState.copyWith(notificationSettings: updatedSettings));
        }
      }
    } catch (e) {
      emit(ProfileError(message: 'Failed to update notification preference: ${e.toString()}'));
    }
  }

  Future<void> _onExportProfileData(ExportProfileData event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      // Mock implementation - in real app, this would generate and store the file
      final downloadUrl = 'https://example.com/exports/profile_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.${event.format.name}';

      emit(ProfileDataExported(downloadUrl: downloadUrl, format: event.format));
    } catch (e) {
      emit(ProfileError(message: 'Failed to export profile data: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAccount(DeleteAccount event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      final success = await _profileService.deleteAccount(_currentUserId!, event.password);

      if (success) {
        emit(const AccountDeleted());
      } else {
        emit(const ProfileError(message: 'Failed to delete account'));
      }
    } catch (e) {
      emit(ProfileError(message: 'Failed to delete account: ${e.toString()}'));
    }
  }

  Future<void> _onChangePassword(ChangePassword event, Emitter<ProfileState> emit) async {
    if (_currentUserId == null) {
      emit(const ProfileError(message: 'No user loaded'));
      return;
    }

    try {
      // Mock implementation - in real app, this would call authentication service
      // For now, we'll just simulate success
      emit(const PasswordChanged());
    } catch (e) {
      emit(ProfileError(message: 'Failed to change password: ${e.toString()}'));
    }
  }
}