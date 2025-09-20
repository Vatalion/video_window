import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:email_validator/email_validator.dart';
import '../../bloc/auth_bloc.dart';

class PasswordResetRequest extends StatefulWidget {
  const PasswordResetRequest({super.key});

  @override
  State<PasswordResetRequest> createState() => _PasswordResetRequestState();
}

class _PasswordResetRequestState extends State<PasswordResetRequest> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _selectedMethod = 'email';

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedMethod == 'email') {
        context.read<AuthBloc>().add(
          RequestPasswordReset(email: _emailController.text.trim()),
        );
      } else {
        context.read<AuthBloc>().add(
          RequestPhoneRecovery(phoneNumber: _phoneController.text.trim()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent to your email'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is PhoneRecoverySuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your phone'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reset Password'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Reset Your Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose how you\'d like to receive your reset instructions',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildRecoveryMethodSelector(),
                const SizedBox(height: 32),
                _buildRecoveryForm(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitResetRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Send Reset ${_selectedMethod == 'email' ? 'Email' : 'Code'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recovery Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMethod = 'email'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedMethod == 'email'
                        ? Colors.blue
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedMethod == 'email'
                          ? Colors.blue
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.email,
                        size: 32,
                        color: _selectedMethod == 'email'
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedMethod == 'email'
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMethod = 'phone'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedMethod == 'phone'
                        ? Colors.blue
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedMethod == 'phone'
                          ? Colors.blue
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 32,
                        color: _selectedMethod == 'phone'
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedMethod == 'phone'
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecoveryForm() {
    if (_selectedMethod == 'email') {
      return TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          hintText: 'Enter your email address',
          prefixIcon: Icon(Icons.email),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your email address';
          }
          if (!EmailValidator.validate(value.trim())) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      );
    } else {
      return TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          hintText: 'Enter your phone number',
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your phone number';
          }
          if (value.trim().length < 10) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
      );
    }
  }
}
