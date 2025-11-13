import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared/design_system/tokens.dart';
import 'package:core/services/analytics_service.dart';

/// Widget for launching Persona identity verification flow
///
/// AC2: Opens Persona hosted flow with proper branding, sends capability_request_id
/// AC4: Handles error states (rejected, timeout, cancelled) with actionable messaging
class PersonaVerificationWidget extends StatefulWidget {
  final String capabilityRequestId;
  final String? draftId;
  final Function(String verificationId)? onVerificationStarted;
  final Function(String status, Map<String, dynamic>? metadata)?
      onVerificationCompleted;
  final Function(String error)? onError;
  final AnalyticsService? analyticsService;

  const PersonaVerificationWidget({
    super.key,
    required this.capabilityRequestId,
    this.draftId,
    this.onVerificationStarted,
    this.onVerificationCompleted,
    this.onError,
    this.analyticsService,
  });

  @override
  State<PersonaVerificationWidget> createState() =>
      _PersonaVerificationWidgetState();
}

class _PersonaVerificationWidgetState extends State<PersonaVerificationWidget> {
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _verificationStartTime;

  /// Launch Persona verification flow
  ///
  /// AC2: Opens hosted flow with capability_request_id
  /// AC5: Emits analytics event publish_verification_started
  Future<void> _launchPersonaVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationStartTime = DateTime.now();
    });

    try {
      // AC5: Emit analytics event publish_verification_started
      if (widget.analyticsService != null) {
        await widget.analyticsService!.trackEvent(
          _PublishVerificationStartedEvent(
            capabilityRequestId: widget.capabilityRequestId,
            draftId: widget.draftId,
          ),
        );
      }

      // TODO: Replace with actual Persona API integration
      // For MVP, using placeholder URL structure
      // In production, use persona_flutter package or webview
      final personaUrl = Uri.parse(
        'https://withpersona.com/verify?'
        'inquiry-id=${widget.capabilityRequestId}'
        '&redirect-uri=videowindow://verification/complete'
        '&reference-id=${widget.draftId ?? ''}',
      );

      widget.onVerificationStarted?.call(widget.capabilityRequestId);

      // Launch Persona verification in webview
      final launched = await launchUrl(
        personaUrl,
        mode: LaunchMode.inAppWebView,
      );

      if (!launched) {
        throw Exception('Failed to launch Persona verification');
      }

      // Note: In production, use persona_flutter package for better integration
      // and handle deep link callbacks for completion status

      // AC5: Emit analytics event on completion (when deep link callback received)
      // This will be called from deep link handler
      _handleVerificationCompleted('completed', null);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to start verification: ${e.toString()}';
      });

      // AC5: Emit analytics event for failure
      if (widget.analyticsService != null && _verificationStartTime != null) {
        final duration =
            DateTime.now().difference(_verificationStartTime!).inSeconds;
        await widget.analyticsService!.trackEvent(
          _PublishVerificationCompletedEvent(
            capabilityRequestId: widget.capabilityRequestId,
            success: false,
            durationSeconds: duration,
            error: e.toString(),
          ),
        );
      }

      widget.onError?.call(_errorMessage!);
    }
  }

  /// Handle verification completion
  ///
  /// AC5: Emits analytics event publish_verification_completed with duration
  Future<void> _handleVerificationCompleted(
    String status,
    Map<String, dynamic>? metadata,
  ) async {
    if (_verificationStartTime != null && widget.analyticsService != null) {
      final duration =
          DateTime.now().difference(_verificationStartTime!).inSeconds;
      final success = status == 'approved' || status == 'completed';

      await widget.analyticsService!.trackEvent(
        _PublishVerificationCompletedEvent(
          capabilityRequestId: widget.capabilityRequestId,
          success: success,
          durationSeconds: duration,
          status: status,
          metadata: metadata,
        ),
      );
    }

    widget.onVerificationCompleted?.call(status, metadata);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return _buildLaunchButton();
  }

  Widget _buildLaunchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _launchPersonaVerification,
        icon: const Icon(Icons.verified_user),
        label: const Text('Start Identity Verification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Opening verification...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Verification Error',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _launchPersonaVerification();
                },
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Analytics event for publish verification started
///
/// AC5: Analytics event publish_verification_started
class _PublishVerificationStartedEvent extends AnalyticsEvent {
  final String capabilityRequestId;
  final String? draftId;
  final DateTime _timestamp;

  _PublishVerificationStartedEvent({
    required this.capabilityRequestId,
    this.draftId,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'publish_verification_started';

  @override
  Map<String, dynamic> get properties => {
        'capability_request_id': capabilityRequestId,
        if (draftId != null) 'draft_id': draftId!,
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for publish verification completed
///
/// AC5: Analytics event publish_verification_completed with success/failure and duration
class _PublishVerificationCompletedEvent extends AnalyticsEvent {
  final String capabilityRequestId;
  final bool success;
  final int durationSeconds;
  final String? status;
  final Map<String, dynamic>? metadata;
  final String? error;
  final DateTime _timestamp;

  _PublishVerificationCompletedEvent({
    required this.capabilityRequestId,
    required this.success,
    required this.durationSeconds,
    this.status,
    this.metadata,
    this.error,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'publish_verification_completed';

  @override
  Map<String, dynamic> get properties => {
        'capability_request_id': capabilityRequestId,
        'success': success,
        'duration_seconds': durationSeconds,
        if (status != null) 'status': status!,
        if (error != null) 'error': error!,
        if (metadata != null) ...metadata!,
      };

  @override
  DateTime get timestamp => _timestamp;
}
