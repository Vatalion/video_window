import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/mfa_service.dart';
import '../models/two_factor_configuration.dart';

class MfaSetupWizard extends StatefulWidget {
  final String userId;
  final MfaService mfaService;

  const MfaSetupWizard({
    super.key,
    required this.userId,
    required this.mfaService,
  });

  @override
  State<MfaSetupWizard> createState() => _MfaSetupWizardState();
}

class _MfaSetupWizardState extends State<MfaSetupWizard> {
  int _currentStep = 0;
  String? _selectedMethod;
  String? _phoneNumber;
  Map<String, dynamic>? _totpSetupData;
  String? _verificationCode;
  bool _isLoading = false;
  List<String>? _backupCodes;

  final List<String> _methods = ['sms', 'totp'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Two-Factor Authentication'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _handleStepContinue,
        onStepCancel: _handleStepCancel,
        steps: [
          _buildMethodSelectionStep(),
          _buildSmsSetupStep(),
          _buildTotpSetupStep(),
          _buildVerificationStep(),
          _buildBackupCodesStep(),
        ],
      ),
    );
  }

  Step _buildMethodSelectionStep() {
    return Step(
      title: const Text('Choose Method'),
      content: Column(
        children: [
          const Text(
            'Select a two-factor authentication method to secure your account.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          RadioListTile<String>(
            title: const Text('SMS (Text Message)'),
            subtitle: const Text('Receive verification codes via SMS'),
            value: 'sms',
            groupValue: _selectedMethod,
            onChanged: (value) {
              setState(() {
                _selectedMethod = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Authenticator App'),
            subtitle: const Text('Use an app like Google Authenticator or Authy'),
            value: 'totp',
            groupValue: _selectedMethod,
            onChanged: (value) {
              setState(() {
                _selectedMethod = value;
              });
            },
          ),
        ],
      ),
      isActive: _currentStep == 0,
    );
  }

  Step _buildSmsSetupStep() {
    return Step(
      title: const Text('SMS Setup'),
      content: Column(
        children: [
          const Text(
            'Enter your phone number to receive SMS verification codes.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1234567890',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              setState(() {
                _phoneNumber = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
        ],
      ),
      isActive: _currentStep == 1,
    );
  }

  Step _buildTotpSetupStep() {
    return Step(
      title: const Text('Authenticator App Setup'),
      content: Column(
        children: [
          const Text(
            'Scan this QR code with your authenticator app:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          if (_totpSetupData != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: _totpSetupData!['provisioningUri'],
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Or enter this code manually:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _totpSetupData!['manualEntryKey'],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      isActive: _currentStep == 2,
    );
  }

  Step _buildVerificationStep() {
    return Step(
      title: const Text('Verify Setup'),
      content: Column(
        children: [
          Text(
            'Enter the ${_selectedMethod == 'sms' ? 'SMS' : 'authenticator app'} verification code:',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _verificationCode = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the verification code';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _verifyCode,
              child: const Text('Verify Code'),
            ),
        ],
      ),
      isActive: _currentStep == 3,
    );
  }

  Step _buildBackupCodesStep() {
    return Step(
      title: const Text('Backup Codes'),
      content: Column(
        children: [
          const Text(
            'Save these backup codes in a secure place. You can use them to access your account if you lose your authentication method.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          if (_backupCodes != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _backupCodes!.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${i + 1}. ${_backupCodes![i]}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Complete Setup'),
          ),
        ],
      ),
      isActive: _currentStep == 4,
    );
  }

  void _handleStepContinue() {
    setState(() {
      if (_currentStep < _getTotalSteps() - 1) {
        _currentStep++;
        _setupCurrentStep();
      } else {
        // Complete setup
        Navigator.of(context).pop();
      }
    });
  }

  void _handleStepCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  int _getTotalSteps() {
    return _selectedMethod == 'sms' ? 4 : 5;
  }

  Future<void> _setupCurrentStep() async {
    switch (_currentStep) {
      case 1:
        // SMS setup step - no additional setup needed
        break;
      case 2:
        if (_selectedMethod == 'totp') {
          await _setupTotp();
        }
        break;
    }
  }

  Future<void> _setupTotp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final setupData = await widget.mfaService.setupTotp2fa(widget.userId);
      setState(() {
        _totpSetupData = setupData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to setup authenticator app: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationCode == null || _verificationCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a verification code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool verified = false;

      if (_selectedMethod == 'sms') {
        // For SMS, the verification would be handled differently
        // This is a simplified version
        verified = true;
      } else {
        verified = await widget.mfaService.verifyTotpSetup(
          widget.userId,
          _verificationCode!,
        );
      }

      if (verified) {
        // Get backup codes
        final backupCodes = await widget.mfaService.generateBackupCodes(widget.userId);
        setState(() {
          _backupCodes = backupCodes;
          _isLoading = false;
        });

        if (_selectedMethod == 'totp') {
          _currentStep++;
        } else {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification code')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: ${e.toString()}')),
      );
    }
  }
}