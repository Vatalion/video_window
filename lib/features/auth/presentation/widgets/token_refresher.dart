import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/models/session_token_model.dart';

class TokenRefresher extends StatefulWidget {
  final String sessionId;
  final Widget child;

  const TokenRefresher({
    super.key,
    required this.sessionId,
    required this.child,
  });

  @override
  State<TokenRefresher> createState() => _TokenRefresherState();
}

class _TokenRefresherState extends State<TokenRefresher> {
  Timer? _refreshTimer;
  SessionTokenModel? _currentTokens;
  bool _isRefreshing = false;
  bool _showRefreshWarning = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentTokens();
    _startTokenMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is TokenRefreshed) {
          setState(() {
            _isRefreshing = false;
            _showRefreshWarning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access token refreshed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthError) {
          setState(() => _isRefreshing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_showRefreshWarning) _buildRefreshWarning(),
          if (_isRefreshing) _buildRefreshOverlay(),
        ],
      ),
    );
  }

  Widget _buildRefreshWarning() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.orange[50],
        child: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Session token expiring soon. Refreshing...',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_isRefreshing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Refreshing session token...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrentTokens() async {
    try {
      // Mock implementation - in real app, this would call the token service
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _currentTokens = SessionTokenModel.create(
          userId: 'user_123',
          deviceId: 'device_123',
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
          accessTokenDuration: const Duration(minutes: 30),
          refreshTokenDuration: const Duration(days: 7),
          ipAddress: '192.168.1.100',
          userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        );
      });
    } catch (e) {
      // Handle error
    }
  }

  void _startTokenMonitoring() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkTokenExpiration();
    });

    // Initial check
    _checkTokenExpiration();
  }

  Future<void> _checkTokenExpiration() async {
    if (_currentTokens == null || _isRefreshing) return;

    final timeRemaining = _currentTokens!.accessTokenRemainingTime;
    final shouldRefresh = timeRemaining.inMinutes <= 5;

    if (shouldRefresh && timeRemaining.inSeconds > 0) {
      setState(() => _showRefreshWarning = true);
      await _refreshToken();
    } else if (timeRemaining.inSeconds <= 0) {
      // Token expired - handle session termination
      await _handleTokenExpiration();
    } else {
      setState(() => _showRefreshWarning = false);
    }
  }

  Future<void> _refreshToken() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // In real app, this would call the auth bloc
      await Future.delayed(const Duration(seconds: 2));

      // Update tokens with new expiration times
      setState(() {
        _currentTokens = SessionTokenModel(
          id: _currentTokens!.id,
          userId: _currentTokens!.userId,
          deviceId: _currentTokens!.deviceId,
          accessToken:
              'new_access_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: _currentTokens!.refreshToken,
          accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
          refreshTokenExpiresAt: _currentTokens!.refreshTokenExpiresAt,
          issuedAt: DateTime.now(),
          ipAddress: _currentTokens!.ipAddress,
          userAgent: _currentTokens!.userAgent,
          isActive: _currentTokens!.isActive,
          tokenType: _currentTokens!.tokenType,
          tokenVersion: _currentTokens!.tokenVersion + 1,
        );
      });
    } catch (e) {
      // Handle error
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleTokenExpiration() async {
    setState(() => _isRefreshing = false);
    setState(() => _showRefreshWarning = false);

    // Show session expired dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session has expired due to inactivity. '
          'Please log in again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Public method to manually refresh tokens
  Future<void> manualRefresh() async {
    if (_currentTokens != null && !_isRefreshing) {
      await _refreshToken();
    }
  }

  // Public method to get current token status
  TokenStatus getTokenStatus() {
    if (_currentTokens == null) return TokenStatus.unknown;
    if (_currentTokens!.isAccessTokenExpired) return TokenStatus.expired;
    if (_currentTokens!.needsRefresh) return TokenStatus.expiring;
    return TokenStatus.valid;
  }

  // Public method to get time remaining
  Duration getTimeRemaining() {
    return _currentTokens?.accessTokenRemainingTime ?? Duration.zero;
  }
}

enum TokenStatus { valid, expiring, expired, unknown }
