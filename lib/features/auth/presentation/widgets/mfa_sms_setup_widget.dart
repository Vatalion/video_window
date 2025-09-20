import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_event.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_state.dart';

class MfaSmsSetupWidget extends StatefulWidget {
  final String userId;
  final MfaBloc mfaBloc;
  final VoidCallback onComplete;

  const MfaSmsSetupWidget({
    super.key,
    required this.userId,
    required this.mfaBloc,
    required this.onComplete,
  });

  @override
  State<MfaSmsSetupWidget> createState() => _MfaSmsSetupWidgetState();
}

class _MfaSmsSetupWidgetState extends State<MfaSmsSetupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '1');

  int _currentStep = 0;
  String? _verificationId;
  bool _isCodeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Verification Setup'),
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
          if (state is MfaSmsCodeSentState) {
            setState(() {
              _verificationId = state.verification.id;
              _isCodeSent = true;
              _currentStep = 1;
            });
          } else if (state is MfaSmsSetupCompleteState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SMS verification setup completed successfully!'),
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
            _buildPhoneStep(),
            _buildVerificationStep(),
            _buildConfirmationStep(),
          ],
        ),
      ),
    );
  }

  Step _buildPhoneStep() {
    return Step(
      title: const Text('Phone Number'),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your phone number to receive SMS verification codes.',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _countryCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      border: OutlineInputBorder(),
                      prefixText: '+',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      hintText: '(123) 456-7890',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Phone number is required';
                      }
                      if (!RegExp(r'^[\d\s\-\(\)]+$').hasMatch(value!)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Standard message and data rates may apply.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isActive: _currentStep == 0,
    );
  }

  Step _buildVerificationStep() {
    return Step(
      title: const Text('Verify Code'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We sent a verification code to +${_countryCodeController.text} ${_phoneController.text}',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Didn't receive the code?",
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: _isCodeSent ? null : _resendCode,
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    color: _isCodeSent ? Colors.grey : Colors.blue,
                  ),
                ),
              ),
            ],
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
                    'The verification code will expire in 10 minutes.',
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

  Step _buildConfirmationStep() {
    return Step(
      title: const Text('Confirmation'),
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
                      'SMS Verification Enabled',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your account is now protected with SMS verification.',
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
            'What happens next:',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...[
            '• You will receive SMS codes for sensitive actions',
            '• Keep your phone accessible when logging in',
            '• Generate backup codes for account recovery',
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
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
      isActive: _currentStep == 2,
    );
  }

  void _handleStepContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        _sendVerificationCode();
      }
    } else if (_currentStep == 1) {
      if (_codeController.text.length == 6) {
        _verifyCode();
      }
    } else if (_currentStep == 2) {
      _completeSetup();
    }
  }

  void _sendVerificationCode() {
    widget.mfaBloc.add(
      MfaSendSmsCodeEvent(
        userId: widget.userId,
        phoneNumber: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        countryCode: _countryCodeController.text,
      ),
    );
  }

  void _resendCode() {
    if (!_isCodeSent) {
      _sendVerificationCode();
    }
  }

  void _verifyCode() {
    if (_verificationId == null) return;

    widget.mfaBloc.add(
      MfaVerifySmsCodeEvent(
        verificationId: _verificationId!,
        code: _codeController.text,
      ),
    );
  }

  void _completeSetup() {
    if (_verificationId == null) return;

    widget.mfaBloc.add(
      MfaSetupSmsEvent(
        userId: widget.userId,
        phoneNumber: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        countryCode: _countryCodeController.text,
        verificationId: _verificationId!,
        verificationCode: _codeController.text,
      ),
    );
  }
}
