import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:videowindow/features/payment/domain/models/payment_model.dart';
import 'package:videowindow/features/payment/domain/models/card_model.dart';
import 'package:videowindow/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:videowindow/features/payment/presentation/bloc/payment_event.dart';
import 'package:videowindow/features/payment/presentation/bloc/payment_state.dart';
import 'package:videowindow/features/payment/presentation/widgets/payment_form.dart';

class MockPaymentBloc extends Mock implements PaymentBloc {}

void main() {
  late MockPaymentBloc mockPaymentBloc;

  setUp(() {
    mockPaymentBloc = MockPaymentBloc();
  });

  Widget createPaymentForm({
    String userId = 'user_123',
    String orderId = 'order_123',
    double amount = 100.0,
    String currency = 'USD',
    void Function(PaymentModel)? onSuccess,
    void Function(String)? onError,
  }) {
    return MaterialApp(
      home: BlocProvider<PaymentBloc>(
        create: (context) => mockPaymentBloc,
        child: PaymentForm(
          userId: userId,
          orderId: orderId,
          amount: amount,
          currency: currency,
          onSuccess: onSuccess,
          onError: onError,
        ),
      ),
    );
  }

  group('PaymentForm', () {
    testWidgets('should display payment form with all required fields', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Card Details'), findsOneWidget);
      expect(find.text('Card Number'), findsOneWidget);
      expect(find.text('Expiry Date'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);
      expect(find.text('Cardholder Name'), findsOneWidget);
      expect(find.text('Save card for future purchases'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display payment summary with correct calculations', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm(amount: 100.0));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Payment Summary'), findsOneWidget);
      expect(find.text('Amount:'), findsOneWidget);
      expect(find.text('USD 100.00'), findsOneWidget);
      expect(find.text('Processing Fee:'), findsOneWidget);
      expect(find.text('USD 3.20'), findsOneWidget); // 100 * 0.029 + 0.30
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('USD 103.20'), findsOneWidget); // 100 * 1.029 + 0.30
    });

    testWidgets('should show saved cards section when cards are available', (tester) async {
      // Arrange
      final savedCards = [
        CardModel(
          id: 'card_1',
          userId: 'user_123',
          brand: CardBrand.visa,
          lastFourDigits: '4242',
          expiryMonth: '12',
          expiryYear: '25',
          cardholderName: 'John Doe',
          isDefault: true,
          isTokenized: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      whenListen(
        mockPaymentBloc,
        Stream.fromIterable([CardsLoaded(cards: savedCards)]),
        initialState: PaymentInitial(),
      );

      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Saved Cards'), findsOneWidget);
      expect(find.text('VISA **** **** **** 4242'), findsOneWidget);
      expect(find.text('Expires 12/25'), findsOneWidget);
      expect(find.text('Use a new card'), findsOneWidget);
    });

    testWidgets('should validate card number input', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.enterText(find.byKey(const Key('cardNumberField')), '123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid card number'), findsOneWidget);
    });

    testWidgets('should validate expiry date format', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.enterText(find.byKey(const Key('expiryField')), '12/2025'); // Invalid format
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Use MM/YY format'), findsOneWidget);
    });

    testWidgets('should validate CVV input', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.enterText(find.byKey(const Key('cvvField')), '12'); // Too short
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid CVV'), findsOneWidget);
    });

    testWidgets('should validate cardholder name', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.enterText(find.byKey(const Key('cardholderNameField')), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter cardholder name'), findsOneWidget);
    });

    testWidgets('should show processing state when submitting payment', (tester) async {
      // Arrange
      whenListen(
        mockPaymentBloc,
        Stream.fromIterable([PaymentLoading()]),
        initialState: PaymentInitial(),
      );

      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.enterText(find.byKey(const Key('cardNumberField')), '4111111111111111');
      await tester.enterText(find.byKey(const Key('expiryField')), '12/25');
      await tester.enterText(find.byKey(const Key('cvvField')), '123');
      await tester.enterText(find.byKey(const Key('cardholderNameField')), 'John Doe');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing...'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull); // Should be disabled during processing
    });

    testWidgets('should call onSuccess when payment succeeds', (tester) async {
      // Arrange
      final mockPayment = PaymentModel(
        id: 'pay_123',
        userId: 'user_123',
        orderId: 'order_123',
        amount: 100.0,
        currency: 'USD',
        status: PaymentStatus.succeeded,
        riskLevel: FraudRiskLevel.low,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        processedAt: DateTime.now(),
      );

      var onSuccessCalled = false;
      PaymentModel? receivedPayment;

      whenListen(
        mockPaymentBloc,
        Stream.fromIterable([PaymentOperationSuccess(payment: mockPayment)]),
        initialState: PaymentInitial(),
      );

      await tester.pumpWidget(createPaymentForm(
        onSuccess: (payment) {
          onSuccessCalled = true;
          receivedPayment = payment;
        },
      ));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(onSuccessCalled, true);
      expect(receivedPayment, equals(mockPayment));
    });

    testWidgets('should call onError when payment fails', (tester) async {
      // Arrange
      const errorMessage = 'Payment failed: Insufficient funds';

      var onErrorCalled = false;
      String? receivedError;

      whenListen(
        mockPaymentBloc,
        Stream.fromIterable([PaymentError(message: errorMessage)]),
        initialState: PaymentInitial(),
      );

      await tester.pumpWidget(createPaymentForm(
        onError: (error) {
          onErrorCalled = true;
          receivedError = error;
        },
      ));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(onErrorCalled, true);
      expect(receivedError, equals(errorMessage));
    });

    testWidgets('should process payment with new card when no saved card selected', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.enterText(find.byKey(const Key('cardNumberField')), '4111111111111111');
      await tester.enterText(find.byKey(const Key('expiryField')), '12/25');
      await tester.enterText(find.byKey(const Key('cvvField')), '123');
      await tester.enterText(find.byKey(const Key('cardholderNameField')), 'John Doe');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockPaymentBloc.add(
        ProcessPaymentEvent(
          userId: 'user_123',
          orderId: 'order_123',
          amount: 100.0,
          currency: 'USD',
          cardInput: any(named: 'cardInput'),
          saveCard: false,
          isRecurring: false,
        ),
      )).called(1);
    });

    testWidgets('should process payment with token when saved card selected', (tester) async {
      // Arrange
      final savedCards = [
        CardModel(
          id: 'card_1',
          userId: 'user_123',
          brand: CardBrand.visa,
          lastFourDigits: '4242',
          expiryMonth: '12',
          expiryYear: '25',
          cardholderName: 'John Doe',
          isDefault: true,
          isTokenized: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      whenListen(
        mockPaymentBloc,
        Stream.fromIterable([CardsLoaded(cards: savedCards)]),
        initialState: PaymentInitial(),
      );

      await tester.pumpWidget(createPaymentForm());
      await tester.pumpAndSettle();

      // Act - Select saved card
      await tester.tap(find.text('VISA **** **** **** 4242'));
      await tester.pumpAndSettle();

      // Then submit payment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockPaymentBloc.add(
        ProcessPaymentWithTokenEvent(
          userId: 'user_123',
          orderId: 'order_123',
          amount: 100.0,
          currency: 'USD',
          paymentToken: 'card_1',
          isRecurring: false,
        ),
      )).called(1);
    });

    testWidgets('should toggle save card option', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CheckboxListTile), findsOneWidget);
      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isTrue);
    });

    testWidgets('should load saved cards on initialization', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockPaymentBloc.add(
        LoadUserCardsEvent(userId: 'user_123'),
      )).called(1);
    });

    testWidgets('should format payment amount correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm(amount: 123.45));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Amount:'), findsOneWidget);
      expect(find.text('USD 123.45'), findsOneWidget);
      expect(find.text('Processing Fee:'), findsOneWidget);
      expect(find.text('USD 3.88'), findsOneWidget); // 123.45 * 0.029 + 0.30
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('USD 127.33'), findsOneWidget); // 123.45 * 1.029 + 0.30
    });

    testWidgets('should handle different currencies', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm(amount: 50.0, currency: 'EUR'));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Amount:'), findsOneWidget);
      expect(find.text('EUR 50.00'), findsOneWidget);
      expect(find.text('Processing Fee:'), findsOneWidget);
      expect(find.text('EUR 1.75'), findsOneWidget); // 50 * 0.029 + 0.30
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('EUR 51.75'), findsOneWidget); // 50 * 1.029 + 0.30
    });

    testWidgets('should dispose controllers properly', (tester) async {
      // Arrange
      await tester.pumpWidget(createPaymentForm());

      // Act
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox()); // Remove widget
      await tester.pumpAndSettle();

      // Assert - No exceptions should be thrown during disposal
      expect(tester.takeException(), isNull);
    });
  });
}