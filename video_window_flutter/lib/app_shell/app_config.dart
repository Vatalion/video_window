import 'package:video_window_client/video_window_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// Application configuration and dependency setup
class AppConfig {
  static late Client serverClient;

  /// Initialize application dependencies and services
  static Future<void> initialize() async {
    // Configure server URL based on environment
    const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
    final serverUrl =
        serverUrlFromEnv.isEmpty ? 'http://$localhost:8080/' : serverUrlFromEnv;

    // Initialize Serverpod client
    serverClient = Client(serverUrl)
      ..connectivityMonitor = FlutterConnectivityMonitor();
  }

  /// Cleanup resources
  static Future<void> dispose() async {
    // Add cleanup logic here as needed
  }
}
