import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_event.dart';
import 'package:video_window/features/auth/presentation/bloc/mfa_state.dart';
import 'package:video_window/features/auth/presentation/widgets/mfa_sms_setup_widget.dart';
import 'package:video_window/features/auth/presentation/widgets/mfa_totp_setup_widget.dart';
import 'package:video_window/features/auth/presentation/widgets/mfa_backup_codes_widget.dart';

class MfaManagementWidget extends StatefulWidget {
  final String userId;

  const MfaManagementWidget({super.key, required this.userId});

  @override
  State<MfaManagementWidget> createState() => _MfaManagementWidgetState();
}

class _MfaManagementWidgetState extends State<MfaManagementWidget> {
  late MfaBloc _mfaBloc;

  @override
  void initState() {
    super.initState();
    _mfaBloc = MfaBloc(
      MfaService(SecurityAuditService(), Encrypter(Key.fromLength(32))),
      SecurityAuditService(),
    );
    _loadMfaData();
  }

  void _loadMfaData() {
    _mfaBloc.add(MfaGetSecurityStatusEvent(userId: widget.userId));
    _mfaBloc.add(MfaLoadSettingsEvent(userId: widget.userId));
  }

  @override
  void dispose() {
    _mfaBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _mfaBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Two-Factor Authentication',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: BlocBuilder<MfaBloc, MfaState>(
          builder: (context, state) {
            if (state is MfaLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MfaErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading MFA settings',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadMfaData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityStatus(context),
                  const SizedBox(height: 32),
                  _buildSetupMethods(context),
                  const SizedBox(height: 32),
                  _buildBackupCodesSection(context),
                  const SizedBox(height: 32),
                  _buildGracePeriodSection(context),
                  const SizedBox(height: 32),
                  _buildAuditLogSection(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSecurityStatus(BuildContext context) {
    return BlocBuilder<MfaBloc, MfaState>(
      builder: (context, state) {
        Map<String, dynamic> securityStatus = {};
        if (state is MfaSecurityStatusLoadedState) {
          securityStatus = state.securityStatus;
        }

        final isMfaEnabled = securityStatus['mfa_enabled'] ?? false;
        final hasBackupCodes = securityStatus['has_backup_codes'] ?? false;
        final backupCodesRemaining =
            securityStatus['backup_codes_remaining'] ?? 0;
        final isInGracePeriod = securityStatus['in_grace_period'] ?? false;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isMfaEnabled ? Icons.security : Icons.security_outlined,
                      size: 28,
                      color: isMfaEnabled ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Status',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isMfaEnabled ? 'MFA Enabled' : 'MFA Disabled',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isMfaEnabled
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isInGracePeriod)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are in a grace period for MFA setup. Please complete setup soon.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isInGracePeriod) const SizedBox(height: 16),
                if (hasBackupCodes)
                  Row(
                    children: [
                      const Icon(Icons.key, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$backupCodesRemaining backup codes available',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetupMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Methods',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSetupCard(
                context,
                title: 'SMS Verification',
                icon: Icons.sms,
                description: 'Receive verification codes via SMS',
                color: Colors.blue,
                onTap: () => _showSmsSetupDialog(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSetupCard(
                context,
                title: 'Authenticator App',
                icon: Icons.phone_android,
                description:
                    'Use an authenticator app (Google Authenticator, Authy)',
                color: Colors.green,
                onTap: () => _showTotpSetupDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSetupCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupCodesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup Codes',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Generate backup codes for account recovery if you lose access to your MFA device.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showBackupCodesDialog(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Generate Backup Codes'),
          ),
        ),
      ],
    );
  }

  Widget _buildGracePeriodSection(BuildContext context) {
    return BlocBuilder<MfaBloc, MfaState>(
      builder: (context, state) {
        bool isInGracePeriod = false;
        DateTime? gracePeriodExpiry;

        if (state is MfaGracePeriodCheckedState) {
          isInGracePeriod = state.isInGracePeriod;
          gracePeriodExpiry = state.gracePeriodExpiry;
        }

        if (!isInGracePeriod) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grace Period',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Grace Period Active',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have until ${gracePeriodExpiry?.toString()} to complete MFA setup.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _mfaBloc.add(
                              MfaExtendGracePeriodEvent(
                                userId: widget.userId,
                                duration: const Duration(hours: 24),
                              ),
                            );
                          },
                          child: const Text('Extend Grace Period'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _mfaBloc.add(
                              MfaEndGracePeriodEvent(userId: widget.userId),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Setup Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuditLogSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Security Log',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => _showAuditLogDialog(context),
              child: const Text('View Full Log'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Recent security events will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSmsSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: MfaSmsSetupWidget(
            userId: widget.userId,
            mfaBloc: _mfaBloc,
            onComplete: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showTotpSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: MfaTotpSetupWidget(
            userId: widget.userId,
            mfaBloc: _mfaBloc,
            onComplete: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showBackupCodesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: MfaBackupCodesWidget(userId: widget.userId, mfaBloc: _mfaBloc),
        ),
      ),
    );
  }

  void _showAuditLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Security Audit Log'),
              automaticallyImplyLeading: false,
            ),
            body: BlocBuilder<MfaBloc, MfaState>(
              builder: (context, state) {
                if (state is MfaLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MfaAuditLogLoadedState) {
                  if (state.auditLog.isEmpty) {
                    return const Center(
                      child: Text('No security events found'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.auditLog.length,
                    itemBuilder: (context, index) {
                      final event = state.auditLog[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            event.wasSuccessful
                                ? Icons.check_circle
                                : Icons.error,
                            color: event.wasSuccessful
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(event.auditType.name),
                          subtitle: Text(
                            '${event.createdAt.toString()} - ${event.mfaType?.name ?? 'N/A'}',
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('Load audit log to view events'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
