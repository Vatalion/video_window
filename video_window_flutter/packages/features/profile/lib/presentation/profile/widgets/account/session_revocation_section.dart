import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';

/// Session revocation section for managing active sessions
/// AC1: Account settings tab offers session revocation
class SessionRevocationSection extends StatelessWidget {
  final int userId;

  const SessionRevocationSection({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Active Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your active sessions and sign out from other devices',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _revokeAllSessions(context),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out from All Devices'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  void _revokeAllSessions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out from All Devices'),
        content: const Text(
          'This will sign you out from all devices except this one. '
          'You will need to sign in again on other devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileBloc>().add(
                    RevokeAllSessionsRequested(userId),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All sessions revoked successfully'),
                ),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
