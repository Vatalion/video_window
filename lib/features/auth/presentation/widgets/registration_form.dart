import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/presentation/widgets/password_strength_indicator.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEmailMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _ageVerified = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _ageVerified && _termsAccepted) {
      if (_isEmailMode) {
        context.read<AuthBloc>().add(
          RegisterWithEmailEvent(
            email: _emailController.text,
            password: _passwordController.text,
            ageVerified: _ageVerified,
          ),
        );
      } else {
        context.read<AuthBloc>().add(
          RegisterWithPhoneEvent(
            phone: _phoneController.text,
            password: _passwordController.text,
            ageVerified: _ageVerified,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Registration Type Toggle
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailMode
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isEmailMode = true),
                  child: const Text('Email'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isEmailMode
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isEmailMode = false),
                  child: const Text('Phone'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Email or Phone Field
          if (_isEmailMode)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            )
          else
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\+?1?\d{9,15}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Strength Indicator
          PasswordStrengthIndicator(password: _passwordController.text),
          const SizedBox(height: 24),

          // Age Verification Checkbox
          CheckboxListTile(
            title: const Text('I confirm that I am 13 years of age or older'),
            value: _ageVerified,
            onChanged: (value) => setState(() => _ageVerified = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),

          // Terms and Conditions Checkbox
          CheckboxListTile(
            title: const Text(
              'I accept the Terms of Service and Privacy Policy',
            ),
            value: _termsAccepted,
            onChanged: (value) =>
                setState(() => _termsAccepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
