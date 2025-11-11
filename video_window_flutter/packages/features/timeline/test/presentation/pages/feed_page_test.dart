import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/presentation/pages/feed_page.dart';
import '../../lib/presentation/bloc/feed_bloc.dart';
import '../../lib/presentation/bloc/feed_state.dart';
import '../../lib/data/repositories/feed_repository.dart';
import '../../lib/domain/entities/video.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  group('FeedPage', () {
    late MockFeedRepository mockRepository;

    setUp(() {
      mockRepository = MockFeedRepository();
    });

    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>(
            create: (context) => FeedBloc(
              repository: mockRepository,
            )..emit(const FeedLoading()),
            child: const FeedPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when error occurs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>(
            create: (context) => FeedBloc(
              repository: mockRepository,
            )..emit(const FeedError(message: 'Test error')),
            child: const FeedPage(),
          ),
        ),
      );

      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays empty state when no videos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>(
            create: (context) => FeedBloc(
              repository: mockRepository,
            )..emit(const FeedLoaded(
                videos: [],
                hasMore: false,
              )),
            child: const FeedPage(),
          ),
        ),
      );

      expect(find.text('No videos available'), findsOneWidget);
    });
  });
}
