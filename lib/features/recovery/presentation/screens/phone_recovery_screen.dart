import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recovery_bloc.dart';
import '../bloc/recovery_event.dart';
import '../bloc/recovery_state.dart';

class PhoneRecoveryScreen extends StatelessWidget {
  const PhoneRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Recovery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<RecoveryBloc, RecoveryState>(
        listener: (context, state) {
          if (state is PhoneRecoverySent) {
            _showVerificationDialog(context, state.phoneNumber, state.expiresAt);
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
                  Icons.phone,
                  size: 80,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'Recover with Phone',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your phone number and we\'ll send you a verification code to recover your account.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const PhoneRecoveryForm(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVerificationDialog(
    BuildContext context,
    String phoneNumber,
    DateTime expiresAt,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verification Code Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We\'ve sent a verification code to:'),
            const SizedBox(height: 8),
            Text(
              phoneNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('This code will expire at:'),
            Text(
              '${expiresAt.toLocal()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please check your phone and enter the code when prompted.',
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

class PhoneRecoveryForm extends StatefulWidget {
  const PhoneRecoveryForm({super.key});

  @override
  State<PhoneRecoveryForm> createState() => _PhoneRecoveryFormState();
}

class _PhoneRecoveryFormState extends State<PhoneRecoveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+1';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US/Canada'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+81', 'country': 'Japan'},
    {'code': '+86', 'country': 'China'},
    {'code': '+49', 'country': 'Germany'},
    {'code': '+33', 'country': 'France'},
    {'code': '+39', 'country': 'Italy'},
    {'code': '+61', 'country': 'Australia'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  underline: Container(),
                  items: _countryCodes.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Text(country['code']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryCode = value!;
                    });
                  },
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ll send a verification code to $_selectedCountryCode ${_phoneController.text}',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
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
                'Send Verification Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back to Email Recovery'),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';
      context.read<RecoveryBloc>().add(
            PhoneRecoveryRequested(fullPhoneNumber),
          );
    }
  }
}