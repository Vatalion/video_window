import 'package:flutter/material.dart';
import '../../domain/models/privacy_setting.dart';
import '../../data/repositories/profile_repository.dart';

class PrivacySettings extends StatefulWidget {
  final PrivacySetting initialSettings;
  final Function(PrivacySetting) onSettingsUpdated;

  const PrivacySettings({
    super.key,
    required this.initialSettings,
    required this.onSettingsUpdated,
  });

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final ProfileRepository _repository = ProfileRepository();
  late PrivacySetting _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSettings = await _repository.updatePrivacySettings(_settings);
      setState(() {
        _settings = updatedSettings;
        _isLoading = false;
      });

      widget.onSettingsUpdated(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings updated')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            _buildProfileVisibilitySetting(),
            const SizedBox(height: 24),

            _buildDataSharingSetting(),
            const SizedBox(height: 24),

            _buildSearchVisibilitySetting(),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Visibility',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Control who can see your profile',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Column(
          children: ProfileVisibility.values.map((visibility) {
            return RadioListTile<ProfileVisibility>(
              title: Text(_getVisibilityLabel(visibility)),
              subtitle: Text(_getVisibilityDescription(visibility)),
              value: visibility,
              groupValue: _settings.profileVisibility,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _settings = _settings.copyWith(profileVisibility: value);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataSharingSetting() {
    return SwitchListTile(
      title: const Text('Allow Data Sharing'),
      subtitle: const Text('Share your data with trusted partners for better experience'),
      value: _settings.allowDataSharing,
      onChanged: (value) {
        setState(() {
          _settings = _settings.copyWith(allowDataSharing: value);
        });
      },
    );
  }

  Widget _buildSearchVisibilitySetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Visibility',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Control whether your profile appears in search results',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Column(
          children: SearchVisibility.values.map((visibility) {
            return RadioListTile<SearchVisibility>(
              title: Text(_getSearchVisibilityLabel(visibility)),
              subtitle: Text(_getSearchVisibilityDescription(visibility)),
              value: visibility,
              groupValue: _settings.searchVisibility,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _settings = _settings.copyWith(searchVisibility: value);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getVisibilityLabel(ProfileVisibility visibility) {
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
        return 'Only friends can view your profile';
    }
  }

  String _getSearchVisibilityLabel(SearchVisibility visibility) {
    switch (visibility) {
      case SearchVisibility.visible:
        return 'Visible in Search';
      case SearchVisibility.hidden:
        return 'Hidden from Search';
    }
  }

  String _getSearchVisibilityDescription(SearchVisibility visibility) {
    switch (visibility) {
      case SearchVisibility.visible:
        return 'Your profile can be found in search results';
      case SearchVisibility.hidden:
        return 'Your profile will not appear in search results';
    }
  }
}