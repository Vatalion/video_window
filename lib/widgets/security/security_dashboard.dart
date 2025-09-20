import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/security/security_audit_log.dart';
import '../../models/security/security_alert.dart';
import '../../services/security/security_audit_service.dart';
import '../../services/security/security_notification_service.dart';

class SecurityDashboard extends StatefulWidget {
  final String userId;
  final SecurityAuditService auditService;
  final SecurityNotificationService notificationService;

  const SecurityDashboard({
    super.key,
    required this.userId,
    required this.auditService,
    required this.notificationService,
  });

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  List<SecurityAuditLog> _recentLogs = [];
  List<SecurityAlert> _activeAlerts = [];
  Map<String, int> _eventStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
    widget.notificationService.addAlertListener(_onNewAlert);
  }

  @override
  void dispose() {
    widget.notificationService.removeAlertListener(_onNewAlert);
    super.dispose();
  }

  void _onNewAlert(SecurityAlert alert) {
    if (alert.userId == widget.userId) {
      setState(() {
        _activeAlerts.add(alert);
      });
    }
  }

  Future<void> _loadSecurityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _recentLogs = widget.auditService.getAuditLogs(
        userId: widget.userId,
        limit: 10,
      );

      _activeAlerts = widget.notificationService.getActiveAlerts(userId: widget.userId);

      _eventStats = widget.auditService.getEventStatistics(userId: widget.userId);
    } catch (e) {
      debugPrint('Error loading security data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSecurityData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSecurityData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecurityScoreCard(),
                    const SizedBox(height: 24),
                    _buildActiveAlertsCard(),
                    const SizedBox(height: 24),
                    _buildEventStatisticsCard(),
                    const SizedBox(height: 24),
                    _buildRecentActivityCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecurityScoreCard() {
    final riskScore = _calculateRiskScore();
    final securityLevel = _getSecurityLevel(riskScore);
    final color = _getSecurityColor(securityLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Security Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${(riskScore * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        securityLevel,
                        style: TextStyle(
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getSecurityIcon(securityLevel),
                  size: 48,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: riskScore,
              backgroundColor: Colors.grey[300],
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRiskScore() {
    if (_activeAlerts.isNotEmpty) {
      return 0.3; // Low score if there are active alerts
    }

    final totalEvents = _eventStats.values.fold(0, (a, b) => a + b);
    final failedLogins = _eventStats['failed_login'] ?? 0;

    if (totalEvents == 0) return 1.0;

    return (totalEvents - failedLogins) / totalEvents;
  }

  String _getSecurityLevel(double score) {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Fair';
    return 'Poor';
  }

  Color _getSecurityColor(String level) {
    switch (level) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getSecurityIcon(String level) {
    switch (level) {
      case 'Excellent':
        return Icons.shield;
      case 'Good':
        return Icons.security;
      case 'Fair':
        return Icons.warning;
      default:
        return Icons.dangerous;
    }
  }

  Widget _buildActiveAlertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Active Security Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_activeAlerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_activeAlerts.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_activeAlerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No active security alerts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeAlerts.length,
                itemBuilder: (context, index) {
                  final alert = _activeAlerts[index];
                  return _buildAlertItem(alert);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(SecurityAlert alert) {
    return Card(
      color: _getAlertColor(alert.severity),
      child: ListTile(
        leading: Icon(_getAlertIcon(alert.alertType), color: Colors.white),
        title: Text(
          alert.message,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy HH:mm').format(alert.timestamp),
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'acknowledge':
                await widget.notificationService.acknowledgeAlert(
                  alert.id,
                  'user',
                );
                _loadSecurityData();
                break;
              case 'dismiss':
                await widget.notificationService.dismissAlert(
                  alert.id,
                  'user',
                );
                _loadSecurityData();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'acknowledge',
              child: Text('Acknowledge'),
            ),
            const PopupMenuItem(
              value: 'dismiss',
              child: Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(double severity) {
    if (severity >= 0.8) return Colors.red;
    if (severity >= 0.6) return Colors.orange;
    return Colors.yellow[700]!;
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.unusualLoginLocation:
        return Icons.location_on;
      case AlertType.multipleFailedAttempts:
        return Icons.warning;
      case AlertType.suspiciousDevice:
        return Icons.devices;
      case AlertType.passwordStrengthWeak:
        return Icons.password;
      default:
        return Icons.security;
    }
  }

  Widget _buildEventStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Event Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_eventStats.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No security events recorded',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _eventStats.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Security Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No recent security activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentLogs.length,
                itemBuilder: (context, index) {
                  final log = _recentLogs[index];
                  return _buildActivityItem(log);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(SecurityAuditLog log) {
    return ListTile(
      leading: Icon(_getActivityIcon(log.eventType)),
      title: Text(log.eventType.replaceAll('_', ' ').toUpperCase()),
      subtitle: Text(
        '${DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp)} - ${log.ipAddress}',
      ),
      trailing: log.riskScore > 0.5
          ? Icon(Icons.warning, color: Colors.orange[700])
          : null,
    );
  }

  IconData _getActivityIcon(String eventType) {
    switch (eventType) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'password_change':
        return Icons.password;
      case 'account_lockout':
        return Icons.lock;
      case 'suspicious_activity':
        return Icons.warning;
      default:
        return Icons.security;
    }
  }
}