import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/payment_model.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/payment_gateway_model.dart';
import '../../domain/models/fraud_detection_model.dart';

class PaymentRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  PaymentRemoteDataSource({required this.client, required this.baseUrl});

  Future<PaymentModel> processPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required CardInputModel cardInput,
    bool saveCard = false,
    bool isRecurring = false,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/payments/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'user_id': userId,
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'card_input': cardInput.toJson(),
          'save_card': saveCard,
          'is_recurring': isRecurring,
        }),
      );

      if (response.statusCode == 200) {
        return PaymentModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to process payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment processing error: $e');
    }
  }

  Future<PaymentModel> processPaymentWithToken({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentToken,
    bool isRecurring = false,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/payments/process-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'user_id': userId,
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'payment_token': paymentToken,
          'is_recurring': isRecurring,
        }),
      );

      if (response.statusCode == 200) {
        return PaymentModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to process payment with token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Token payment processing error: $e');
    }
  }

  Future<PaymentModel> getPaymentById(String paymentId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return PaymentModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get payment error: $e');
    }
  }

  Future<List<PaymentModel>> getPaymentsByUserId(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/payments/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaymentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get user payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get user payments error: $e');
    }
  }

  Future<CardModel> addCard({
    required String userId,
    required CardInputModel cardInput,
    bool makeDefault = false,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/cards/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'user_id': userId,
          'card_input': cardInput.toJson(),
          'make_default': makeDefault,
        }),
      );

      if (response.statusCode == 200) {
        return CardModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add card: ${response.body}');
      }
    } catch (e) {
      throw Exception('Add card error: $e');
    }
  }

  Future<List<CardModel>> getUserCards(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/cards/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CardModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get user cards: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get user cards error: $e');
    }
  }

  Future<FraudDetectionModel> analyzePaymentRisk({
    required String userId,
    required String paymentId,
    required double amount,
    required String currency,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/fraud/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'user_id': userId,
          'payment_id': paymentId,
          'amount': amount,
          'currency': currency,
          'ip_address': ipAddress,
          'device_id': deviceId,
          'user_agent': userAgent,
        }),
      );

      if (response.statusCode == 200) {
        return FraudDetectionModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to analyze payment risk: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment risk analysis error: $e');
    }
  }

  String? _token;

  void setAuthToken(String token) {
    _token = token;
  }

  void clearAuthToken() {
    _token = null;
  }
}