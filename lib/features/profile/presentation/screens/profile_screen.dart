import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/profile_media.dart';
import '../../domain/models/social_link.dart';
import '../../domain/models/privacy_setting.dart';
import '../../domain/models/notification_preference.dart';
import '../../data/repositories/profile_repository.dart';
import '../widgets/profile_editor.dart';
import '../widgets/profile_image_uploader.dart';
import '../widgets/social_links_manager.dart';
import '../widgets/privacy_settings.dart';
import '../widgets/notification_preferences.dart';
import '../widgets/account_data_manager.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repository = ProfileRepository();
  UserProfile? _profile;
  ProfileMedia? _profilePhoto;
  ProfileMedia? _coverImage;
  List<SocialLink> _socialLinks = [];
  PrivacySetting? _privacySettings;
  List<NotificationPreference> _notificationPreferences = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all profile data in parallel
      final results = await Future.wait([
        _repository.getUserProfile(widget.userId),
        _repository.getProfileMedia(widget.userId, ProfileMediaType.photo),
        _repository.getProfileMedia(widget.userId, ProfileMediaType.cover),
        _repository.getSocialLinks(widget.userId),
        _repository.getPrivacySettings(widget.userId),
        _repository.getNotificationPreferences(widget.userId),
      ]);

      setState(() {
        _profile = results[0] as UserProfile?;
        _profilePhoto = results[1] as ProfileMedia?;
        _coverImage = results[2] as ProfileMedia?;
        _socialLinks = results[3] as List<SocialLink>;
        _privacySettings = results[4] as PrivacySetting?;
        _notificationPreferences = results[5] as List<NotificationPreference>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onProfileUpdated(UserProfile updatedProfile) {
    setState(() {
      _profile = updatedProfile;
    });
  }

  void _onProfilePhotoUploaded(ProfileMedia media) {
    setState(() {
      _profilePhoto = media;
    });
  }

  void _onCoverImageUploaded(ProfileMedia media) {
    setState(() {
      _coverImage = media;
    });
  }

  void _onSocialLinksUpdated(List<SocialLink> links) {
    setState(() {
      _socialLinks = links;
    });
  }

  void _onPrivacySettingsUpdated(PrivacySetting settings) {
    setState(() {
      _privacySettings = settings;
    });
  }

  void _onNotificationPreferencesUpdated(List<NotificationPreference> preferences) {
    setState(() {
      _notificationPreferences = preferences;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(
                      child: Text('Profile not found'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Cover Image and Profile Photo
                          _buildProfileHeader(),

                          // Profile Information
                          _buildProfileInfo(),

                          // Edit Profile Button
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileEditor(
                                        initialProfile: _profile!,
                                        onSave: _onProfileUpdated,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ),

                          // Image Management
                          ProfileImageUploader(
                            userId: widget.userId,
                            mediaType: ProfileMediaType.photo,
                            currentImageUrl: _profilePhoto?.mediaUrl,
                            onUploadComplete: _onProfilePhotoUploaded,
                          ),

                          const SizedBox(height: 16),

                          ProfileImageUploader(
                            userId: widget.userId,
                            mediaType: ProfileMediaType.cover,
                            currentImageUrl: _coverImage?.mediaUrl,
                            onUploadComplete: _onCoverImageUploaded,
                          ),

                          // Social Links
                          if (_privacySettings?.profileVisibility == ProfileVisibility.public)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SocialLinksManager(
                                userId: widget.userId,
                                initialLinks: _socialLinks,
                                onLinksUpdated: _onSocialLinksUpdated,
                              ),
                            ),

                          // Privacy Settings
                          if (_privacySettings != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: PrivacySettings(
                                initialSettings: _privacySettings!,
                                onSettingsUpdated: _onPrivacySettingsUpdated,
                              ),
                            ),

                          // Notification Preferences
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: NotificationPreferences(
                              userId: widget.userId,
                              initialPreferences: _notificationPreferences,
                              onPreferencesUpdated: _onNotificationPreferencesUpdated,
                            ),
                          ),

                          // Account Data Management
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: AccountDataManager(
                              userId: widget.userId,
                              onAccountDeleted: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      children: [
        // Cover Image
        if (_coverImage != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_coverImage!.mediaUrl),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),

        // Profile Photo
        Positioned(
          bottom: -50,
          left: 16,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  image: _profilePhoto != null
                      ? DecorationImage(
                          image: NetworkImage(_profilePhoto!.mediaUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey.shade300,
                ),
                child: _profilePhoto == null
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profile!.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _profile!.bio!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
          if (_profile!.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _profile!.location!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
          if (_profile!.website != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _profile!.website!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}