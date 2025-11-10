import 'package:flutter/material.dart';
import '../../app_shell/legal_disclosures.dart';

/// Cookie consent banner for GDPR/CCPA compliance
///
/// Displays on first visit or when consent is required.
/// Allows users to accept all, customize preferences, or reject optional cookies.
class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({
    super.key,
    required this.userId,
    required this.onConsentGiven,
  });

  final String? userId;
  final Function(Map<String, bool> preferences) onConsentGiven;

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _showDetails = false;
  late Map<String, bool> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = {
      'essential': true,
      'functional': false,
      'analytics': false,
      'marketing': false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildDescription(context),
              if (_showDetails) ...[
                const SizedBox(height: 16),
                _buildCookiePreferences(context),
              ],
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.cookie,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Cookie Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'We use cookies to provide essential functionality, enhance your experience, '
      'and analyze how our site is used. You can customize your preferences below.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildCookiePreferences(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Cookie Preferences',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...LegalDisclosures.cookieCategories.entries.map((entry) {
          final category = entry.key;
          final info = entry.value as Map<String, dynamic>;
          final isRequired = info['required'] as bool;

          return _buildCookieCategory(
            context,
            category,
            info['name'] as String,
            info['description'] as String,
            isRequired,
          );
        }),
      ],
    );
  }

  Widget _buildCookieCategory(
    BuildContext context,
    String category,
    String name,
    String description,
    bool isRequired,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (isRequired)
                  Chip(
                    label: const Text('Required'),
                    backgroundColor: Colors.grey.shade300,
                    labelStyle: const TextStyle(fontSize: 12),
                  )
                else
                  Switch(
                    value: _preferences[category] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _preferences[category] = value;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleRejectOptional,
                child: const Text('Reject Optional'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleAcceptAll,
                child: const Text('Accept All'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showDetails = !_showDetails;
                });
              },
              child: Text(_showDetails ? 'Hide Details' : 'Customize'),
            ),
            if (_showDetails)
              TextButton(
                onPressed: _handleSavePreferences,
                child: const Text('Save Preferences'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => _openLegalPage(context, 'privacy'),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () => _openLegalPage(context, 'terms'),
              child: const Text('Terms'),
            ),
            TextButton(
              onPressed: () => _openLegalPage(context, 'cookies'),
              child: const Text('Cookie Policy'),
            ),
          ],
        ),
      ],
    );
  }

  void _handleAcceptAll() {
    final allAccepted = {
      'essential': true,
      'functional': true,
      'analytics': true,
      'marketing': true,
    };
    _recordConsent(allAccepted);
  }

  void _handleRejectOptional() {
    final essentialOnly = {
      'essential': true,
      'functional': false,
      'analytics': false,
      'marketing': false,
    };
    _recordConsent(essentialOnly);
  }

  void _handleSavePreferences() {
    _recordConsent(_preferences);
  }

  void _recordConsent(Map<String, bool> preferences) {
    // Record consent
    if (widget.userId != null) {
      LegalDisclosures.updateCookiePreferences(widget.userId!, preferences);
    }

    // Notify parent
    widget.onConsentGiven(preferences);
  }

  void _openLegalPage(BuildContext context, String page) {
    // TODO: Navigate to legal pages
    // Navigator.pushNamed(context, '/privacy-policy');
    // Navigator.pushNamed(context, '/terms-of-service');
  }
}

/// Wrapper widget to show consent banner when needed
class CookieConsentWrapper extends StatefulWidget {
  const CookieConsentWrapper({
    super.key,
    required this.child,
    this.userId,
  });

  final Widget child;
  final String? userId;

  @override
  State<CookieConsentWrapper> createState() => _CookieConsentWrapperState();
}

class _CookieConsentWrapperState extends State<CookieConsentWrapper> {
  bool _showBanner = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConsentRequired();
  }

  Future<void> _checkConsentRequired() async {
    final required =
        await LegalDisclosures.requiresConsentPrompt(widget.userId);
    if (mounted) {
      setState(() {
        _showBanner = required;
        _isLoading = false;
      });
    }
  }

  void _handleConsentGiven(Map<String, bool> preferences) {
    setState(() {
      _showBanner = false;
    });

    // Apply cookie preferences
    _applyCookiePreferences(preferences);
  }

  void _applyCookiePreferences(Map<String, bool> preferences) {
    // TODO: Enable/disable cookie functionality based on preferences
    // - Analytics tracking (if preferences['analytics'] == true)
    // - Marketing pixels (if preferences['marketing'] == true)
    // - Functional cookies (if preferences['functional'] == true)
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CookieConsentBanner(
              userId: widget.userId,
              onConsentGiven: _handleConsentGiven,
            ),
          ),
      ],
    );
  }
}
