import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_shell/app_config.dart';
import 'app_shell/router.dart';
import 'app_shell/theme.dart';

/// Application entry point
/// Initializes dependencies and launches the app
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app configuration and dependencies
  await AppConfig.initialize();

  // Run the app
  runApp(const VideoWindowApp());
}

/// Root application widget
class VideoWindowApp extends StatelessWidget {
  const VideoWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter();

    return MaterialApp.router(
      title: 'Craft Video Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
