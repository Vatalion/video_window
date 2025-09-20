import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_event.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_state.dart';

class MfaTotpSetupWidget extends StatefulWidget {
  final String userId;
  final MfaBloc mfaBloc;
  final VoidCallback onComplete;

  const MfaTotpSetupWidget({
    super.key,
    required this.userId,
    required this.mfaBloc,
    required this.onComplete,
  });

  @override
  State<MfaTotpSetupWidget> createState() => _MfaTotpSetupWidgetState();
}

class _MfaTotpSetupWidgetState extends State<MfaTotpSetupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _accountNameController = TextEditingController();

  int _currentStep = 0;
  String? _setupId;
  TotpSetupModel? _totpSetup;

  @override
  void initState() {
    super.initState();
    _accountNameController.text = 'user_${widget.userId}';
    _initiateTotpSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator App Setup'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: BlocListener<MfaBloc, MfaState>(
        listener: (context, state) {
          if (state is MfaTotpSetupInitiatedState) {
            setState(() {
              _totpSetup = state.setup;
              _setupId = state.setup.id;
              _currentStep = 1;
            });
          } else if (state is MfaTotpSetupVerifiedState) {
            setState(() => _currentStep = 2);
          } else if (state is MfaTotpSetupCompleteState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Authenticator app setup completed successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
            widget.onComplete();
          } else if (state is MfaErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _handleStepContinue,
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
          steps: [
            _buildIntroductionStep(),
            _buildScanStep(),
            _buildVerificationStep(),
            _buildConfirmationStep(),
          ],
        ),
      ),
    );
  }

  Step _buildIntroductionStep() {
    return Step(
      title: const Text('Introduction'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set up two-factor authentication using an authenticator app.',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Text(
            'Recommended apps:',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            '• Google Authenticator',
            '• Microsoft Authenticator',
            '• Authy',
            '• LastPass Authenticator',
          ].map(
            (app) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                app,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'How it works:',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            '1. Install an authenticator app on your phone',
            '2. Scan the QR code or enter the setup key manually',
            '3. Enter the verification code to confirm setup',
            '4. Use the app to generate codes when logging in',
          ].map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                step,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      ),
      isActive: _currentStep == 0,
    );
  }

  Step _buildScanStep() {
    return Step(
      title: const Text('Scan QR Code'),
      content: _totpSetup == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan this QR code with your authenticator app:',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: _totpSetup!.qrCodeUri,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Or enter this setup key manually:',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _totpSetup!.manualSetupKey,
                          style: GoogleFonts.monospace(
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Copy to clipboard
                          // Clipboard.setData(ClipboardData(text: _totpSetup!.manualSetupKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Setup key copied to clipboard'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This setup will expire in 15 minutes.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      isActive: _currentStep == 1,
    );
  }

  Step _buildVerificationStep() {
    return Step(
      title: const Text('Verify Setup'),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the verification code from your authenticator app:',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
                hintText: 'Enter 6-digit code',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Verification code is required';
                }
                if (value!.length != 6) {
                  return 'Code must be 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                labelText: 'Account Name (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Work Account, Personal Account',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The code changes every 30 seconds. Make sure to enter the current code.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      isActive: _currentStep == 2,
    );
  }

  Step _buildConfirmationStep() {
    return Step(
      title: const Text('Backup Codes'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authenticator App Enabled',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your account is now protected with TOTP verification.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your backup codes:',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Save these backup codes in a secure location. You can use them to access your account if you lose your authenticator device.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow[200]!),
            ),
            child: _totpSetup == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _totpSetup!.backupCodes
                            .map(
                              (code) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  code,
                                  style: GoogleFonts.monospace(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These codes are only shown once. Store them securely!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeSetup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Complete Setup'),
            ),
          ),
        ],
      ),
      isActive: _currentStep == 3,
    );
  }

  void _initiateTotpSetup() {
    widget.mfaBloc.add(MfaInitiateTotpSetupEvent(userId: widget.userId));
  }

  void _handleStepContinue() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_formKey.currentState?.validate() ?? false) {
        _verifyTotpCode();
      }
    } else if (_currentStep == 3) {
      _completeSetup();
    }
  }

  void _verifyTotpCode() {
    if (_setupId == null) return;

    widget.mfaBloc.add(
      MfaVerifyTotpSetupEvent(
        setupId: _setupId!,
        verificationCode: _codeController.text,
      ),
    );
  }

  void _completeSetup() {
    if (_setupId == null) return;

    widget.mfaBloc.add(
      MfaCompleteTotpSetupEvent(
        setupId: _setupId!,
        userId: widget.userId,
        accountName: _accountNameController.text.trim().isNotEmpty
            ? _accountNameController.text
            : 'user_${widget.userId}',
      ),
    );
  }
}
