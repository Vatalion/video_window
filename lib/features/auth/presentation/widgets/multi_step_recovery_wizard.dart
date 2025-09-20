import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';

class MultiStepRecoveryWizard extends StatefulWidget {
  const MultiStepRecoveryWizard({super.key});

  @override
  State<MultiStepRecoveryWizard> createState() =>
      _MultiStepRecoveryWizardState();
}

class _MultiStepRecoveryWizardState extends State<MultiStepRecoveryWizard> {
  int _currentStep = 0;
  String? _selectedMethod;
  String? _identifier;
  String _verificationCode = '';
  List<Map<String, String>> _securityAnswers = [];
  String _newPassword = '';
  String _confirmPassword = '';

  final List<Step> _steps = [
    const Step(
      title: Text('Choose Method'),
      content: Text('Select recovery method'),
      isActive: true,
    ),
    const Step(
      title: Text('Verify Identity'),
      content: Text('Verify your identity'),
      isActive: false,
    ),
    const Step(
      title: Text('Security Questions'),
      content: Text('Answer security questions'),
      isActive: false,
    ),
    const Step(
      title: Text('Reset Password'),
      content: Text('Create new password'),
      isActive: false,
    ),
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordResetSuccess || state is PhoneRecoverySuccess) {
            _nextStep();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          steps: _steps,
          onStepContinue: _currentStep < _steps.length - 1 ? _nextStep : null,
          onStepCancel: _currentStep > 0 ? _previousStep : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _previousStep,
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep < _steps.length - 1
                          ? _nextStep
                          : null,
                      child: Text(
                        _currentStep < _steps.length - 1
                            ? 'Continue'
                            : 'Complete',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMethodSelection();
      case 1:
        return _buildVerificationStep();
      case 2:
        return _buildSecurityQuestions();
      case 3:
        return _buildPasswordReset();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMethodSelection() {
    return Column(
      children: [
        const Text(
          'How would you like to recover your account?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        _buildRecoveryMethodCard(
          icon: Icons.email,
          title: 'Email Recovery',
          subtitle: 'Send reset link to your email',
          onTap: () {
            setState(() => _selectedMethod = 'email');
            _nextStep();
          },
        ),
        const SizedBox(height: 12),
        _buildRecoveryMethodCard(
          icon: Icons.phone,
          title: 'Phone Recovery',
          subtitle: 'Send verification code to your phone',
          onTap: () {
            setState(() => _selectedMethod = 'phone');
            _nextStep();
          },
        ),
        const SizedBox(height: 12),
        _buildRecoveryMethodCard(
          icon: Icons.security,
          title: 'Security Questions',
          subtitle: 'Answer your security questions',
          onTap: () {
            setState(() => _selectedMethod = 'security');
            _currentStep = 2; // Skip to security questions
          },
        ),
      ],
    );
  }

  Widget _buildRecoveryMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        const Text(
          'Verify Your Identity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (_selectedMethod == 'email') ...[
          const Text('We\'ll send a reset link to your email address'),
          const SizedBox(height: 24),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _identifier = value),
          ),
        ] else if (_selectedMethod == 'phone') ...[
          const Text('We\'ll send a verification code to your phone'),
          const SizedBox(height: 24),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _identifier = value),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _identifier?.isNotEmpty == true
              ? () {
                  if (_selectedMethod == 'email') {
                    context.read<AuthBloc>().add(
                      RequestPasswordReset(email: _identifier!),
                    );
                  } else {
                    context.read<AuthBloc>().add(
                      RequestPhoneRecovery(phoneNumber: _identifier!),
                    );
                  }
                }
              : null,
          child: Text(
            'Send ${_selectedMethod == 'email' ? 'Reset Link' : 'Verification Code'}',
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityQuestions() {
    return Column(
      children: [
        const Text(
          'Answer Your Security Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // Mock security questions
        _buildSecurityQuestion(
          question: 'What was the name of your first pet?',
          index: 0,
        ),
        const SizedBox(height: 16),
        _buildSecurityQuestion(
          question: 'What city were you born in?',
          index: 1,
        ),
        const SizedBox(height: 16),
        _buildSecurityQuestion(
          question: 'What is your mother\'s maiden name?',
          index: 2,
        ),
      ],
    );
  }

  Widget _buildSecurityQuestion({
    required String question,
    required int index,
  }) {
    final answer = _securityAnswers.length > index
        ? _securityAnswers[index]['answer']
        : '';

    return TextFormField(
      decoration: InputDecoration(
        labelText: question,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          if (_securityAnswers.length <= index) {
            _securityAnswers.add({'question': question, 'answer': value});
          } else {
            _securityAnswers[index]['answer'] = value;
          }
        });
      },
    );
  }

  Widget _buildPasswordReset() {
    return Column(
      children: [
        const Text(
          'Create New Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _newPassword = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _confirmPassword = value),
        ),
        const SizedBox(height: 16),
        PasswordStrengthIndicator(password: _newPassword),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed:
              _newPassword.isNotEmpty &&
                  _confirmPassword.isNotEmpty &&
                  _newPassword == _confirmPassword
              ? () {
                  // Complete password reset
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              : null,
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
