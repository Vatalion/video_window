import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/data/repositories/feed_repository.dart';
import '../../lib/presentation/bloc/feed_bloc.dart';
import '../../lib/presentation/bloc/feed_event.dart';
import '../../lib/presentation/bloc/feed_state.dart';
import '../../lib/domain/entities/video.dart';
import '../../lib/domain/entities/video_interaction.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockRepository;
  late FeedBloc feedBloc;

  setUp(() {
    mockRepository = MockFeedRepository();
    feedBloc = FeedBloc(
      repository: mockRepository,
      userId: 'test_user',
    );
  });

  tearDown(() {
    feedBloc.close();
  });

  group('FeedBloc', () {
    test('initial state is FeedInitial', () {
      expect(feedBloc.state, const FeedInitial());
    });

    blocTest<FeedBloc, FeedState>(
      'emits [FeedLoading, FeedLoaded] when FeedLoadInitial is added',
      build: () {
        when(() => mockRepository.fetchFeedPage(
              userId: any(named: 'userId'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => FeedPageResult(
              videos: [],
              hasMore: false,
              feedId: 'test',
            ));
        return feedBloc;
      },
      act: (bloc) => bloc.add(const FeedLoadInitial()),
      expect: () => [
        const FeedLoading(),
        const FeedLoaded(
          videos: [],
          hasMore: false,
        ),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'emits FeedError when fetchFeedPage fails',
      build: () {
        when(() => mockRepository.fetchFeedPage(
              userId: any(named: 'userId'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('Network error'));
        return feedBloc;
      },
      act: (bloc) => bloc.add(const FeedLoadInitial()),
      expect: () => [
        const FeedLoading(),
        isA<FeedError>(),
      ],
    );
  });
}
