import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;

  PaymentBloc({required this.paymentRepository}) : super(PaymentInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<ProcessPaymentWithTokenEvent>(_onProcessPaymentWithToken);
    on<LoadPaymentEvent>(_onLoadPayment);
    on<LoadUserPaymentsEvent>(_onLoadUserPayments);
    on<LoadOrderPaymentsEvent>(_onLoadOrderPayments);
    on<RefundPaymentEvent>(_onRefundPayment);
    on<CancelPaymentEvent>(_onCancelPayment);
    on<LoadPaymentsByStatusEvent>(_onLoadPaymentsByStatus);
    on<AddCardEvent>(_onAddCard);
    on<LoadUserCardsEvent>(_onLoadUserCards);
    on<DeleteCardEvent>(_onDeleteCard);
    on<SetDefaultCardEvent<_onSetDefaultCard);
    on<LoadPaymentGatewaysEvent>(_onLoadPaymentGateways);
    on<AnalyzePaymentRiskEvent>(_onAnalyzePaymentRisk);
    on<ProcessRecurringPaymentEvent>(_onProcessRecurringPayment);
    on<CancelRecurringPaymentEvent>(_onCancelRecurringPayment);
    on<Validate3DSecureEvent>(_onValidate3DSecure);
    on<ClearPaymentErrorEvent>(_onClearPaymentError);
    on<RefreshPaymentsEvent>(_onRefreshPayments);
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.processPayment(
        userId: event.userId,
        orderId: event.orderId,
        amount: event.amount,
        currency: event.currency,
        cardInput: event.cardInput,
        saveCard: event.saveCard,
        isRecurring: event.isRecurring,
      );

      emit(PaymentOperationSuccess(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onProcessPaymentWithToken(
    ProcessPaymentWithTokenEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.processPaymentWithToken(
        userId: event.userId,
        orderId: event.orderId,
        amount: event.amount,
        currency: event.currency,
        paymentToken: event.paymentToken,
        isRecurring: event.isRecurring,
      );

      emit(PaymentOperationSuccess(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onLoadPayment(
    LoadPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.getPaymentById(event.paymentId);
      emit(PaymentLoaded(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserPayments(
    LoadUserPaymentsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payments = await paymentRepository.getPaymentsByUserId(event.userId);
      emit(PaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onLoadOrderPayments(
    LoadOrderPaymentsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payments = await paymentRepository.getPaymentsByOrderId(event.orderId);
      emit(PaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onRefundPayment(
    RefundPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.refundPayment(
        paymentId: event.paymentId,
        amount: event.amount,
        reason: event.reason,
      );

      emit(PaymentOperationSuccess(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onCancelPayment(
    CancelPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.cancelPayment(event.paymentId);
      emit(PaymentOperationSuccess(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onLoadPaymentsByStatus(
    LoadPaymentsByStatusEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payments = await paymentRepository.getPaymentsByStatus(event.status);
      emit(PaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onAddCard(
    AddCardEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(CardProcessing(cardId: '', progress: 0.5));
    try {
      final card = await paymentRepository.addCard(
        userId: event.userId,
        cardInput: event.cardInput,
        makeDefault: event.makeDefault,
      );

      emit(CardOperationSuccess(card: card));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserCards(
    LoadUserCardsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final cards = await paymentRepository.getUserCards(event.userId);
      emit(CardsLoaded(cards: cards));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCard(
    DeleteCardEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      await paymentRepository.deleteCard(event.cardId);
      emit(const PaymentOperationSuccess(
        payment: PaymentModel(
          id: '',
          userId: '',
          orderId: '',
          amount: 0,
          currency: '',
          status: PaymentStatus.succeeded,
          riskLevel: FraudRiskLevel.low,
          isRecurring: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onSetDefaultCard(
    SetDefaultCardEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final card = await paymentRepository.setDefaultCard(
        userId: event.userId,
        cardId: event.cardId,
      );

      emit(CardOperationSuccess(card: card));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onLoadPaymentGateways(
    LoadPaymentGatewaysEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final gateways = await paymentRepository.getActivePaymentGateways();
      emit(PaymentGatewaysLoaded(gateways: gateways));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onAnalyzePaymentRisk(
    AnalyzePaymentRiskEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final fraudDetection = await paymentRepository.analyzePaymentRisk(
        userId: event.userId,
        paymentId: event.paymentId,
        amount: event.amount,
        currency: event.currency,
        ipAddress: event.ipAddress,
        deviceId: event.deviceId,
        userAgent: event.userAgent,
      );

      emit(FraudAnalysisComplete(fraudDetection: fraudDetection));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onProcessRecurringPayment(
    ProcessRecurringPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.processRecurringPayment(
        userId: event.userId,
        orderId: event.orderId,
        amount: event.amount,
        currency: event.currency,
        subscriptionId: event.subscriptionId,
      );

      emit(PaymentOperationSuccess(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onCancelRecurringPayment(
    CancelRecurringPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payment = await paymentRepository.cancelRecurringPayment(
        subscriptionId: event.subscriptionId,
        reason: event.reason,
      );

      emit(PaymentOperationSuccess(payment: payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onValidate3DSecure(
    Validate3DSecureEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final isValid = await paymentRepository.validate3DSecure(
        paymentId: event.paymentId,
        transactionId: event.transactionId,
        authData: event.authData,
      );

      if (isValid) {
        emit(const PaymentOperationSuccess(
          payment: PaymentModel(
            id: '',
            userId: '',
            orderId: '',
            amount: 0,
            currency: '',
            status: PaymentStatus.succeeded,
            riskLevel: FraudRiskLevel.low,
            isRecurring: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ));
      } else {
        emit(const PaymentError(message: '3D Secure validation failed'));
      }
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  void _onClearPaymentError(
    ClearPaymentErrorEvent event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentInitial());
  }

  Future<void> _onRefreshPayments(
    RefreshPaymentsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payments = await paymentRepository.getPaymentsByStatus(PaymentStatus.succeeded);
      emit(PaymentsLoaded(payments: payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
}