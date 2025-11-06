import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/design_system.dart';

void main() {
  group('AppTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Test Field',
            ),
          ),
        ),
      );

      expect(find.text('Test Field'), findsOneWidget);
    });

    testWidgets('shows hint text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Test Field',
              hint: 'Enter text here',
            ),
          ),
        ),
      );

      expect(find.text('Enter text here'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              label: 'Test Field',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test input');
      expect(changedValue, 'test input');
    });

    testWidgets('obscures text when type is password', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Password',
              type: AppTextFieldType.password,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('shows/hides password with visibility toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Password',
              type: AppTextFieldType.password,
            ),
          ),
        ),
      );

      // Initially obscured
      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Now visible
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, false);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Obscured again
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('uses email keyboard for email type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Email',
              type: AppTextFieldType.email,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('uses phone keyboard for phone type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Phone',
              type: AppTextFieldType.phone,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.phone);
    });

    testWidgets('validates input and shows error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              label: 'Test Field',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Field is required';
                }
                return null;
              },
            ),
          ),
        ),
      );

      // Enter some valid text first
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Verify no error is shown for valid input
      expect(find.text('Field is required'), findsNothing);

      // Now enter invalid (empty) text to trigger validation error
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Verify error is displayed
      expect(find.text('Field is required'), findsOneWidget);
    });

    testWidgets('shows prefix icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Test Field',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('shows suffix icon when provided (non-password)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Test Field',
              suffixIcon: Icons.search,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('can be disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Test Field',
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('supports multiline input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Test Field',
              type: AppTextFieldType.multiline,
              maxLines: 4,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 4);
      expect(textField.keyboardType, TextInputType.multiline);
    });
  });
}
