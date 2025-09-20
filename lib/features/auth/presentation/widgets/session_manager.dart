import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/auth_bloc.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/session_activity_model.dart';

class SessionManager extends StatefulWidget {
  final String userId;

  const SessionManager({super.key, required this.userId});

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  bool _isLoading = false;
  List<SessionModel> _sessions = [];
  List<SessionActivityModel> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SessionTerminated) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session terminated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSessions();
        } else if (state is AuthError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Session Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadSessions,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSessionSummary(),
            const Divider(),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Active Sessions'),
                        Tab(text: 'Recent Activity'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [_buildSessionsList(), _buildActivityList()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoading ? null : _terminateAllSessions,
          backgroundColor: Colors.red,
          child: const Icon(Icons.logout_all),
        ),
      ),
    );
  }

  Widget _buildSessionSummary() {
    final activeSessions = _sessions.where((s) => s.isActive).length;
    final totalSessions = _sessions.length;
    final securityAlerts = _recentActivities
        .where((a) => a.isSecurityEvent)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.session, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Session Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.active_session,
                  label: 'Active Sessions',
                  value: activeSessions.toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.history,
                  label: 'Total Sessions',
                  value: totalSessions.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.warning,
                  label: 'Security Alerts',
                  value: securityAlerts.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.session_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No active sessions',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recent sessions will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            session.isActive
                                ? Icons.active_session
                                : Icons.inactive_session,
                            color: session.isActive
                                ? Colors.green
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Session ${session.id.substring(0, 8)}...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                session.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              session.activityStatus,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(session.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device: ${session.deviceId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'terminate':
                        await _terminateSession(session);
                        break;
                      case 'view_activity':
                        await _viewSessionActivity(session);
                        break;
                      case 'extend':
                        await _extendSession(session);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view_activity',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Activity'),
                        ],
                      ),
                    ),
                    if (session.isActive)
                      const PopupMenuItem(
                        value: 'extend',
                        child: Row(
                          children: [
                            Icon(Icons.access_time),
                            SizedBox(width: 8),
                            Text('Extend Session'),
                          ],
                        ),
                      ),
                    if (session.isActive)
                      const PopupMenuItem(
                        value: 'terminate',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Terminate Session',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.security,
                  label: session.securityStatus,
                  color: _getSecurityColor(session.securityLevel),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: '${session.remainingTime.inMinutes}m remaining',
                  color: session.remainingTime.inMinutes < 5
                      ? Colors.red
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.location_on,
                  label: session.location ?? 'Unknown',
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Started: ${_formatDate(session.startTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 16),
                Text(
                  'Last activity: ${_formatDate(session.lastActivity)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your session activities will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentActivities.length,
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(SessionActivityModel activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getActivityColor(activity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity.activityIcon,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.description ?? activity.activityType.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(activity.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (activity.isSecurityEvent)
              Icon(
                Icons.warning,
                color: _getSecurityImpactColor(activity.securityImpact),
                size: 16,
              ),
            if (!activity.success)
              Icon(Icons.error, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Colors.green;
      case SessionStatus.expired:
        return Colors.red;
      case SessionStatus.terminated:
        return Colors.grey;
      case SessionStatus.suspended:
        return Colors.orange;
    }
  }

  Color _getSecurityColor(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.low:
        return Colors.red;
      case SecurityLevel.standard:
        return Colors.orange;
      case SecurityLevel.high:
        return Colors.blue;
      case SecurityLevel.maximum:
        return Colors.green;
    }
  }

  Color _getActivityColor(SessionActivityModel activity) {
    if (activity.isSecurityEvent) {
      return _getSecurityImpactColor(activity.securityImpact);
    }
    if (!activity.success) {
      return Colors.red;
    }
    return Colors.blue;
  }

  Color _getSecurityImpactColor(SecurityImpact impact) {
    switch (impact) {
      case SecurityImpact.none:
        return Colors.grey;
      case SecurityImpact.low:
        return Colors.orange;
      case SecurityImpact.medium:
        return Colors.deepOrange;
      case SecurityImpact.high:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      // Mock implementation - in real app, this would call the service
      await Future.delayed(const Duration(seconds: 1));

      // Mock sessions data
      setState(() {
        _sessions = [
          SessionModel.create(
            userId: widget.userId,
            deviceId: 'device_123',
            sessionId: 'session_456',
            ipAddress: '192.168.1.100',
            userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
            location: 'San Francisco, CA',
            timeoutDuration: const Duration(minutes: 30),
            securityLevel: SecurityLevel.high,
          ),
          SessionModel.create(
            userId: widget.userId,
            deviceId: 'device_456',
            sessionId: 'session_789',
            ipAddress: '192.168.1.101',
            userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
            location: 'San Francisco, CA',
            timeoutDuration: const Duration(minutes: 30),
            securityLevel: SecurityLevel.standard,
          ).terminate(),
        ];

        _recentActivities = [
          SessionActivityModel.create(
            sessionId: 'session_456',
            userId: widget.userId,
            activityType: ActivityType.login,
            description: 'User logged in from iPhone',
            ipAddress: '192.168.1.100',
            location: 'San Francisco, CA',
          ),
          SessionActivityModel.create(
            sessionId: 'session_456',
            userId: widget.userId,
            activityType: ActivityType.tokenRefresh,
            description: 'Access token refreshed automatically',
            ipAddress: '192.168.1.100',
            location: 'San Francisco, CA',
          ),
          SessionActivityModel.create(
            sessionId: 'session_789',
            userId: widget.userId,
            activityType: ActivityType.logout,
            description: 'User logged out from MacBook',
            ipAddress: '192.168.1.101',
            location: 'San Francisco, CA',
          ),
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sessions: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _terminateSession(SessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Session'),
        content: Text(
          'Are you sure you want to terminate this session? '
          'The user will be logged out immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      // In real app, this would call the auth bloc
      await Future.delayed(const Duration(seconds: 1));

      setState(() => _isLoading = false);
    }
  }

  Future<void> _terminateAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate All Sessions'),
        content: const Text(
          'Are you sure you want to terminate all active sessions? '
          'All users will be logged out immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Terminate All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      // In real app, this would call the auth bloc
      await Future.delayed(const Duration(seconds: 1));

      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewSessionActivity(SessionModel session) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Activity - ${session.id.substring(0, 8)}...'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildActivityDetail('Session ID', session.id),
              _buildActivityDetail('User ID', session.userId),
              _buildActivityDetail('Device ID', session.deviceId),
              _buildActivityDetail('IP Address', session.ipAddress),
              _buildActivityDetail('User Agent', session.userAgent),
              _buildActivityDetail('Location', session.location),
              _buildActivityDetail('Status', session.activityStatus),
              _buildActivityDetail(
                'Security Level',
                session.securityLevel.name,
              ),
              _buildActivityDetail(
                'Start Time',
                _formatDate(session.startTime),
              ),
              _buildActivityDetail(
                'Last Activity',
                _formatDate(session.lastActivity),
              ),
              _buildActivityDetail(
                'Timeout Duration',
                '${session.timeoutDuration.inMinutes} minutes',
              ),
              _buildActivityDetail(
                'Consecutive Failures',
                session.consecutiveFailures.toString(),
              ),
              _buildActivityDetail('Is Locked', session.isLocked.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _extendSession(SessionModel session) async {
    // Mock implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session extended successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
