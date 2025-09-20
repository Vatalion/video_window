import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/auth_bloc.dart';
import '../models/security_audit_model.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  bool _isLoading = false;
  SecurityMetrics? _metrics;
  List<SecurityAlert>? _alerts;
  List<SecurityAuditLog>? _recentLogs;

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);

    try {
      // Mock implementation - load security data
      final now = DateTime.now();
      final periodStart = now.subtract(const Duration(days: 30));
      final periodEnd = now;

      _metrics = SecurityMetrics(
        userId: 'current_user',
        periodStart: periodStart,
        periodEnd: periodEnd,
        totalEvents: 45,
        suspiciousEvents: 2,
        criticalAlerts: 0,
        highRiskEvents: 1,
        averageRiskScore: 25.5,
        eventTypeDistribution: {
          'login': 20,
          'logout': 15,
          'passwordChange': 3,
          'profileUpdate': 7,
        },
        topRiskFactors: ['Multiple login attempts', 'Unusual device'],
        lastSecurityScan: now.subtract(const Duration(hours: 1)),
      );

      _alerts = [
        SecurityAlert(
          id: 'alert_1',
          userId: 'current_user',
          alertType: AlertType.suspiciousLogin,
          title: 'Suspicious Login Attempt',
          description: 'Login attempt from unusual location detected',
          severity: AlertSeverity.medium,
          actionRequired: 'Please verify if this was you',
          createdAt: now.subtract(const Duration(hours: 6)),
          expiresAt: now.add(const Duration(days: 7)),
        ),
      ];

      _recentLogs = [
        SecurityAuditLog(
          id: 'log_1',
          userId: 'current_user',
          eventType: SecurityEventType.login,
          eventDescription: 'Successful login from mobile device',
          ipAddress: '192.168.1.100',
          userAgent: 'Mobile App 1.0.0',
          deviceId: 'device_1',
          riskScore: 20,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        SecurityAuditLog(
          id: 'log_2',
          userId: 'current_user',
          eventType: SecurityEventType.passwordChange,
          eventDescription: 'Password changed successfully',
          ipAddress: '192.168.1.100',
          userAgent: 'Mobile App 1.0.0',
          deviceId: 'device_1',
          riskScore: 30,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
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
            onPressed: _isLoading ? null : _loadSecurityData,
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _runSecurityScan,
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
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildSecurityAlerts(),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                    const SizedBox(height: 16),
                    _buildSecurityMetrics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecurityScoreCard() {
    if (_metrics == null) return const SizedBox();

    final score = _metrics!.securityScore;
    final status = _metrics!.securityStatus;
    final color = _getSecurityScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Score',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        score.round().toString(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildSecurityScoreBreakdown(_metrics!)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityScoreBreakdown(SecurityMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreItem(
          label: 'Total Events',
          value: metrics.totalEvents.toString(),
          color: Colors.blue,
        ),
        const SizedBox(height: 4),
        _buildScoreItem(
          label: 'Suspicious',
          value: metrics.suspiciousEvents.toString(),
          color: Colors.orange,
        ),
        const SizedBox(height: 4),
        _buildScoreItem(
          label: 'Critical Alerts',
          value: metrics.criticalAlerts.toString(),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildScoreItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getSecurityScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.security,
                    label: 'Run Scan',
                    color: Colors.blue,
                    onPressed: _runSecurityScan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.password,
                    label: 'Change Password',
                    color: Colors.green,
                    onPressed: _changePassword,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.devices,
                    label: 'Manage Devices',
                    color: Colors.orange,
                    onPressed: _manageDevices,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.download,
                    label: 'Export Data',
                    color: Colors.purple,
                    onPressed: _exportSecurityData,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildSecurityAlerts() {
    final alerts = _alerts?.where((a) => a.isActive).toList() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Security Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alerts.length} Active',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (alerts.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Active Alerts',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...alerts.map((alert) => _buildAlertCard(alert)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SecurityAlert alert) {
    final color = _getAlertColor(alert.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                Text(
                  _formatTimeAgo(alert.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (alert.actionRequired != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _acknowledgeAlert(alert),
                      child: const Text('Acknowledge'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final logs = _recentLogs ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _viewAllLogs,
                  child: const Text('View All'),
                ),
              ],
            ),
            if (logs.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              ...logs.take(5).map((log) => _buildActivityLog(log)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog(SecurityAuditLog log) {
    final color = _getEventColor(log.eventType, log.wasSuspicious);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.eventDescription,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(log.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    if (log.wasSuspicious)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Suspicious',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetrics() {
    if (_metrics == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Metrics (Last 30 Days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Events',
                    value: _metrics!.totalEvents.toString(),
                    icon: Icons.event,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Suspicious',
                    value: _metrics!.suspiciousEvents.toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Critical Alerts',
                    value: _metrics!.criticalAlerts.toString(),
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg Risk Score',
                    value: _metrics!.averageRiskScore.toStringAsFixed(1),
                    icon: Icons.analytics,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.blue;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.purple;
    }
  }

  Color _getEventColor(SecurityEventType type, bool wasSuspicious) {
    if (wasSuspicious) return Colors.red;

    switch (type) {
      case SecurityEventType.login:
        return Colors.green;
      case SecurityEventType.logout:
        return Colors.blue;
      case SecurityEventType.failedLogin:
        return Colors.orange;
      case SecurityEventType.passwordChange:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM d').format(dateTime);
  }

  Future<void> _runSecurityScan() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security scan completed successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changePassword() async {
    Navigator.of(context).pushNamed('/change_password');
  }

  Future<void> _manageDevices() async {
    Navigator.of(context).pushNamed('/device_management');
  }

  Future<void> _exportSecurityData() async {
    // Mock implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security data export initiated'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _acknowledgeAlert(SecurityAlert alert) async {
    // Mock implementation
    setState(() {
      _alerts?.removeWhere((a) => a.id == alert.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert acknowledged'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAllLogs() {
    Navigator.of(context).pushNamed('/security_logs');
  }
}
