import 'package:flutter_test/flutter_test.dart';
import 'package:video_window_flutter/app_shell/routing/route_guards.dart';

void main() {
  group('AuthenticationGuard', () {
    late AuthenticationGuard guard;

    setUp(() {
      guard = AuthenticationGuard();
    });

    group('initialization', () {
      test('starts uninitialized and unauthenticated', () {
        expect(guard.isAuthenticated, false);
        expect(guard.isInitialized, false);
      });

      test('setAuthenticated marks as initialized', () {
        guard.setAuthenticated(true);
        expect(guard.isAuthenticated, true);
        expect(guard.isInitialized, true);
      });

      test('setInitialized marks as initialized without changing auth', () {
        guard.setInitialized();
        expect(guard.isAuthenticated, false);
        expect(guard.isInitialized, true);
      });
    });

    group('authentication state', () {
      test('setAuthenticated updates state', () {
        guard.setAuthenticated(true);
        expect(guard.isAuthenticated, true);

        guard.setAuthenticated(false);
        expect(guard.isAuthenticated, false);
      });

      test('setAuthenticated notifies listeners on change', () {
        var notified = false;
        guard.addListener(() => notified = true);

        guard.setAuthenticated(true);
        expect(notified, true);
      });

      test('setAuthenticated does not notify if value unchanged', () {
        guard.setAuthenticated(true);

        var notifyCount = 0;
        guard.addListener(() => notifyCount++);

        guard.setAuthenticated(true);
        expect(notifyCount, 0);
      });

      test('signOut sets authentication to false', () {
        guard.setAuthenticated(true);
        expect(guard.isAuthenticated, true);

        guard.signOut();
        expect(guard.isAuthenticated, false);
      });

      test('signOut notifies listeners', () {
        guard.setAuthenticated(true);

        var notified = false;
        guard.addListener(() => notified = true);

        guard.signOut();
        expect(notified, true);
      });
    });

    group('ChangeNotifier behavior', () {
      test('can add and remove listeners', () {
        void listener() {}

        guard.addListener(listener);
        guard.removeListener(listener);

        // Should not throw
      });

      test('notifies all listeners', () {
        var count1 = 0;
        var count2 = 0;

        guard.addListener(() => count1++);
        guard.addListener(() => count2++);

        guard.setAuthenticated(true);

        expect(count1, 1);
        expect(count2, 1);
      });
    });
  });
}
