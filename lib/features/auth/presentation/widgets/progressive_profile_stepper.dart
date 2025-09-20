import 'package:flutter/material.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';

class ProgressiveProfileStepper extends StatefulWidget {
  final UserModel user;
  final ValueChanged<int> onStepChanged;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;

  const ProgressiveProfileStepper({
    super.key,
    required this.user,
    required this.onStepChanged,
    required this.onProfileUpdated,
  });

  @override
  State<ProgressiveProfileStepper> createState() =>
      _ProgressiveProfileStepperState();
}

class _ProgressiveProfileStepperState extends State<ProgressiveProfileStepper> {
  int _currentStep = 0;
  final Map<String, dynamic> _profileData = {};

  final List<Step> _steps = [
    Step(
      title: const Text('Basic Info'),
      content: _buildBasicInfoStep(),
      isActive: true,
    ),
    Step(
      title: const Text('Preferences'),
      content: _buildPreferencesStep(),
      isActive: true,
    ),
    Step(
      title: const Text('Security'),
      content: _buildSecurityStep(),
      isActive: true,
    ),
  ];

  static Widget _buildBasicInfoStep() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'First Name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Last Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          keyboardType: TextInputType.datetime,
        ),
      ],
    );
  }

  static Widget _buildPreferencesStep() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Enable email notifications'),
          value: true,
          onChanged: (value) {},
        ),
        CheckboxListTile(
          title: const Text('Enable SMS notifications'),
          value: false,
          onChanged: (value) {},
        ),
        CheckboxListTile(
          title: const Text('Enable marketing communications'),
          value: false,
          onChanged: (value) {},
        ),
      ],
    );
  }

  static Widget _buildSecurityStep() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Enable Two-Factor Authentication'),
          subtitle: const Text(
            'Add an extra layer of security to your account',
          ),
          trailing: Switch(value: false, onChanged: (value) {}),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.fingerprint),
          title: const Text('Enable Biometric Login'),
          subtitle: const Text('Use Face ID or Touch ID to sign in'),
          trailing: Switch(value: false, onChanged: (value) {}),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStep + 1) / _steps.length,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 24),
        Text(
          'Step ${_currentStep + 1} of ${_steps.length}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Complete your profile to get started',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Stepper(
            currentStep: _currentStep,
            steps: _steps,
            onStepContinue: () {
              if (_currentStep < _steps.length - 1) {
                setState(() {
                  _currentStep++;
                  widget.onStepChanged(_currentStep);
                });
              } else {
                // Complete profile setup
                widget.onProfileUpdated(_profileData);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep--;
                  widget.onStepChanged(_currentStep);
                });
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(
                        _currentStep == _steps.length - 1
                            ? 'Complete'
                            : 'Continue',
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
