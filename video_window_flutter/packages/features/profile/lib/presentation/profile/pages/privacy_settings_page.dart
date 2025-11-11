import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Privacy settings page
/// AC3: Granular privacy settings allowing viewers to control profile visibility,
/// data sharing preferences, and consent management with GDPR/CCPA compliance
class PrivacySettingsPage extends StatefulWidget {
  final int userId;

  const PrivacySettingsPage({
    super.key,
    required this.userId,
  });

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  String? _profileVisibility;
  bool? _showEmailToPublic;
  bool? _showPhoneToFriends;
  bool? _allowTagging;
  bool? _allowSearchByPhone;
  bool? _allowDataAnalytics;
  bool? _allowMarketingEmails;
  bool? _allowPushNotifications;
  bool? _shareProfileWithPartners;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    context
        .read<ProfileBloc>()
        .add(PrivacySettingsLoadRequested(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is PrivacySettingsUpdated) {
            setState(() {
              _hasChanges = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Privacy settings saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is PrivacySettingsUpdated) {
              final settings = state.settings;
              // Initialize local state from loaded settings
              if (_profileVisibility == null) {
                _profileVisibility =
                    settings['profileVisibility'] as String? ?? 'public';
                _showEmailToPublic =
                    settings['showEmailToPublic'] as bool? ?? false;
                _showPhoneToFriends =
                    settings['showPhoneToFriends'] as bool? ?? false;
                _allowTagging = settings['allowTagging'] as bool? ?? false;
                _allowSearchByPhone =
                    settings['allowSearchByPhone'] as bool? ?? false;
                _allowDataAnalytics =
                    settings['allowDataAnalytics'] as bool? ?? false;
                _allowMarketingEmails =
                    settings['allowMarketingEmails'] as bool? ?? false;
                _allowPushNotifications =
                    settings['allowPushNotifications'] as bool? ?? false;
                _shareProfileWithPartners =
                    settings['shareProfileWithPartners'] as bool? ?? false;
              }
            }

            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProfileBloc>().add(
                              PrivacySettingsLoadRequested(widget.userId),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Visibility Section
                  _buildSectionHeader('Profile Visibility'),
                  _buildVisibilitySelector(),
                  const SizedBox(height: 24),

                  // Contact Information Section
                  _buildSectionHeader('Contact Information'),
                  _buildSwitchTile(
                    title: 'Show Email to Public',
                    value: _showEmailToPublic ?? false,
                    onChanged: (value) {
                      setState(() {
                        _showEmailToPublic = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Allow anyone to see your email address',
                  ),
                  _buildSwitchTile(
                    title: 'Show Phone to Friends',
                    value: _showPhoneToFriends ?? false,
                    onChanged: (value) {
                      setState(() {
                        _showPhoneToFriends = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Allow friends to see your phone number',
                  ),
                  const SizedBox(height: 24),

                  // Interaction Settings Section
                  _buildSectionHeader('Interaction Settings'),
                  _buildSwitchTile(
                    title: 'Allow Tagging',
                    value: _allowTagging ?? false,
                    onChanged: (value) {
                      setState(() {
                        _allowTagging = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Allow others to tag you in content',
                  ),
                  _buildSwitchTile(
                    title: 'Allow Search by Phone',
                    value: _allowSearchByPhone ?? false,
                    onChanged: (value) {
                      setState(() {
                        _allowSearchByPhone = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Allow others to find you using your phone number',
                  ),
                  const SizedBox(height: 24),

                  // Data Sharing Section
                  _buildSectionHeader('Data Sharing & Analytics'),
                  _buildSwitchTile(
                    title: 'Allow Data Analytics',
                    value: _allowDataAnalytics ?? false,
                    onChanged: (value) {
                      setState(() {
                        _allowDataAnalytics = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Share anonymized data for analytics and product improvement',
                  ),
                  _buildSwitchTile(
                    title: 'Share Profile with Partners',
                    value: _shareProfileWithPartners ?? false,
                    onChanged: (value) {
                      setState(() {
                        _shareProfileWithPartners = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Allow trusted partners to access your profile information',
                  ),
                  const SizedBox(height: 24),

                  // Marketing & Notifications Section
                  _buildSectionHeader('Marketing & Notifications'),
                  _buildSwitchTile(
                    title: 'Marketing Emails',
                    value: _allowMarketingEmails ?? false,
                    onChanged: (value) {
                      setState(() {
                        _allowMarketingEmails = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Receive marketing emails and promotional content',
                  ),
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    value: _allowPushNotifications ?? false,
                    onChanged: (value) {
                      setState(() {
                        _allowPushNotifications = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Receive push notifications on your device',
                  ),
                  const SizedBox(height: 32),

                  // GDPR/CCPA Compliance Note
                  _buildComplianceNote(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Public'),
            subtitle: const Text('Anyone can see your profile'),
            value: 'public',
            groupValue: _profileVisibility,
            onChanged: (value) {
              setState(() {
                _profileVisibility = value;
                _hasChanges = true;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Friends Only'),
            subtitle: const Text('Only your friends can see your profile'),
            value: 'friends',
            groupValue: _profileVisibility,
            onChanged: (value) {
              setState(() {
                _profileVisibility = value;
                _hasChanges = true;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Private'),
            subtitle: const Text('Only you can see your profile'),
            value: 'private',
            groupValue: _profileVisibility,
            onChanged: (value) {
              setState(() {
                _profileVisibility = value;
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String description,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(description),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildComplianceNote() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Your Privacy Rights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'You have the right to access, correct, and delete your personal information at any time. '
              'Changes to your privacy settings are logged for compliance purposes.',
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    if (_profileVisibility == null) return;

    context.read<ProfileBloc>().add(
          PrivacySettingsUpdateRequested(
            widget.userId,
            {
              'profileVisibility': _profileVisibility!,
              'showEmailToPublic': _showEmailToPublic ?? false,
              'showPhoneToFriends': _showPhoneToFriends ?? false,
              'allowTagging': _allowTagging ?? false,
              'allowSearchByPhone': _allowSearchByPhone ?? false,
              'allowDataAnalytics': _allowDataAnalytics ?? false,
              'allowMarketingEmails': _allowMarketingEmails ?? false,
              'allowPushNotifications': _allowPushNotifications ?? false,
              'shareProfileWithPartners': _shareProfileWithPartners ?? false,
            },
          ),
        );
  }
}
