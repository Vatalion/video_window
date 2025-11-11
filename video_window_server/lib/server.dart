import 'package:video_window_server/src/birthday_reminder.dart';
import 'package:serverpod/serverpod.dart';

import 'package:video_window_server/src/web/routes/root.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/tasks/feed_lightfm_retrain.dart';

// This is the starting point of your Serverpod server. In most cases, you will
// only need to make additions to this file if you add future calls,  are
// configuring Relic (Serverpod's web-server), or need custom setup work.

void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Setup a default page at the web root.
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  // Serve all files in the /static directory.
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // Start the server.
  await pod.start();

  // After starting the server, you can register future calls. Future calls are
  // tasks that need to happen in the future, or independently of the request/
  // response cycle. For example, you can use future calls to send emails, or to
  // schedule tasks to be executed at a later time. Future calls are executed in
  // the background. Their schedule is persisted to the database, so you will
  // not lose them if the server is restarted.

  pod.registerFutureCall(
    BirthdayReminder(),
    FutureCallNames.birthdayReminder.name,
  );

  // AC5 (Story 4-5): Register LightFM retraining job
  // Schedule nightly at 02:00 UTC via cron or scheduled future call
  pod.registerFutureCall(
    FeedLightFMRetrain(),
    FutureCallNames.feedLightFMRetrain.name,
  );

  // AC5: Schedule initial LightFM retraining job for next 02:00 UTC
  await _scheduleLightFMRetrain(pod);

  // You can schedule future calls for a later time during startup. But you can
  // also schedule them in any endpoint or webroute through the session object.
  // there is also [futureCallAtTime] if you want to schedule a future call at a
  // specific time.
  await pod.futureCallWithDelay(
    FutureCallNames.birthdayReminder.name,
    Greeting(
      message: 'Hello!',
      author: 'Serverpod Server',
      timestamp: DateTime.now(),
    ),
    Duration(seconds: 5),
  );
}

/// Schedule LightFM retraining job for next 02:00 UTC
/// AC5: Nightly retraining at 02:00 UTC
Future<void> _scheduleLightFMRetrain(Serverpod pod) async {
  final now = DateTime.now().toUtc();
  var nextRun = DateTime.utc(
    now.year,
    now.month,
    now.day,
    2, // 02:00 UTC
    0,
    0,
  );

  // If 02:00 UTC has already passed today, schedule for tomorrow
  if (nextRun.isBefore(now) || nextRun.isAtSameMomentAs(now)) {
    nextRun = nextRun.add(const Duration(days: 1));
  }

  await pod.futureCallAtTime(
    FutureCallNames.feedLightFMRetrain.name,
    Greeting(
      message: 'LightFM Retrain',
      author: 'System',
      timestamp: DateTime.now(),
    ),
    nextRun,
  );

  // Log scheduling via server startup log
  // Note: In production, this would be logged via Serverpod's logging system
}

/// Names of all future calls in the server.
///
/// This is better than using a string literal, as it will reduce the risk of
/// typos and make it easier to refactor the code.
enum FutureCallNames {
  birthdayReminder,
  feedLightFMRetrain,
}
