import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recovery_bloc.dart';
import '../bloc/recovery_event.dart';
import '../bloc/recovery_state.dart';

class EmailRecoveryScreen extends StatelessWidget {
  const EmailRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Recovery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<RecoveryBloc, RecoveryState>(
        listener: (context, state) {
          if (state is EmailRecoverySent) {
            _showSuccessDialog(context, state.email, state.expiresAt);
          } else if (state is RecoveryFailed) {
            _showErrorDialog(context, state.error);
          } else if (state is AccountLocked) {
            _showAccountLockedDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is RecoveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.email,
                  size: 80,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset Your Password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const EmailRecoveryForm(),
                const SizedBox(height: 24),
                const AlternativeRecoveryMethods(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    String email,
    DateTime expiresAt,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Email Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We\'ve sent a recovery link to:'),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('This link will expire at:'),
            Text(
              '${expiresAt.toLocal()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please check your email and follow the instructions to reset your password.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAccountLockedDialog(BuildContext context, AccountLocked state) {
    String lockMessage;
    if (state.lockStatus == AccountLockStatus.lockedTemporary &&
        state.lockedUntil != null) {
      lockMessage =
          'Your account is temporarily locked until ${state.lockedUntil!.toLocal()}.';
    } else {
      lockMessage = 'Your account has been locked due to suspicious activity.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Locked'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lockMessage),
            const SizedBox(height: 16),
            const Text(
              'Please contact support or try again later.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class EmailRecoveryForm extends StatefulWidget {
  const EmailRecoveryForm({super.key});

  @override
  State<EmailRecoveryForm> createState() => _EmailRecoveryFormState();
}

class _EmailRecoveryFormState extends State<EmailRecoveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Recovery Email',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<RecoveryBloc>().add(
            EmailRecoveryRequested(_emailController.text.trim()),
          );
    }
  }
}

class AlternativeRecoveryMethods extends StatelessWidget {
  const AlternativeRecoveryMethods({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Other Recovery Options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildRecoveryOption(
          context,
          Icons.phone,
          'Phone Recovery',
          'Recover using your phone number',
          () {
            // Navigate to phone recovery
          },
        ),
        const SizedBox(height: 12),
        _buildRecoveryOption(
          context,
          Icons.security,
          'Security Questions',
          'Answer security questions',
          () {
            // Navigate to security questions
          },
        ),
      ],
    );
  }

  Widget _buildRecoveryOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}