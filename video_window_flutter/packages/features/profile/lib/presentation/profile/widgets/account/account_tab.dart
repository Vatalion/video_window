import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import 'otp_confirmation_modal.dart';
import 'dsar_export_status_banner.dart';
import 'trusted_devices_list.dart';
import 'session_revocation_section.dart';

/// Account tab widget for DSAR and account management
/// AC1: Account settings tab offers DSAR export, DSAR deletion, session revocation, and trusted device list management
class AccountTab extends StatelessWidget {
  final int userId;
  final DateTime? lastAuthTime;

  const AccountTab({
    super.key,
    required this.userId,
    this.lastAuthTime,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DSAR Export Status Banner
              const DSARExportStatusBanner(),
              const SizedBox(height: 24),

              // Data Management Section
              _buildDataManagementSection(context, state),
              const SizedBox(height: 24),

              // Session Management Section
              SessionRevocationSection(userId: userId),
              const SizedBox(height: 24),

              // Trusted Devices Section
              TrustedDevicesList(userId: userId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataManagementSection(
    BuildContext context,
    ProfileState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Data Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Request a copy of your data or delete your account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // DSAR Export Button
        ElevatedButton.icon(
          onPressed: () => _handleDSARExport(context),
          icon: const Icon(Icons.download),
          label: const Text('Export My Data'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Account Deletion Button
        OutlinedButton.icon(
          onPressed: () => _handleAccountDeletion(context),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            'Delete My Account',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void _handleDSARExport(BuildContext context) {
    // Check if re-authentication is required
    final requiresReAuth = _requiresReAuthentication();

    if (requiresReAuth) {
      // Show OTP confirmation modal
      showDialog(
        context: context,
        builder: (context) => OTPConfirmationModal(
          userId: userId,
          onVerified: () {
            Navigator.pop(context);
            context.read<ProfileBloc>().add(
                  DSARExportRequested(userId),
                );
          },
        ),
      );
    } else {
      // Directly request export
      context.read<ProfileBloc>().add(
            DSARExportRequested(userId),
          );
    }
  }

  void _handleAccountDeletion(BuildContext context) {
    // Check if re-authentication is required
    final requiresReAuth = _requiresReAuthentication();

    if (requiresReAuth) {
      // Show OTP confirmation modal
      showDialog(
        context: context,
        builder: (context) => OTPConfirmationModal(
          userId: userId,
          onVerified: () {
            Navigator.pop(context);
            _showAccountDeletionConfirmation(context);
          },
        ),
      );
    } else {
      _showAccountDeletionConfirmation(context);
    }
  }

  void _showAccountDeletionConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.\n\n'
          'All your personal data will be permanently deleted, including:\n'
          '• Your profile information\n'
          '• Your privacy settings\n'
          '• Your notification preferences\n'
          '• Your uploaded media\n\n'
          'Some anonymized records may be retained for legal compliance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileBloc>().add(
                    AccountDeletionRequested(userId),
                  );
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  bool _requiresReAuthentication() {
    if (lastAuthTime == null) return true;
    final sessionAge = DateTime.now().difference(lastAuthTime!);
    return sessionAge.inMinutes > 10;
  }
}
