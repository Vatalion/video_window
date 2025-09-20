import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../domain/models/two_factor_config_model.dart';
import '../../bloc/two_factor/two_factor_bloc.dart';
import '../../bloc/two_factor/two_factor_event.dart';
import '../../bloc/two_factor/two_factor_state.dart';

class TwoFactorSmsSetupWidget extends StatefulWidget {
  final String userId;
  final void Function(TwoFactorConfig)? onSetupComplete;

  const TwoFactorSmsSetupWidget({
    super.key,
    required this.userId,
    this.onSetupComplete,
  });

  @override
  State<TwoFactorSmsSetupWidget> createState() =>
      _TwoFactorSmsSetupWidgetState();
}

class _TwoFactorSmsSetupWidgetState extends State<TwoFactorSmsSetupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _showCodeVerification = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final phoneNumber = _phoneController.text.trim();
    context.read<TwoFactorBloc>().add(
      TwoFactorSmsSetupInitiated(
        userId: widget.userId,
        phoneNumber: phoneNumber,
      ),
    );

    setState(() {
      _isSubmitting = false;
      _showCodeVerification = true;
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final code = _codeController.text.trim();
    context.read<TwoFactorBloc>().add(
      TwoFactorSmsCodeVerified(
        userId: widget.userId,
        sessionId: 'temp_session_${DateTime.now().millisecondsSinceEpoch}',
        code: code,
      ),
    );

    setState(() => _isSubmitting = false);
  }

  Future<void> _resendCode() async {
    context.read<TwoFactorBloc>().add(
      TwoFactorSmsCodeRequested(
        userId: widget.userId,
        sessionId: 'temp_session_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TwoFactorBloc, TwoFactorState>(
      listener: (context, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.hasSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );

          if (state.successMessage!.contains('verified successfully') &&
              widget.onSetupComplete != null) {
            widget.onSetupComplete!(state.config!);
          }
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_showCodeVerification) ...[
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildPhoneNumberInput(),
                  const SizedBox(height: 24),
                  _buildSecurityNote(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ] else ...[
                  _buildVerificationHeader(),
                  const SizedBox(height: 32),
                  _buildCodeInput(),
                  const SizedBox(height: 24),
                  _buildResendButton(),
                  const SizedBox(height: 32),
                  _buildVerificationSubmitButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sms, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMS Authentication',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Add an extra layer of security with SMS verification',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'How SMS 2FA works:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildStep(
          step: 1,
          title: 'Enter your phone number',
          description: 'We\'ll send a verification code to your phone',
        ),
        const SizedBox(height: 12),
        _buildStep(
          step: 2,
          title: 'Verify your number',
          description: 'Enter the 6-digit code you receive via SMS',
        ),
        const SizedBox(height: 12),
        _buildStep(
          step: 3,
          title: 'Complete setup',
          description: 'Your account will be protected with SMS verification',
        ),
      ],
    );
  }

  Widget _buildStep({
    required int step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+1 (555) 123-4567',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            if (!RegExp(
              r'^\+?1?\d{10,15}$',
            ).hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We\'ll only use your phone number for security verification. Standard message rates may apply.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPhoneNumber,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Send Verification Code'),
      ),
    );
  }

  Widget _buildVerificationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify Your Phone',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Enter the 6-digit code sent to ${_phoneController.text}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '123456',
            prefixIcon: const Icon(Icons.password),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the verification code';
            }
            if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
              return 'Please enter a valid 6-digit code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: _resendCode,
        child: Text(
          'Resend Code',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _verifyCode,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Verify Code'),
      ),
    );
  }
}
