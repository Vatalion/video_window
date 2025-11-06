import 'package:flutter_test/flutter_test.dart';
import 'package:core/services/services.dart';

void main() {
  group('MockNavigationService', () {
    late MockNavigationService mockNav;

    setUp(() {
      mockNav = MockNavigationService();
    });

    tearDown(() {
      mockNav.reset();
    });

    group('go', () {
      test('records go location', () {
        mockNav.go('/story/123');

        expect(mockNav.goLocations, contains('/story/123'));
      });

      test('records multiple go calls', () {
        mockNav.go('/home');
        mockNav.go('/profile');

        expect(mockNav.goLocations, hasLength(2));
        expect(mockNav.goLocations[0], '/home');
        expect(mockNav.goLocations[1], '/profile');
      });
    });

    group('goNamed', () {
      test('records goNamed call', () {
        mockNav.goNamed('storyDetail', pathParameters: {'id': '123'});

        expect(mockNav.goNamedCalls, contains('storyDetail'));
      });

      test('records multiple goNamed calls', () {
        mockNav.goNamed('home');
        mockNav.goNamed('profile');

        expect(mockNav.goNamedCalls, hasLength(2));
      });
    });

    group('push', () {
      test('records pushed location', () async {
        await mockNav.push('/settings');

        expect(mockNav.pushedLocations, contains('/settings'));
      });

      test('returns null by default', () async {
        final result = await mockNav.push<String>('/settings');

        expect(result, null);
      });
    });

    group('pushNamed', () {
      test('records pushed route name', () async {
        await mockNav.pushNamed('settings');

        expect(mockNav.pushedRoutes, contains('settings'));
      });

      test('records multiple pushNamed calls', () async {
        await mockNav.pushNamed('settings');
        await mockNav.pushNamed('profile');

        expect(mockNav.pushedRoutes, hasLength(2));
      });
    });

    group('pop', () {
      test('increments pop count', () {
        mockNav.pop();

        expect(mockNav.popCount, 1);
      });

      test('tracks multiple pops', () {
        mockNav.pop();
        mockNav.pop();
        mockNav.pop();

        expect(mockNav.popCount, 3);
      });
    });

    group('replace', () {
      test('records replace as go location', () {
        mockNav.replace('/new-location');

        expect(mockNav.goLocations, contains('/new-location'));
      });
    });

    group('replaceNamed', () {
      test('records replaceNamed as goNamed call', () {
        mockNav.replaceNamed('newRoute');

        expect(mockNav.goNamedCalls, contains('newRoute'));
      });
    });

    group('canPop', () {
      test('always returns true', () {
        expect(mockNav.canPop(), true);
      });
    });

    group('currentLocation', () {
      test('returns root by default', () {
        expect(mockNav.currentLocation, '/');
      });
    });

    group('reset', () {
      test('clears all recorded calls', () {
        mockNav.go('/home');
        mockNav.goNamed('profile');
        mockNav.push('/settings');
        mockNav.pushNamed('offer');
        mockNav.pop();

        mockNav.reset();

        expect(mockNav.goLocations, isEmpty);
        expect(mockNav.goNamedCalls, isEmpty);
        expect(mockNav.pushedLocations, isEmpty);
        expect(mockNav.pushedRoutes, isEmpty);
        expect(mockNav.popCount, 0);
      });
    });

    group('usage in tests', () {
      test('can verify navigation calls', () {
        // Simulate a workflow that navigates
        mockNav.pushNamed('storyDetail', pathParameters: {'id': '123'});
        mockNav.pop();
        mockNav.goNamed('home');

        // Verify the expected navigation sequence
        expect(mockNav.pushedRoutes, contains('storyDetail'));
        expect(mockNav.popCount, 1);
        expect(mockNav.goNamedCalls, contains('home'));
      });
    });
  });

  group('NavigationService interface', () {
    test('MockNavigationService implements NavigationService', () {
      final nav = MockNavigationService();
      expect(nav, isA<NavigationService>());
    });
  });
}
