import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../domain/models/privacy_setting_model.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  bool _isLoading = false;
  PrivacySettingModel? _currentSettings;

  ProfileVisibility _selectedVisibility = ProfileVisibility.public;
  SearchVisibility _selectedSearchVisibility = SearchVisibility.everyone;
  bool _shareProfileWithPartners = false;
  bool _shareActivityWithFriends = true;
  bool _shareLocationData = false;
  bool _allowDataAnalytics = true;
  bool _allowPersonalizedAds = false;
  bool _allowMessagesFromEveryone = false;
  bool _allowMessagesFromFriends = true;
  bool _allowMessagesFromFollowers = true;
  bool _allowMessageRequests = true;
  bool _showOnlineStatus = true;
  bool _showActivityStatus = true;
  bool _showLastSeen = true;
  bool _allowReadReceipts = true;
  bool _allowTypingIndicators = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    if (_currentUserId != null) {
      context.read<ProfileBloc>().add(LoadPrivacySettings(userId: _currentUserId!));
    }
  }

  String? get _currentUserId {
    // This should come from user authentication context
    // For now, we'll get it from the current profile state
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      return state.profile.userId;
    }
    return null;
  }

  void _updateSettingsFromModel(PrivacySettingModel settings) {
    setState(() {
      _currentSettings = settings;
      _selectedVisibility = settings.profileVisibility;
      _selectedSearchVisibility = settings.searchVisibility;
      _shareProfileWithPartners = settings.dataSharing.shareProfileWithPartners;
      _shareActivityWithFriends = settings.dataSharing.shareActivityWithFriends;
      _shareLocationData = settings.dataSharing.shareLocationData;
      _allowDataAnalytics = settings.dataSharing.allowDataAnalytics;
      _allowPersonalizedAds = settings.dataSharing.allowPersonalizedAds;
      _allowMessagesFromEveryone = settings.messageSettings.allowMessagesFromEveryone;
      _allowMessagesFromFriends = settings.messageSettings.allowMessagesFromFriends;
      _allowMessagesFromFollowers = settings.messageSettings.allowMessagesFromFollowers;
      _allowMessageRequests = settings.messageSettings.allowMessageRequests;
      _showOnlineStatus = settings.activitySettings.showOnlineStatus;
      _showActivityStatus = settings.activitySettings.showActivityStatus;
      _showLastSeen = settings.activitySettings.showLastSeen;
      _allowReadReceipts = settings.activitySettings.allowReadReceipts;
      _allowTypingIndicators = settings.activitySettings.allowTypingIndicators;
    });
  }

  Future<void> _savePrivacySettings() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    final dataSharing = DataSharingSettings(
      shareProfileWithPartners: _shareProfileWithPartners,
      shareActivityWithFriends: _shareActivityWithFriends,
      shareLocationData: _shareLocationData,
      allowDataAnalytics: _allowDataAnalytics,
      allowPersonalizedAds: _allowPersonalizedAds,
    );

    final messageSettings = MessageSettings(
      allowMessagesFromEveryone: _allowMessagesFromEveryone,
      allowMessagesFromFriends: _allowMessagesFromFriends,
      allowMessagesFromFollowers: _allowMessagesFromFollowers,
      allowMessageRequests: _allowMessageRequests,
    );

    final activitySettings = ActivitySettings(
      showOnlineStatus: _showOnlineStatus,
      showActivityStatus: _showActivityStatus,
      showLastSeen: _showLastSeen,
      allowReadReceipts: _allowReadReceipts,
      allowTypingIndicators: _allowTypingIndicators,
    );

    context.read<ProfileBloc>().add(
      UpdatePrivacySettings(
        profileVisibility: _selectedVisibility,
        dataSharing: dataSharing,
        searchVisibility: _selectedSearchVisibility,
        messageSettings: messageSettings,
        activitySettings: activitySettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is PrivacySettingsUpdated) {
          setState(() => _isLoading = false);
          _updateSettingsFromModel(state.settings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy settings updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProfileError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ProfileLoaded && state.privacySettings != null) {
          _updateSettingsFromModel(state.privacySettings!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Settings'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _savePrivacySettings,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Visibility Section
              _buildSectionTitle('Profile Visibility'),
              _buildVisibilitySettings(),
              const SizedBox(height: 24),

              // Search Visibility Section
              _buildSectionTitle('Search Visibility'),
              _buildSearchVisibilitySettings(),
              const SizedBox(height: 24),

              // Data Sharing Section
              _buildSectionTitle('Data Sharing'),
              _buildDataSharingSettings(),
              const SizedBox(height: 24),

              // Message Settings Section
              _buildSectionTitle('Message Settings'),
              _buildMessageSettings(),
              const SizedBox(height: 24),

              // Activity Settings Section
              _buildSectionTitle('Activity Settings'),
              _buildActivitySettings(),
              const SizedBox(height: 24),

              // Account Actions Section
              _buildSectionTitle('Account Actions'),
              _buildAccountActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildVisibilitySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who can see your profile?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...ProfileVisibility.values.map((visibility) {
              return RadioListTile<ProfileVisibility>(
                title: Text(_getVisibilityText(visibility)),
                subtitle: Text(_getVisibilityDescription(visibility)),
                value: visibility,
                groupValue: _selectedVisibility,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedVisibility = value);
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchVisibilitySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who can find you in search?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...SearchVisibility.values.map((visibility) {
              return RadioListTile<SearchVisibility>(
                title: Text(_getSearchVisibilityText(visibility)),
                subtitle: Text(_getSearchVisibilityDescription(visibility)),
                value: visibility,
                groupValue: _selectedSearchVisibility,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSearchVisibility = value);
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Sharing Preferences',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Share profile with partners',
              subtitle: 'Allow partners to access your profile information',
              value: _shareProfileWithPartners,
              onChanged: (value) => setState(() => _shareProfileWithPartners = value),
            ),
            _buildSwitchTile(
              title: 'Share activity with friends',
              subtitle: 'Let friends see your activity status',
              value: _shareActivityWithFriends,
              onChanged: (value) => setState(() => _shareActivityWithFriends = value),
            ),
            _buildSwitchTile(
              title: 'Share location data',
              subtitle: 'Share your location for personalized experiences',
              value: _shareLocationData,
              onChanged: (value) => setState(() => _shareLocationData = value),
            ),
            _buildSwitchTile(
              title: 'Allow data analytics',
              subtitle: 'Help us improve by sharing usage data',
              value: _allowDataAnalytics,
              onChanged: (value) => setState(() => _allowDataAnalytics = value),
            ),
            _buildSwitchTile(
              title: 'Allow personalized ads',
              subtitle: 'Show ads based on your interests',
              value: _allowPersonalizedAds,
              onChanged: (value) => setState(() => _allowPersonalizedAds = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message Privacy',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Messages from everyone',
              subtitle: 'Allow anyone to send you messages',
              value: _allowMessagesFromEveryone,
              onChanged: (value) => setState(() => _allowMessagesFromEveryone = value),
            ),
            _buildSwitchTile(
              title: 'Messages from friends',
              subtitle: 'Allow friends to send you messages',
              value: _allowMessagesFromFriends,
              onChanged: (value) => setState(() => _allowMessagesFromFriends = value),
            ),
            _buildSwitchTile(
              title: 'Messages from followers',
              subtitle: 'Allow followers to send you messages',
              value: _allowMessagesFromFollowers,
              onChanged: (value) => setState(() => _allowMessagesFromFollowers = value),
            ),
            _buildSwitchTile(
              title: 'Message requests',
              subtitle: 'Allow message requests from people you don\'t know',
              value: _allowMessageRequests,
              onChanged: (value) => setState(() => _allowMessageRequests = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Show online status',
              subtitle: 'Let others see when you\'re online',
              value: _showOnlineStatus,
              onChanged: (value) => setState(() => _showOnlineStatus = value),
            ),
            _buildSwitchTile(
              title: 'Show activity status',
              subtitle: 'Share your current activity',
              value: _showActivityStatus,
              onChanged: (value) => setState(() => _showActivityStatus = value),
            ),
            _buildSwitchTile(
              title: 'Show last seen',
              subtitle: 'Show when you were last active',
              value: _showLastSeen,
              onChanged: (value) => setState(() => _showLastSeen = value),
            ),
            _buildSwitchTile(
              title: 'Read receipts',
              subtitle: 'Let others know when you\'ve read their messages',
              value: _allowReadReceipts,
              onChanged: (value) => setState(() => _allowReadReceipts = value),
            ),
            _buildSwitchTile(
              title: 'Typing indicators',
              subtitle: 'Show when you\'re typing a message',
              value: _allowTypingIndicators,
              onChanged: (value) => setState(() => _allowTypingIndicators = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Management',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export My Data'),
              subtitle: const Text('Download all your account data'),
              onTap: _exportData,
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Blocked Users'),
              subtitle: const Text('Manage users you\'ve blocked'),
              onTap: _manageBlockedUsers,
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy Compliance'),
              subtitle: const Text('View privacy rights and compliance info'),
              onTap: _showPrivacyCompliance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  String _getVisibilityText(ProfileVisibility visibility) {
    switch (visibility) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.private:
        return 'Private';
      case ProfileVisibility.friendsOnly:
        return 'Friends Only';
    }
  }

  String _getVisibilityDescription(ProfileVisibility visibility) {
    switch (visibility) {
      case ProfileVisibility.public:
        return 'Anyone can view your profile';
      case ProfileVisibility.private:
        return 'Only you can view your profile';
      case ProfileVisibility.friendsOnly:
        return 'Only your friends can view your profile';
    }
  }

  String _getSearchVisibilityText(SearchVisibility visibility) {
    switch (visibility) {
      case SearchVisibility.everyone:
        return 'Everyone';
      case SearchVisibility.friendsOnly:
        return 'Friends Only';
      case SearchVisibility.none:
        return 'No One';
    }
  }

  String _getSearchVisibilityDescription(SearchVisibility visibility) {
    switch (visibility) {
      case SearchVisibility.everyone:
        return 'Anyone can find you in search results';
      case SearchVisibility.friendsOnly:
        return 'Only your friends can find you in search';
      case SearchVisibility.none:
        return 'You cannot be found in search results';
    }
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Your Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the format for your data export:'),
            const SizedBox(height: 16),
            ...DataExportFormat.values.map((format) {
              return ListTile(
                title: Text(format.name.toUpperCase()),
                onTap: () {
                  Navigator.pop(context);
                  if (_currentUserId != null) {
                    context.read<ProfileBloc>().add(ExportProfileData(format: format));
                  }
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageBlockedUsers() async {
    // This would open a blocked users management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Blocked users management coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showPrivacyCompliance() async {
    // This would open privacy compliance information
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy compliance information coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}