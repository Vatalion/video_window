import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/privacy_toggle_tile.dart';

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

  // Store previous values for rollback on failure (AC2)
  String? _previousProfileVisibility;
  bool? _previousShowEmailToPublic;
  bool? _previousShowPhoneToFriends;
  bool? _previousAllowTagging;
  bool? _previousAllowSearchByPhone;
  bool? _previousAllowDataAnalytics;
  bool? _previousAllowMarketingEmails;
  bool? _previousAllowPushNotifications;
  bool? _previousShareProfileWithPartners;

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
              // Clear previous values after successful save
              _previousProfileVisibility = null;
              _previousShowEmailToPublic = null;
              _previousShowPhoneToFriends = null;
              _previousAllowTagging = null;
              _previousAllowSearchByPhone = null;
              _previousAllowDataAnalytics = null;
              _previousAllowMarketingEmails = null;
              _previousAllowPushNotifications = null;
              _previousShareProfileWithPartners = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Privacy settings saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ProfileError) {
            // AC2: Rollback on failure
            _rollbackSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error: ${state.message}. Settings have been rolled back.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
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
                  PrivacyToggleTile(
                    title: 'Show Email to Public',
                    value: _showEmailToPublic ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _showEmailToPublic = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Allow anyone to see your email address',
                    learnMoreUrl:
                        'https://example.com/privacy/email-visibility',
                    learnMoreText: 'Learn more about email visibility',
                  ),
                  const SizedBox(height: 8),
                  PrivacyToggleTile(
                    title: 'Show Phone to Friends',
                    value: _showPhoneToFriends ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _showPhoneToFriends = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Allow friends to see your phone number',
                    learnMoreUrl: 'https://example.com/privacy/phone-sharing',
                    learnMoreText: 'Learn more about phone sharing',
                  ),
                  const SizedBox(height: 24),

                  // Interaction Settings Section
                  _buildSectionHeader('Interaction Settings'),
                  PrivacyToggleTile(
                    title: 'Allow Tagging',
                    value: _allowTagging ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _allowTagging = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Allow others to tag you in content',
                    learnMoreUrl: 'https://example.com/privacy/tagging',
                    learnMoreText: 'Learn more about tagging',
                  ),
                  const SizedBox(height: 8),
                  PrivacyToggleTile(
                    title: 'Allow Search by Phone',
                    value: _allowSearchByPhone ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _allowSearchByPhone = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Allow others to find you using your phone number',
                    learnMoreUrl: 'https://example.com/privacy/phone-search',
                    learnMoreText: 'Learn more about phone search',
                  ),
                  const SizedBox(height: 24),

                  // Data Sharing Section
                  _buildSectionHeader('Data Sharing & Analytics'),
                  PrivacyToggleTile(
                    title: 'Allow Data Analytics',
                    value: _allowDataAnalytics ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _allowDataAnalytics = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Share anonymized data for analytics and product improvement',
                    learnMoreUrl: 'https://example.com/privacy/analytics',
                    learnMoreText: 'Learn more about data analytics',
                  ),
                  const SizedBox(height: 8),
                  PrivacyToggleTile(
                    title: 'Share Profile with Partners',
                    value: _shareProfileWithPartners ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _shareProfileWithPartners = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Allow trusted partners to access your profile information',
                    learnMoreUrl: 'https://example.com/privacy/partner-sharing',
                    learnMoreText: 'Learn more about partner sharing',
                  ),
                  const SizedBox(height: 24),

                  // Marketing & Notifications Section
                  _buildSectionHeader('Marketing & Notifications'),
                  PrivacyToggleTile(
                    title: 'Marketing Emails',
                    value: _allowMarketingEmails ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _allowMarketingEmails = value;
                        _hasChanges = true;
                      });
                    },
                    description:
                        'Receive marketing emails and promotional content',
                    learnMoreUrl: 'https://example.com/privacy/marketing',
                    learnMoreText: 'Learn more about marketing preferences',
                  ),
                  const SizedBox(height: 8),
                  PrivacyToggleTile(
                    title: 'Push Notifications',
                    value: _allowPushNotifications ?? false,
                    onChanged: (value) {
                      _savePreviousValue();
                      setState(() {
                        _allowPushNotifications = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Receive push notifications on your device',
                    learnMoreUrl: 'https://example.com/privacy/notifications',
                    learnMoreText: 'Learn more about notifications',
                  ),
                  const SizedBox(height: 32),

                  // GDPR/CCPA Compliance Note
                  _buildComplianceNote(),

                  // DSAR CTA Section (AC5)
                  const SizedBox(height: 24),
                  _buildDsarSection(),
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

  Widget _buildDsarSection() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Data Rights & Privacy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'You have the right to access, export, or delete your personal data at any time.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDsarExportConfirmation(),
                    icon: const Icon(Icons.download),
                    label: const Text('Export My Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDsarDeleteConfirmation(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete My Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDsarExportConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Your Data'),
        content: const Text(
          'This will generate a downloadable package containing all your personal data. '
          'The export will be available within 24 hours. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileBloc>().add(
                    ExportUserDataRequested(widget.userId),
                  );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDsarDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Your Data'),
        content: const Text(
          'This will permanently delete all your personal data, including your profile, '
          'privacy settings, and account information. This action cannot be undone. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileBloc>().add(
                    DeleteUserDataRequested(widget.userId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _savePreviousValue() {
    // AC2: Save previous values for rollback on failure
    if (!_hasChanges) {
      _previousProfileVisibility = _profileVisibility;
      _previousShowEmailToPublic = _showEmailToPublic;
      _previousShowPhoneToFriends = _showPhoneToFriends;
      _previousAllowTagging = _allowTagging;
      _previousAllowSearchByPhone = _allowSearchByPhone;
      _previousAllowDataAnalytics = _allowDataAnalytics;
      _previousAllowMarketingEmails = _allowMarketingEmails;
      _previousAllowPushNotifications = _allowPushNotifications;
      _previousShareProfileWithPartners = _shareProfileWithPartners;
    }
  }

  void _rollbackSettings() {
    // AC2: Rollback to previous values on failure
    setState(() {
      if (_previousProfileVisibility != null) {
        _profileVisibility = _previousProfileVisibility;
      }
      if (_previousShowEmailToPublic != null) {
        _showEmailToPublic = _previousShowEmailToPublic;
      }
      if (_previousShowPhoneToFriends != null) {
        _showPhoneToFriends = _previousShowPhoneToFriends;
      }
      if (_previousAllowTagging != null) {
        _allowTagging = _previousAllowTagging;
      }
      if (_previousAllowSearchByPhone != null) {
        _allowSearchByPhone = _previousAllowSearchByPhone;
      }
      if (_previousAllowDataAnalytics != null) {
        _allowDataAnalytics = _previousAllowDataAnalytics;
      }
      if (_previousAllowMarketingEmails != null) {
        _allowMarketingEmails = _previousAllowMarketingEmails;
      }
      if (_previousAllowPushNotifications != null) {
        _allowPushNotifications = _previousAllowPushNotifications;
      }
      if (_previousShareProfileWithPartners != null) {
        _shareProfileWithPartners = _previousShareProfileWithPartners;
      }
      _hasChanges = false;
    });
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

    // AC2: Save previous values before attempting update
    _savePreviousValue();

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
