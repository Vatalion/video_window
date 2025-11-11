import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../lib/presentation/bloc/auth_bloc.dart';
import 'otp_verification_page.dart';
import '../widgets/social_sign_in_buttons.dart';
import '../widgets/social_sign_in_service.dart';

/// Email OTP Request Page
/// First step in OTP authentication - user enters email
/// Includes social sign-in options (Apple & Google)
class EmailOtpRequestPage extends StatefulWidget {
  const EmailOtpRequestPage({Key? key}) : super(key: key);

  @override
  State<EmailOtpRequestPage> createState() => _EmailOtpRequestPageState();
}

class _EmailOtpRequestPageState extends State<EmailOtpRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final SocialSignInService _socialSignInService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _socialSignInService = SocialSignInService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthOtpSendRequested(email: _emailController.text.trim()),
          );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            // Navigate to OTP verification page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OtpVerificationPage(
                  email: state.email,
                  expiresIn: state.expiresIn,
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            // Social sign-in succeeded, navigate to home
            // TODO: Navigate to home page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signed in successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is AuthError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: state.retryAfter != null
                    ? SnackBarAction(
                        label: 'Retry in ${state.retryAfter}s',
                        textColor: Colors.white,
                        onPressed: () {},
                      )
                    : null,
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

                      // App logo or icon
                      Icon(
                        Icons.video_library_rounded,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Welcome to Video Window',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Sign in to start exploring',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Social sign-in buttons
                      SocialSignInButtons(
                        socialSignInService: _socialSignInService,
                        onFallbackToEmail: () {
                          // Focus email input if social auth fails/cancelled
                          FocusScope.of(context).requestFocus(
                            FocusNode(),
                          );
                        },
                      ),

                      // Email OTP section header
                      Text(
                        'Or continue with email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Email input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'you@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validateEmail,
                        onFieldSubmitted: (_) => _onSubmit(),
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
                                'Send One-Time Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Info text
                      Text(
                        'We\'ll send a 6-digit code to your email that expires in 5 minutes. Check your spam folder if you don\'t see it.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      // Privacy info
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
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
