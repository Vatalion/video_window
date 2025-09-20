import 'package:flutter/material.dart';
import '../../domain/models/checkout_security_model.dart';

class CheckoutSecurityBanner extends StatelessWidget {
  final SecurityContextModel securityContext;
  final SecurityValidationResult? securityValidation;
  final VoidCallback? onRefreshSecurity;
  final VoidCallback? onUpgradeSecurity;

  const CheckoutSecurityBanner({
    required this.securityContext,
    this.securityValidation,
    this.onRefreshSecurity,
    this.onUpgradeSecurity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getSecurityColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _getSecurityColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecurityHeader(context),
              const SizedBox(height: 12),
              _buildSecurityDetails(),
              if (securityValidation != null) ...[
                const SizedBox(height: 12),
                _buildSecurityValidation(),
              ],
              const SizedBox(height: 12),
              _buildSecurityActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSecurityColor().withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getSecurityIcon(),
            color: _getSecurityColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${securityContext.securityLevel.name.toUpperCase()} Protection',
                style: TextStyle(
                  color: _getSecurityColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (onRefreshSecurity != null)
          IconButton(
            onPressed: onRefreshSecurity,
            icon: Icon(
              Icons.refresh,
              color: _getSecurityColor(),
              size: 20,
            ),
            tooltip: 'Refresh Security Status',
          ),
      ],
    );
  }

  Widget _buildSecurityDetails() {
    return Column(
      children: [
        _buildSecurityDetailRow(
          'Device ID',
          _obfuscateDeviceId(securityContext.deviceFingerprint),
          Icons.devices,
        ),
        _buildSecurityDetailRow(
          'Session Started',
          _formatDateTime(securityContext.lastActivity),
          Icons.access_time,
        ),
        _buildSecurityDetailRow(
          'Failed Attempts',
          '${securityContext.failedAttempts}',
          Icons.warning_amber,
          isWarning: securityContext.failedAttempts > 0,
        ),
        if (securityContext.isLocked)
          _buildSecurityDetailRow(
            'Account Locked',
            'Until ${_formatDateTime(securityContext.lockedUntil!)}',
            Icons.lock,
            isWarning: true,
          ),
      ],
    );
  }

  Widget _buildSecurityDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isWarning ? Colors.orange : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 12,
                color: isWarning ? Colors.orange.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityValidation() {
    if (securityValidation!.isValid) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade700,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Security validation passed',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Security validation failed',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (securityValidation!.violations.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${securityValidation!.violations.length} violation(s) detected',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildSecurityActions(BuildContext context) {
    final canUpgrade = securityContext.securityLevel != SecurityLevel.maximum;
    final needsAttention = securityContext.failedAttempts > 0 ||
        securityContext.isLocked ||
        (securityValidation != null && !securityValidation!.isValid);

    return Row(
      children: [
        if (needsAttention)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Show security details or recommendations
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Security attention required. Check settings.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber, size: 16),
              label: const Text('Review Security'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        if (needsAttention) const SizedBox(width: 8),
        if (canUpgrade && onUpgradeSecurity != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onUpgradeSecurity,
              icon: const Icon(Icons.upgrade, size: 16),
              label: const Text('Upgrade Security'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
      ],
    );
  }

  Color _getSecurityColor() {
    switch (securityContext.securityLevel) {
      case SecurityLevel.maximum:
        return Colors.green;
      case SecurityLevel.high:
        return Colors.blue;
      case SecurityLevel.standard:
        return Colors.orange;
      case SecurityLevel.low:
        return Colors.red;
    }
  }

  IconData _getSecurityIcon() {
    switch (securityContext.securityLevel) {
      case SecurityLevel.maximum:
        return Icons.security;
      case SecurityLevel.high:
        return Icons.shield;
      case SecurityLevel.standard:
        return Icons.lock_outline;
      case SecurityLevel.low:
        return Icons.warning;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    }
  }

  String _obfuscateDeviceId(String deviceId) {
    if (deviceId.length <= 8) return deviceId;
    return '${deviceId.substring(0, 4)}...${deviceId.substring(deviceId.length - 4)}';
  }
}

class RealTimeSecurityMonitor extends StatefulWidget {
  final SecurityContextModel securityContext;
  final Function(SecurityContextModel) onSecurityUpdate;
  final Duration updateInterval;

  const RealTimeSecurityMonitor({
    required this.securityContext,
    required this.onSecurityUpdate,
    this.updateInterval = const Duration(seconds: 30),
    super.key,
  });

  @override
  State<RealTimeSecurityMonitor> createState() => _RealTimeSecurityMonitorState();
}

class _RealTimeSecurityMonitorState extends State<RealTimeSecurityMonitor> {
  late Timer _updateTimer;
  late SecurityContextModel _currentSecurityContext;

  @override
  void initState() {
    super.initState();
    _currentSecurityContext = widget.securityContext;
    _startSecurityMonitoring();
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  void _startSecurityMonitoring() {
    _updateTimer = Timer.periodic(widget.updateInterval, (timer) {
      _updateSecurityContext();
    });
  }

  void _updateSecurityContext() {
    // Simulate security context updates
    // In a real implementation, this would check for real security events
    final updatedContext = _currentSecurityContext.copyWith(
      lastActivity: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _currentSecurityContext = updatedContext;
      });

      widget.onSecurityUpdate(updatedContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutSecurityBanner(
      securityContext: _currentSecurityContext,
      onRefreshSecurity: _updateSecurityContext,
    );
  }
}