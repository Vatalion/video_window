import 'package:flutter_test/flutter_test.dart';
import 'package:video_window_flutter/app_shell/routing/app_routes.dart';

void main() {
  group('AppRoutes', () {
    group('route paths', () {
      test('home route is defined', () {
        expect(AppRoutes.home, '/');
        expect(AppRoutes.homeName, 'home');
      });

      test('sign-in route is defined', () {
        expect(AppRoutes.signIn, '/sign-in');
        expect(AppRoutes.signInName, 'signIn');
      });

      test('settings route is defined', () {
        expect(AppRoutes.settings, '/settings');
        expect(AppRoutes.settingsName, 'settings');
      });

      test('design catalog route is defined', () {
        expect(AppRoutes.designCatalog, '/design-catalog');
        expect(AppRoutes.designCatalogName, 'designCatalog');
      });

      test('story detail route is defined with parameter', () {
        expect(AppRoutes.storyDetail, '/story/:id');
        expect(AppRoutes.storyDetailName, 'storyDetail');
      });

      test('offer detail route is defined with parameter', () {
        expect(AppRoutes.offerDetail, '/offer/:id');
        expect(AppRoutes.offerDetailName, 'offerDetail');
      });

      test('profile route is defined', () {
        expect(AppRoutes.profile, '/profile');
        expect(AppRoutes.profileName, 'profile');
      });
    });

    group('deep link configuration', () {
      test('deep link scheme is defined', () {
        expect(AppRoutes.deepLinkScheme, 'videowindow');
      });

      test('universal link host is defined', () {
        expect(AppRoutes.universalLinkHost, 'app.videowindow.com');
      });
    });

    group('helper methods', () {
      test('storyDetailPath builds correct path', () {
        final path = AppRoutes.storyDetailPath('123');
        expect(path, '/story/123');
      });

      test('storyDetailPath handles special characters', () {
        final path = AppRoutes.storyDetailPath('abc-123');
        expect(path, '/story/abc-123');
      });

      test('offerDetailPath builds correct path', () {
        final path = AppRoutes.offerDetailPath('456');
        expect(path, '/offer/456');
      });

      test('offerDetailPath handles special characters', () {
        final path = AppRoutes.offerDetailPath('def-456');
        expect(path, '/offer/def-456');
      });
    });

    group('requiresAuth', () {
      test('profile route requires authentication', () {
        expect(AppRoutes.requiresAuth('/profile'), true);
      });

      test('home route does not require authentication', () {
        expect(AppRoutes.requiresAuth('/'), false);
      });

      test('sign-in route does not require authentication', () {
        expect(AppRoutes.requiresAuth('/sign-in'), false);
      });

      test('story detail route does not require authentication', () {
        expect(AppRoutes.requiresAuth('/story/123'), false);
      });

      test('offer detail route does not require authentication', () {
        expect(AppRoutes.requiresAuth('/offer/456'), false);
      });
    });
  });
}
