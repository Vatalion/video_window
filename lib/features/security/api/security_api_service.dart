import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/security/security_audit_log.dart';
import '../../../models/security/security_alert.dart';
import '../../../models/security/account_protection.dart';

class SecurityApiService {
  static const String _baseUrl = 'https://api.example.com/security';

  Future<List<SecurityAuditLog>> getAuditLogs({
    String? userId,
    String? token,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/audit-logs').replace(queryParameters: {
        if (userId != null) 'userId': userId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        'limit': limit.toString(),
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SecurityAuditLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load audit logs');
    }
  }

  Future<List<SecurityAlert>> getSecurityAlerts({
    String? userId,
    String? token,
    AlertStatus? status,
    int limit = 100,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/alerts').replace(queryParameters: {
        if (userId != null) 'userId': userId,
        if (status != null) 'status': status.name,
        'limit': limit.toString(),
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SecurityAlert.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load security alerts');
    }
  }

  Future<void> acknowledgeAlert(String alertId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/alerts/$alertId/acknowledge'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to acknowledge alert');
    }
  }

  Future<AccountProtection> getAccountProtection(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/account-protection/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return AccountProtection.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load account protection');
    }
  }

  Future<void> unlockAccount(String userId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/account-protection/$userId/unlock'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unlock account');
    }
  }

  Future<Map<String, dynamic>> getSecurityStatistics(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/statistics/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load security statistics');
    }
  }
}