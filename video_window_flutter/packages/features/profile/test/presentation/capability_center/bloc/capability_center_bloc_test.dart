import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/data/services/capabilities/capability_service.dart';
import 'package:profile/presentation/capability_center/bloc/capability_center_bloc.dart';
import 'package:profile/presentation/capability_center/bloc/capability_center_event.dart';
import 'package:profile/presentation/capability_center/bloc/capability_center_state.dart';

/// Mock classes
class MockCapabilityService extends Mock implements CapabilityService {}

void main() {
  late MockCapabilityService mockService;

  setUp(() {
    mockService = MockCapabilityService();
  });

  group('CapabilityCenterBloc', () {
    const userId = 1;

    test('initial state is CapabilityCenterInitial', () {
      final bloc = CapabilityCenterBloc(mockService);
      expect(bloc.state, equals(const CapabilityCenterInitial()));
      bloc.close();
    });

    blocTest<CapabilityCenterBloc, CapabilityCenterState>(
      'emits [Loading, Loaded] when load succeeds',
      build: () {
        when(() => mockService.getStatus(userId)).thenAnswer(
          (_) async => _createMockStatus(),
        );
        return CapabilityCenterBloc(mockService);
      },
      act: (bloc) => bloc.add(const CapabilityCenterLoadRequested(userId)),
      expect: () => [
        const CapabilityCenterLoading(),
        isA<CapabilityCenterLoaded>()
            .having((s) => s.userId, 'userId', userId)
            .having((s) => s.canPublish, 'canPublish', false)
            .having((s) => s.reviewState, 'reviewState', 'none'),
      ],
      verify: (_) {
        verify(() => mockService.getStatus(userId)).called(1);
      },
    );

    blocTest<CapabilityCenterBloc, CapabilityCenterState>(
      'emits [Loading, Error] when load fails',
      build: () {
        when(() => mockService.getStatus(userId))
            .thenThrow(Exception('Network error'));
        return CapabilityCenterBloc(mockService);
      },
      act: (bloc) => bloc.add(const CapabilityCenterLoadRequested(userId)),
      expect: () => [
        const CapabilityCenterLoading(),
        isA<CapabilityCenterError>()
            .having((s) => s.errorCode, 'errorCode', 'LOAD_ERROR'),
      ],
    );

    blocTest<CapabilityCenterBloc, CapabilityCenterState>(
      'emits [Requesting, Loaded] when request succeeds',
      build: () {
        when(() => mockService.requestCapability(
              userId: userId,
              capability: 'publish',
              entryPoint: 'capability_center',
            )).thenAnswer((_) async => _createMockStatus());
        return CapabilityCenterBloc(mockService);
      },
      act: (bloc) => bloc.add(
        const CapabilityCenterRequestSubmitted(
          userId: userId,
          capability: 'publish',
          entryPoint: 'capability_center',
        ),
      ),
      expect: () => [
        const CapabilityCenterRequesting('publish'),
        isA<CapabilityCenterLoaded>(),
      ],
      verify: (_) {
        verify(() => mockService.requestCapability(
              userId: userId,
              capability: 'publish',
              entryPoint: 'capability_center',
            )).called(1);
      },
    );

    blocTest<CapabilityCenterBloc, CapabilityCenterState>(
      'emits [Requesting, Error] when request fails',
      build: () {
        when(() => mockService.requestCapability(
              userId: userId,
              capability: 'publish',
              entryPoint: 'capability_center',
            )).thenThrow(Exception('Request failed'));
        return CapabilityCenterBloc(mockService);
      },
      act: (bloc) => bloc.add(
        const CapabilityCenterRequestSubmitted(
          userId: userId,
          capability: 'publish',
          entryPoint: 'capability_center',
        ),
      ),
      expect: () => [
        const CapabilityCenterRequesting('publish'),
        isA<CapabilityCenterError>()
            .having((s) => s.errorCode, 'errorCode', 'REQUEST_ERROR'),
      ],
    );

    blocTest<CapabilityCenterBloc, CapabilityCenterState>(
      'refreshes status without changing to loading state',
      build: () {
        when(() => mockService.getStatus(userId)).thenAnswer(
          (_) async => _createMockStatus(),
        );
        return CapabilityCenterBloc(mockService);
      },
      seed: () => const CapabilityCenterLoaded(
        userId: userId,
        canPublish: false,
        canCollectPayments: false,
        canFulfillOrders: false,
        reviewState: 'none',
        blockers: {},
      ),
      act: (bloc) => bloc.add(const CapabilityCenterRefreshRequested(userId)),
      expect: () => [
        isA<CapabilityCenterLoaded>(),
      ],
      verify: (_) {
        verify(() => mockService.getStatus(userId)).called(1);
      },
    );
  });

  group('CapabilityCenterState', () {
    test('CapabilityCenterLoaded hasBlockers returns true when blockers exist',
        () {
      const state = CapabilityCenterLoaded(
        userId: 1,
        canPublish: false,
        canCollectPayments: false,
        canFulfillOrders: false,
        reviewState: 'none',
        blockers: {'publish': 'Identity verification required'},
      );

      expect(state.hasBlockers, isTrue);
    });

    test('CapabilityCenterLoaded hasBlockers returns false when no blockers',
        () {
      const state = CapabilityCenterLoaded(
        userId: 1,
        canPublish: true,
        canCollectPayments: false,
        canFulfillOrders: false,
        reviewState: 'none',
        blockers: {},
      );

      expect(state.hasBlockers, isFalse);
    });

    test('CapabilityCenterLoaded isUnderReview returns true for pending', () {
      const state = CapabilityCenterLoaded(
        userId: 1,
        canPublish: false,
        canCollectPayments: false,
        canFulfillOrders: false,
        reviewState: 'pending',
        blockers: {},
      );

      expect(state.isUnderReview, isTrue);
    });

    test('CapabilityCenterLoaded copyWith preserves unmodified fields', () {
      const original = CapabilityCenterLoaded(
        userId: 1,
        canPublish: false,
        canCollectPayments: false,
        canFulfillOrders: false,
        reviewState: 'none',
        blockers: {},
      );

      final copied = original.copyWith(canPublish: true);

      expect(copied.userId, equals(original.userId));
      expect(copied.canPublish, isTrue);
      expect(copied.canCollectPayments, equals(original.canCollectPayments));
    });
  });
}

/// Helper to create mock status response
dynamic _createMockStatus() {
  // Placeholder for mock status
  // In real implementation, this would return proper typed response
  return {};
}
