import 'package:flutter/material.dart';
import '../services/mfa_service.dart';
import '../models/two_factor_configuration.dart';
import 'mfa_setup_wizard.dart';

class MfaSettingsPage extends StatefulWidget {
  final String userId;
  final MfaService mfaService;

  const MfaSettingsPage({
    super.key,
    required this.userId,
    required this.mfaService,
  });

  @override
  State<MfaSettingsPage> createState() => _MfaSettingsPageState();
}

class _MfaSettingsPageState extends State<MfaSettingsPage> {
  TwoFactorConfiguration? _configuration;
  bool _isLoading = true;
  List<String>? _backupCodes;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildSmsSection(),
                  const SizedBox(height: 24),
                  _buildTotpSection(),
                  const SizedBox(height: 24),
                  _buildBackupCodesSection(),
                  const SizedBox(height: 24),
                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final hasAny2fa = (_configuration?.smsEnabled == true) ||
                      (_configuration?.totpEnabled == true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasAny2fa ? Icons.security : Icons.security_outlined,
                  color: hasAny2fa ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  hasAny2fa ? '2FA Enabled' : '2FA Not Set Up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasAny2fa ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasAny2fa
                  ? 'Your account is protected with two-factor authentication.'
                  : 'Add an extra layer of security to your account.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sms, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'SMS Authentication',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_configuration?.smsEnabled == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Enabled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _configuration?.smsEnabled == true
                  ? 'Phone: ${_configuration?.phoneNumber}'
                  : 'Receive verification codes via SMS.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_configuration?.smsEnabled == true)
              ElevatedButton(
                onPressed: () => _disableSms2fa(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Disable SMS'),
              )
            else
              ElevatedButton(
                onPressed: () => _setupSms2fa(),
                child: const Text('Set Up SMS'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Authenticator App',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_configuration?.totpEnabled == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Enabled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _configuration?.totpEnabled == true
                  ? 'Authenticator app is configured'
                  : 'Use an authenticator app like Google Authenticator or Authy.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_configuration?.totpEnabled == true)
              ElevatedButton(
                onPressed: () => _disableTotp2fa(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Disable Authenticator App'),
              )
            else
              ElevatedButton(
                onPressed: () => _setupTotp2fa(),
                child: const Text('Set Up Authenticator App'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCodesSection() {
    final hasBackupCodes = _configuration?.backupCodes?.isNotEmpty == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Backup Codes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Save these codes in a secure place to access your account if you lose your authentication method.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: hasBackupCodes ? _showBackupCodes : _generateBackupCodes,
                  child: Text(hasBackupCodes ? 'View Codes' : 'Generate Codes'),
                ),
                const SizedBox(width: 12),
                if (hasBackupCodes)
                  ElevatedButton(
                    onPressed: _regenerateBackupCodes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Regenerate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final hasAny2fa = (_configuration?.smsEnabled == true) ||
                      (_configuration?.totpEnabled == true);

    if (!hasAny2fa) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Disabling all 2FA methods will reduce your account security.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _disableAll2fa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disable All 2FA'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await widget.mfaService.getConfiguration(widget.userId);
      setState(() {
        _configuration = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load configuration: ${e.toString()}')),
      );
    }
  }

  Future<void> _setupSms2fa() async {
    // Show SMS setup dialog
    final phoneNumberController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Up SMS Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your phone number:'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1234567890',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phoneNumber = phoneNumberController.text;
              if (phoneNumber.isNotEmpty) {
                Navigator.of(context).pop();
                try {
                  await widget.mfaService.enableSms2fa(widget.userId, phoneNumber);
                  await _loadConfiguration();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SMS 2FA enabled successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to enable SMS 2FA: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _setupTotp2fa() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MfaSetupWizard(
          userId: widget.userId,
          mfaService: widget.mfaService,
        ),
      ),
    );

    if (result == true) {
      await _loadConfiguration();
    }
  }

  Future<void> _disableSms2fa() async {
    final confirmed = await _showConfirmationDialog(
      'Disable SMS Authentication',
      'Are you sure you want to disable SMS authentication? This will make your account less secure.',
    );

    if (confirmed) {
      try {
        await widget.mfaService.disable2faMethod(widget.userId, 'sms');
        await _loadConfiguration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS authentication disabled')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable SMS: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _disableTotp2fa() async {
    final confirmed = await _showConfirmationDialog(
      'Disable Authenticator App',
      'Are you sure you want to disable authenticator app authentication? This will make your account less secure.',
    );

    if (confirmed) {
      try {
        await widget.mfaService.disable2faMethod(widget.userId, 'totp');
        await _loadConfiguration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authenticator app disabled')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable authenticator app: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _disableAll2fa() async {
    final confirmed = await _showConfirmationDialog(
      'Disable All 2FA',
      'Are you sure you want to disable all two-factor authentication methods? This will significantly reduce your account security.',
    );

    if (confirmed) {
      try {
        await widget.mfaService.disable2faMethod(widget.userId, 'all');
        await _loadConfiguration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All 2FA methods disabled')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable 2FA: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _generateBackupCodes() async {
    try {
      final codes = await widget.mfaService.generateBackupCodes(widget.userId);
      setState(() {
        _backupCodes = codes;
      });
      _showBackupCodes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate backup codes: ${e.toString()}')),
      );
    }
  }

  Future<void> _regenerateBackupCodes() async {
    final confirmed = await _showConfirmationDialog(
      'Regenerate Backup Codes',
      'Generating new backup codes will invalidate all existing codes. Make sure you save the new ones in a secure place.',
    );

    if (confirmed) {
      try {
        await widget.mfaService.regenerateBackupCodes(widget.userId);
        await _loadConfiguration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup codes regenerated')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate backup codes: ${e.toString()}')),
        );
      }
    }
  }

  void _showBackupCodes() {
    final codes = _configuration?.backupCodes ?? _backupCodes;
    if (codes == null || codes.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save these codes in a secure place. Each code can only be used once.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: codes.map((code) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}