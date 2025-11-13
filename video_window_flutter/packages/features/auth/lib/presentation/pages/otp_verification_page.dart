import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/lib/presentation/bloc/auth_bloc.dart';

/// OTP Verification Page
/// Second step in OTP authentication - user enters 6-digit code
class OtpVerificationPage extends StatefulWidget {
  final String email;
  final int expiresIn; // seconds

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.expiresIn,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late Timer _timer;
  late int _remainingSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.expiresIn;
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthOtpVerifyRequested(
              email: widget.email,
              code: _codeController.text.trim(),
            ),
          );
    }
  }

  void _onResend() {
    context.read<AuthBloc>().add(
          AuthOtpSendRequested(email: widget.email),
        );

    // Reset timer
    setState(() {
      _remainingSeconds = widget.expiresIn;
      _canResend = false;
    });
    _startTimer();
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Code is required';
    }

    if (value.length != 6) {
      return 'Code must be 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Code must contain only numbers';
    }

    return null;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Navigate to home/main screen
            // For now, just pop back
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is AuthError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAccountLocked) {
            // Show locked account message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is AuthOtpSent) {
            // Show resend success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New code sent!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),

                      // Icon
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Check your email',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Subtitle with email
                      Text(
                        'We sent a 6-digit code to',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Code input
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        enabled: !isLoading,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validateCode,
                        onFieldSubmitted: (_) => _onSubmit(),
                        onChanged: (value) {
                          // Auto-submit when 6 digits entered
                          if (value.length == 6) {
                            _onSubmit();
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Timer and resend
                      if (!_canResend)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Code expires in ${_formatTime(_remainingSeconds)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: _onResend,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resend Code'),
                        ),

                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Verify Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Info text
                      Text(
                        'Didn\'t receive the code? Check your spam folder or click resend above.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      // Change email button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Use a different email'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
