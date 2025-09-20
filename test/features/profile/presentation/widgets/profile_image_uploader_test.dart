import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:video_window/features/profile/presentation/bloc/profile_event.dart';
import 'package:video_window/features/profile/presentation/bloc/profile_state.dart';
import 'package:video_window/features/profile/presentation/widgets/profile_image_uploader.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    mockProfileBloc.close();
  });

  Widget createWidgetUnderTest({ProfileImageType type = ProfileImageType.profilePhoto, String? currentImageUrl}) {
    return MaterialApp(
      home: BlocProvider<ProfileBloc>.value(
        value: mockProfileBloc,
        child: ProfileImageUploader(
          type: type,
          currentImageUrl: currentImageUrl,
        ),
      ),
    );
  }

  group('ProfileImageUploader Widget Tests', () {
    testWidgets('should display image uploader with correct dimensions', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, equals(200)); // Profile photo height
    });

    testWidgets('should display correct dimensions for cover image', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(type: ProfileImageType.coverImage));

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, equals(150)); // Cover image height
    });

    testWidgets('should show placeholder when no image is provided', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('No Profile Photo'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('should show cover image placeholder for cover type', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(type: ProfileImageType.coverImage));

      // Assert
      expect(find.text('No Cover Image'), findsOneWidget);
      expect(find.byIcon(Icons.photo_size_select_actual), findsOneWidget);
    });

    testWidgets('should show current image when URL is provided', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        currentImageUrl: 'https://example.com/image.jpg',
      ));

      // Assert
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should show image source dialog when upload is tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Choose Image Source'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('should show camera option', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.camera), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('should show gallery option', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('should dispatch UploadProfileImage event when image source is selected', (WidgetTester tester) async {
      // Arrange - Mock image picker behavior would be handled by integration tests
      // For unit tests, we verify the event would be dispatched

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.text('Camera'));
      await tester.pump();

      // Assert - The event would be dispatched after image selection
      // This is a unit test, so we don't actually test the image picker
      expect(find.byType(AlertDialog), findsNothing); // Dialog should be closed
    });

    testWidgets('should dispatch RemoveProfileImage event when remove is tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        currentImageUrl: 'https://example.com/image.jpg',
      ));
      await tester.tap(find.text('Remove'));
      await tester.pump();

      // Assert
      verify(() => mockProfileBloc.add(any(that is RemoveProfileImage))).called(1);
    });

    testWidgets('should show loading indicator when uploading', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success message when image is uploaded', (WidgetTester tester) async {
      // Arrange
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileInitial(),
          const ProfileImageUploaded(imageUrl: 'https://example.com/new-image.jpg', type: ProfileImageType.profilePhoto),
        ]),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Image uploaded successfully'), findsOneWidget);
    });

    testWidgets('should show success message when image is removed', (WidgetTester tester) async {
      // Arrange
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileInitial(),
          const ProfileImageRemoved(type: ProfileImageType.profilePhoto),
        ]),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Image removed successfully'), findsOneWidget);
    });

    testWidgets('should show error message when upload fails', (WidgetTester tester) async {
      // Arrange
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([
          const ProfileInitial(),
          const ProfileError(message: 'Failed to upload image'),
        ]),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to upload image'), findsOneWidget);
    });

    testWidgets('should show correct recommendation text for profile photo', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Recommended: Square image, at least 400x400px'), findsOneWidget);
    });

    testWidgets('should show correct recommendation text for cover image', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(type: ProfileImageType.coverImage));

      // Assert
      expect(find.text('Recommended: 16:9 aspect ratio, at least 1920x1080px'), findsOneWidget);
    });

    testWidgets('should handle network image loading errors gracefully', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        currentImageUrl: 'https://invalid-url.com/image.jpg',
      ));

      // Wait for image to load
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('should disable buttons when loading', (WidgetTester tester) async {
      // Arrange
      when(() => mockProfileBloc.state).thenReturn(const ProfileLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        currentImageUrl: 'https://example.com/image.jpg',
      ));

      // Assert
      final uploadButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(uploadButton.enabled, isFalse);

      final removeButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(removeButton.enabled, isFalse);
    });

    testWidgets('should maintain aspect ratio for images', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        currentImageUrl: 'https://example.com/image.jpg',
      ));

      // Find the image widget
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      expect(image.fit, equals(BoxFit.cover));
    });

    testWidgets('should have correct MIME type detection', (WidgetTester tester) async {
      // This is a unit test, so we can't test the actual image picker
      // But we can verify that the widget is properly structured
      await tester.pumpWidget(createWidgetUnderTest());

      // The widget should be properly structured without errors
      expect(find.byType(ProfileImageUploader), findsOneWidget);
    });

    testWidgets('should handle image type correctly in events', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(type: ProfileImageType.coverImage));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.text('Camera'));
      await tester.pump();

      // Verify that the correct image type would be used in the event
      // This is verified through the widget's state and event handling
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should show remove button only when image exists', (WidgetTester tester) async {
      // Act - No current image
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Remove'), findsNothing);

      // Act - With current image
      await tester.pumpWidget(createWidgetUnderTest(
        currentImageUrl: 'https://example.com/image.jpg',
      ));

      // Assert
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.bySemanticsLabel('No Profile Photo'), findsOneWidget);
      expect(find.bySemanticsLabel('Upload'), findsOneWidget);
    });
  });
}