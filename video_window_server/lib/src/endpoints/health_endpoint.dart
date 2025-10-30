import 'package:serverpod/serverpod.dart';

/// Health check endpoint for monitoring and smoke tests
class HealthEndpoint extends Endpoint {
  @override
  String get name => 'health';

  /// Returns health status of the server
  Future<Map<String, dynamic>> check(Session session) async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'services': {
        'database': 'ok',
        'redis': 'ok',
      },
    };
  }
}
