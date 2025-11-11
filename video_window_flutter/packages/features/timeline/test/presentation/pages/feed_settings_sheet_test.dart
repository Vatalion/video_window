import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/presentation/pages/feed_settings_sheet.dart';
import 'package:timeline/presentation/bloc/feed_bloc.dart';
import 'package:timeline/presentation/bloc/feed_state.dart';
import 'package:timeline/domain/entities/feed_configuration.dart';
import 'package:timeline/domain/entities/video.dart';
import 'package:timeline/data/repositories/feed_repository.dart';

void main() {
  group('FeedSettingsSheet', () {
    late FeedConfiguration testConfiguration;
    late FeedRepository mockRepository;
    late FeedBloc mockBloc;

    setUp(() {
      testConfiguration = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: ['tag1', 'tag2'],
        blockedMakers: ['maker_1'],
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      mockRepository = FeedRepository(client: null as dynamic);
      mockBloc = FeedBloc(repository: mockRepository, userId: 'user_1');
    });

    tearDown(() {
      mockBloc.close();
    });

    testWidgets('displays all preference sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: FeedSettingsSheet(
                currentConfiguration: testConfiguration,
                userId: 'user_1',
              ),
            ),
          ),
        ),
      );

      // Verify sections are displayed
      expect(find.text('Feed Preferences'), findsOneWidget);
      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Personalization'), findsOneWidget);
      expect(find.text('Blocked Makers'), findsOneWidget);
      expect(find.text('Accessibility'), findsOneWidget);
    });

    testWidgets('toggles auto-play preference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: FeedSettingsSheet(
                currentConfiguration: testConfiguration,
                userId: 'user_1',
              ),
            ),
          ),
        ),
      );

      // Find auto-play switch
      final autoPlaySwitch = find.byType(SwitchListTile).first;
      expect(autoPlaySwitch, findsOneWidget);

      // Verify initial state
      final switchWidget = tester.widget<SwitchListTile>(autoPlaySwitch);
      expect(switchWidget.value, true);

      // Tap to toggle
      await tester.tap(autoPlaySwitch);
      await tester.pumpAndSettle();

      // Verify state changed
      final updatedSwitch = tester.widget<SwitchListTile>(autoPlaySwitch);
      expect(updatedSwitch.value, false);
    });

    testWidgets('displays blocked makers list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: FeedSettingsSheet(
                currentConfiguration: testConfiguration,
                userId: 'user_1',
              ),
            ),
          ),
        ),
      );

      // Verify blocked maker is displayed
      expect(find.text('Maker: maker_1'), findsOneWidget);
    });

    testWidgets('reduced motion toggle disables auto-play', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: FeedSettingsSheet(
                currentConfiguration: testConfiguration,
                userId: 'user_1',
              ),
            ),
          ),
        ),
      );

      // Find reduced motion switch
      final reducedMotionSwitch = find.text('Reduced Motion');
      expect(reducedMotionSwitch, findsOneWidget);

      // Tap reduced motion
      await tester.tap(reducedMotionSwitch);
      await tester.pumpAndSettle();

      // Verify auto-play is disabled
      final autoPlaySwitch = find.byType(SwitchListTile).first;
      final switchWidget = tester.widget<SwitchListTile>(autoPlaySwitch);
      expect(switchWidget.value, false);
    });

    testWidgets('validates blocked makers limit', (tester) async {
      // Create configuration with >200 blocked makers
      final invalidConfiguration = FeedConfiguration(
        id: 'config_1',
        userId: 'user_1',
        preferredTags: [],
        blockedMakers: List.generate(201, (i) => 'maker_$i'),
        preferredQuality: VideoQuality.hd,
        autoPlay: true,
        showCaptions: false,
        playbackSpeed: 1.0,
        algorithm: FeedAlgorithm.personalized,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FeedBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: FeedSettingsSheet(
                currentConfiguration: invalidConfiguration,
                userId: 'user_1',
              ),
            ),
          ),
        ),
      );

      // Try to save - should show error
      final saveButton = find.text('Save Preferences');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.textContaining('200'), findsWidgets);
    });
  });
}
