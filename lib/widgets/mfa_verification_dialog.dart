import 'package:flutter/material.dart';
import '../services/mfa_service.dart';

class MfaVerificationDialog extends StatefulWidget {
  final String userId;
  final MfaService mfaService;
  final String? actionDescription;

  const MfaVerificationDialog({
    super.key,
    required this.userId,
    required this.mfaService,
    this.actionDescription,
  });

  @override
  State<MfaVerificationDialog> createState() => _MfaVerificationDialogState();
}

class _MfaVerificationDialogState extends State<MfaVerificationDialog> {
  String? _verificationCode;
  bool _isLoading = false;
  bool _showBackupCodeOption = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Two-Factor Authentication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.actionDescription != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.actionDescription!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          Text(
            'Enter your verification code to continue:',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextField(
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
          ),
          const SizedBox(height: 16),
          if (!_showBackupCodeOption)
            TextButton(
              onPressed: () {
                setState(() {
                  _showBackupCodeOption = true;
                });
              },
              child: const Text('Use backup code instead'),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        if (!_isLoading)
          ElevatedButton(
            onPressed: _verifyCode,
            child: const Text('Verify'),
          ),
      ],
    );
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
      final verified = await widget.mfaService.verify2faCode(
        widget.userId,
        _verificationCode!,
      );

      if (verified) {
        Navigator.of(context).pop(true);
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