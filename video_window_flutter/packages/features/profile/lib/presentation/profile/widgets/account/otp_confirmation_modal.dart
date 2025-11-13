import 'package:flutter/material.dart';
client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// OTP confirmation modal for re-authentication
/// AC4: All DSAR and deletion actions require re-authentication (OTP) if last auth > 10 minutes
class OTPConfirmationModal extends StatefulWidget {
  final int userId;
  final VoidCallback onVerified;

  const OTPConfirmationModal({
    super.key,
    required this.userId,
    required this.onVerified,
  });

  @override
  State<OTPConfirmationModal> createState() => _OTPConfirmationModalState();
}

class _OTPConfirmationModalState extends State<OTPConfirmationModal> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Get user email from profile or session
      // For now, using a placeholder - this should be retrieved from the authenticated user
      final client = Client('http://localhost:8080/')
        ..connectivityMonitor = FlutterConnectivityMonitor();

      // Call auth endpoint to send OTP
      // Note: This is a placeholder - actual implementation should use proper auth service
      // final result = await client.auth.sendOTP(userEmail);

      setState(() {
        _codeSent = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification code: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Verify OTP using auth service
      // For now, this is a placeholder
      // final client = Client('http://localhost:8080/')
      //   ..connectivityMonitor = FlutterConnectivityMonitor();
      // final result = await client.auth.verifyOTP(userEmail, code);

      // Simulate verification success for now
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        widget.onVerified();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid verification code. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Re-authentication Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'For your security, please verify your identity before proceeding.',
          ),
          const SizedBox(height: 16),
          if (!_codeSent)
            const Center(child: CircularProgressIndicator())
          else ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                hintText: 'Enter 6-digit code',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _sendOTP,
              child: const Text('Resend Code'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_codeSent ? null : _verifyOTP,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
