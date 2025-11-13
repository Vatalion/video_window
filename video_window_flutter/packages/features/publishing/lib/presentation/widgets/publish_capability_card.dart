import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/design_system/tokens.dart';
import 'package:profile/presentation/capability_center/bloc/capability_center_bloc.dart';
import 'package:profile/presentation/capability_center/bloc/capability_center_event.dart';
import 'package:profile/presentation/capability_center/bloc/capability_center_state.dart';
import 'persona_verification_widget.dart';

/// Inline prompt card in publish flow when capability is missing
///
/// AC1: Displays inline verification card summarizing blockers and primary CTA
/// AC2: Launches Persona verification from the card with proper branding
/// AC3: Listens to capability changes and updates UI when publish capability is enabled
/// AC4: Handles error states (rejected, timeout, cancelled) with actionable messaging
///
/// Story 2-2 Fix: Now integrates with CapabilityCenterBloc to auto-update when capability is enabled
class PublishCapabilityCard extends StatefulWidget {
  final int userId;
  final String? draftId;
  final String? capabilityRequestId;
  final VoidCallback onRequestCapability;
  final VoidCallback? onDismiss;
  final Function(String status)? onVerificationStatusChanged;
  final List<String> blockers;
  final Map<String, String> blockerMessages;

  const PublishCapabilityCard({
    super.key,
    required this.userId,
    this.draftId,
    this.capabilityRequestId,
    required this.onRequestCapability,
    this.onDismiss,
    this.onVerificationStatusChanged,
    this.blockers = const [],
    this.blockerMessages = const {},
  });

  @override
  State<PublishCapabilityCard> createState() => _PublishCapabilityCardState();
}

class _PublishCapabilityCardState extends State<PublishCapabilityCard> {
  String?
      _verificationStatus; // 'not_started', 'in_progress', 'completed', 'rejected'
  String? _errorMessage;
  bool _isPolling = false;

  @override
  void dispose() {
    // Stop polling when widget is disposed
    if (_isPolling) {
      context
          .read<CapabilityCenterBloc>()
          .add(const CapabilityCenterPollingStopped());
    }
    super.dispose();
  }

  /// Start polling for capability updates
  ///
  /// AC3: Start polling when verification is in progress to detect when capability is enabled
  void _startPolling() {
    if (!_isPolling) {
      context
          .read<CapabilityCenterBloc>()
          .add(CapabilityCenterPollingStarted(widget.userId));
      setState(() {
        _isPolling = true;
      });
    }
  }

  /// Stop polling for capability updates
  void _stopPolling() {
    if (_isPolling) {
      context
          .read<CapabilityCenterBloc>()
          .add(const CapabilityCenterPollingStopped());
      setState(() {
        _isPolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // AC3: Listen to capability changes - when canPublish becomes true, notify parent
    return BlocListener<CapabilityCenterBloc, CapabilityCenterState>(
      listener: (context, state) {
        if (state is CapabilityCenterLoaded) {
          // If publish capability is now enabled and we were in progress, mark as completed
          if (state.canPublish &&
              (_verificationStatus == 'in_progress' || _isPolling)) {
            setState(() {
              _verificationStatus = 'completed';
            });
            _stopPolling();
            widget.onVerificationStatusChanged?.call('completed');
            // Optionally auto-dismiss the card
            widget.onDismiss?.call();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Card(
          elevation: AppElevation.md,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.lg),
                _buildBlockersList(),
                const SizedBox(height: AppSpacing.lg),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: _getHeaderColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            _getHeaderIcon(),
            color: _getHeaderColor(),
            size: 32,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitle(),
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _getSubtitle(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
        if (widget.onDismiss != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onDismiss,
            color: AppColors.neutral500,
          ),
      ],
    );
  }

  Widget _buildBlockersList() {
    if (widget.blockers.isEmpty && widget.blockerMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements:',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...widget.blockerMessages.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _verificationStatus == 'completed'
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: 20,
                  color: _verificationStatus == 'completed'
                      ? AppColors.success
                      : AppColors.neutral500,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.value,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    // If verification is in progress, show status
    if (_verificationStatus == 'in_progress') {
      return Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Verification in progress...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      );
    }

    // If verification was rejected, show retry option
    if (_verificationStatus == 'rejected') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                color: AppColors.error.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRetryVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Retry Verification'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // Link to support
                // TODO: Navigate to support page
              },
              child: const Text('Contact Support'),
            ),
          ),
        ],
      );
    }

    // Default: Show verification launch button
    if (widget.capabilityRequestId != null) {
      return PersonaVerificationWidget(
        capabilityRequestId: widget.capabilityRequestId!,
        draftId: widget.draftId,
        onVerificationStarted: (verificationId) {
          setState(() {
            _verificationStatus = 'in_progress';
          });
          // AC3: Start polling to detect when capability is enabled
          _startPolling();
          widget.onVerificationStatusChanged?.call('in_progress');
        },
        onVerificationCompleted: (status, metadata) {
          setState(() {
            _verificationStatus = status;
            if (status == 'rejected' || status == 'failed') {
              _errorMessage = metadata?['reason'] as String? ??
                  'Verification was not approved. Please try again or contact support.';
            }
          });
          // Stop polling on completion (success or failure)
          _stopPolling();
          widget.onVerificationStatusChanged?.call(status);
        },
        onError: (error) {
          setState(() {
            _verificationStatus = 'failed';
            _errorMessage = error;
          });
          _stopPolling();
          widget.onVerificationStatusChanged?.call('failed');
        },
      );
    }

    // Fallback: Show request capability button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onRequestCapability,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: const Text('Enable Publishing'),
      ),
    );
  }

  void _handleRetryVerification() {
    setState(() {
      _verificationStatus = null;
      _errorMessage = null;
    });
    // Reset polling state for retry
    _stopPolling();
    widget.onRequestCapability();
  }

  Color _getBorderColor() {
    switch (_verificationStatus) {
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'failed':
        return AppColors.error;
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  Color _getHeaderColor() {
    switch (_verificationStatus) {
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'failed':
        return AppColors.error;
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  IconData _getHeaderIcon() {
    switch (_verificationStatus) {
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
      case 'failed':
        return Icons.error_outline;
      case 'in_progress':
        return Icons.hourglass_empty;
      default:
        return Icons.lock_outline;
    }
  }

  String _getTitle() {
    switch (_verificationStatus) {
      case 'completed':
        return 'Verification Complete';
      case 'rejected':
        return 'Verification Rejected';
      case 'failed':
        return 'Verification Failed';
      case 'in_progress':
        return 'Verification In Progress';
      default:
        return 'Publishing Locked';
    }
  }

  String _getSubtitle() {
    switch (_verificationStatus) {
      case 'completed':
        return 'You can now publish your story';
      case 'rejected':
        return 'Please review the requirements and try again';
      case 'failed':
        return 'Something went wrong. Please try again';
      case 'in_progress':
        return 'Please complete the verification process';
      default:
        return 'Complete these steps to publish your story';
    }
  }
}
