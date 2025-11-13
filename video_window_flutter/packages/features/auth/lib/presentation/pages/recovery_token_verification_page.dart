import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/lib/presentation/bloc/auth_bloc.dart';

/// Recovery Token Verification Page
/// Second step in account recovery - user enters the recovery token
/// AC3: Token entry screen with success/failure states
class RecoveryTokenVerificationPage extends StatefulWidget {
  final String email;

  const RecoveryTokenVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<RecoveryTokenVerificationPage> createState() =>
      _RecoveryTokenVerificationPageState();
}

class _RecoveryTokenVerificationPageState
    extends State<RecoveryTokenVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  int? _attemptsRemaining;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRecoveryVerifyRequested(
              email: widget.email,
              token: _tokenController.text.trim().replaceAll(' ', ''),
            ),
          );
    }
  }

  void _onResend() {
    context.read<AuthBloc>().add(
          AuthRecoverySendRequested(email: widget.email),
        );
  }

  String? _validateToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'Recovery token is required';
    }

    // Remove spaces and validate length
    final cleanToken = value.replaceAll(' ', '');
    if (cleanToken.length < 16) {
      return 'Recovery token must be at least 16 characters';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Recovery Token'),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Recovery successful, navigate to home
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Account recovered successfully! All previous sessions have been logged out.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            // TODO: Navigate to home page
            // Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          } else if (state is AuthError) {
            // Update attempts remaining if provided
            if (state.attemptsRemaining != null) {
              setState(() {
                _attemptsRemaining = state.attemptsRemaining;
              });
            }

            // Show error message with severity-based color
            Color bgColor = Colors.red;
            if (state.error == 'INVALID_TOKEN' &&
                _attemptsRemaining != null &&
                _attemptsRemaining! > 0) {
              bgColor = Colors
                  .orange; // Warning for invalid token with attempts remaining
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message),
                    if (_attemptsRemaining != null && _attemptsRemaining! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$_attemptsRemaining attempt${_attemptsRemaining! > 1 ? 's' : ''} remaining',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                backgroundColor: bgColor,
                duration: Duration(seconds: state.retryAfter ?? 4),
              ),
            );

            // Clear token field if it was invalid
            if (state.error == 'INVALID_TOKEN') {
              _tokenController.clear();
            }
          } else if (state is AuthRecoverySent) {
            // New recovery token sent
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New recovery token sent! Check your email.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Security icon with badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                          Positioned(
                            right: 120,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mail_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Check Your Email',
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
                      Column(
                        children: [
                          Text(
                            'We sent a recovery token to:',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Token input
                      TextFormField(
                        controller: _tokenController,
                        keyboardType: TextInputType.text,
                        autofocus: true,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Recovery Token',
                          hintText: 'Enter the token from your email',
                          prefixIcon: const Icon(Icons.vpn_key_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Token is case-insensitive',
                          counterText: _attemptsRemaining != null
                              ? '$_attemptsRemaining attempts remaining'
                              : null,
                          counterStyle: TextStyle(
                            color: _attemptsRemaining != null &&
                                    _attemptsRemaining! <= 1
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                        validator: _validateToken,
                        onFieldSubmitted: (_) => _onSubmit(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                        ],
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
                                'Verify Token',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Resend button
                      OutlinedButton(
                        onPressed: isLoading ? null : _onResend,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Resend Token'),
                      ),

                      const SizedBox(height: 32),

                      // Expiry warning
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.amber[900],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Token expires in 15 minutes',
                                style: TextStyle(
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Security note
                      if (_attemptsRemaining != null &&
                          _attemptsRemaining! <= 1)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Last attempt! Account will be locked for 30 minutes after next failed attempt.',
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Info text
                      Text(
                        'Didn\'t receive the token? Check your spam folder or click "Resend Token".',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
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
