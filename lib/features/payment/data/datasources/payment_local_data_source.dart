import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/payment_gateway_model.dart';

class PaymentLocalDataSource {
  final SharedPreferences sharedPreferences;

  PaymentLocalDataSource({required this.sharedPreferences});

  static const String _paymentsKey = 'cached_payments';
  static const String _cardsKey = 'cached_cards';
  static const String _gatewaysKey = 'cached_gateways';
  static const String _paymentTokenKey = 'payment_token';
  static const String _securityConfigKey = 'security_config';

  Future<void> cachePayments(List<PaymentModel> payments) async {
    final paymentsJson = payments.map((p) => p.toJson()).toList();
    await sharedPreferences.setStringList(_paymentsKey,
        paymentsJson.map((p) => json.encode(p)).toList());
  }

  Future<List<PaymentModel>> getCachedPayments() async {
    final paymentsJson = sharedPreferences.getStringList(_paymentsKey);
    if (paymentsJson == null) return [];

    return paymentsJson
        .map((p) => PaymentModel.fromJson(json.decode(p)))
        .toList();
  }

  Future<void> cacheCards(List<CardModel> cards) async {
    final cardsJson = cards.map((c) => c.toJson()).toList();
    await sharedPreferences.setStringList(_cardsKey,
        cardsJson.map((c) => json.encode(c)).toList());
  }

  Future<List<CardModel>> getCachedCards() async {
    final cardsJson = sharedPreferences.getStringList(_cardsKey);
    if (cardsJson == null) return [];

    return cardsJson
        .map((c) => CardModel.fromJson(json.decode(c)))
        .toList();
  }

  Future<void> cachePaymentGateways(List<PaymentGatewayModel> gateways) async {
    final gatewaysJson = gateways.map((g) => g.toJson()).toList();
    await sharedPreferences.setStringList(_gatewaysKey,
        gatewaysJson.map((g) => json.encode(g)).toList());
  }

  Future<List<PaymentGatewayModel>> getCachedPaymentGateways() async {
    final gatewaysJson = sharedPreferences.getStringList(_gatewaysKey);
    if (gatewaysJson == null) return [];

    return gatewaysJson
        .map((g) => PaymentGatewayModel.fromJson(json.decode(g)))
        .toList();
  }

  Future<void> savePaymentToken(String token) async {
    await sharedPreferences.setString(_paymentTokenKey, token);
  }

  Future<String?> getPaymentToken() async {
    return sharedPreferences.getString(_paymentTokenKey);
  }

  Future<void> clearPaymentToken() async {
    await sharedPreferences.remove(_paymentTokenKey);
  }

  Future<void> saveSecurityConfig(Map<String, dynamic> config) async {
    await sharedPreferences.setString(_securityConfigKey, json.encode(config));
  }

  Future<Map<String, dynamic>?> getSecurityConfig() async {
    final configJson = sharedPreferences.getString(_securityConfigKey);
    if (configJson == null) return null;

    return json.decode(configJson) as Map<String, dynamic>;
  }

  Future<void> clearCache() async {
    await sharedPreferences.remove(_paymentsKey);
    await sharedPreferences.remove(_cardsKey);
    await sharedPreferences.remove(_gatewaysKey);
    await sharedPreferences.remove(_paymentTokenKey);
    await sharedPreferences.remove(_securityConfigKey);
  }

  Future<void> cachePayment(PaymentModel payment) async {
    final cachedPayments = await getCachedPayments();
    final updatedPayments = cachedPayments
        .where((p) => p.id != payment.id)
        .toList()
      ..add(payment);

    await cachePayments(updatedPayments);
  }

  Future<void> cacheCard(CardModel card) async {
    final cachedCards = await getCachedCards();
    final updatedCards = cachedCards
        .where((c) => c.id != card.id)
        .toList()
      ..add(card);

    await cacheCards(updatedCards);
  }

  Future<void> removeCachedCard(String cardId) async {
    final cachedCards = await getCachedCards();
    final updatedCards = cachedCards.where((c) => c.id != cardId).toList();
    await cacheCards(updatedCards);
  }

  Future<void> removeCachedPayment(String paymentId) async {
    final cachedPayments = await getCachedPayments();
    final updatedPayments = cachedPayments.where((p) => p.id != paymentId).toList();
    await cachePayments(updatedPayments);
  }

  Future<void> setDefaultCard(String cardId) async {
    final cachedCards = await getCachedCards();
    final updatedCards = cachedCards.map((card) {
      return card.copyWith(isDefault: card.id == cardId);
    }).toList();

    await cacheCards(updatedCards);
  }
}

import 'dart:convert';