import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// 3D Secure authentication service with certified provider integration
class ThreeDSecureService {
  final String _apiKey;
  final String _apiSecret;
  final String _baseUrl;
  final ThreeDProvider _provider;

  ThreeDSecureService({
    required String apiKey,
    required String apiSecret,
    String baseUrl = 'https://api.3dsecure.com/v1',
    ThreeDProvider provider = ThreeDProvider.stripe,
  }) : _apiKey = apiKey,
       _apiSecret = apiSecret,
       _baseUrl = baseUrl,
       _provider = provider;

  /// Initiate 3D Secure authentication for a payment
  Future<ThreeDSecureResult> authenticatePayment({
    required String paymentId,
    required String transactionId,
    required double amount,
    required String currency,
    required String cardToken,
    required Map<String, dynamic> browserData,
    required Map<String, dynamic> deviceData,
  }) async {
    try {
      // 1. Validate authentication request
      final validation = await _validateAuthenticationRequest(
        paymentId: paymentId,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        cardToken: cardToken,
      );

      if (!validation.isValid) {
        return ThreeDSecureResult(
          success: false,
          authenticationStatus: ThreeDAuthenticationStatus.failed,
          error: validation.errorMessage,
          riskLevel: validation.riskLevel,
        );
      }

      // 2. Create authentication session
      final authSession = await _createAuthenticationSession(
        paymentId: paymentId,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        cardToken: cardToken,
        browserData: browserData,
        deviceData: deviceData,
      );

      // 3. Perform risk assessment
      final riskAssessment = await _performRiskAssessment(
        paymentId: paymentId,
        amount: amount,
        cardToken: cardToken,
        browserData: browserData,
        deviceData: deviceData,
      );

      // 4. Determine if step-up authentication is required
      if (riskAssessment.requiresStepUp) {
        final stepUpResult = await _performStepUpAuthentication(
          authSession: authSession,
          riskAssessment: riskAssessment,
        );

        return stepUpResult;
      } else {
        // Frictionless authentication
        return await _completeFrictionlessAuthentication(
          authSession: authSession,
          riskAssessment: riskAssessment,
        );
      }
    } catch (e) {
      return ThreeDSecureResult(
        success: false,
        authenticationStatus: ThreeDAuthenticationStatus.error,
        error: '3D Secure authentication failed: $e',
        riskLevel: FraudRiskLevel.high,
      );
    }
  }

  /// Validate 3D Secure authentication request
  Future<ThreeDValidationResult> _validateAuthenticationRequest({
    required String paymentId,
    required String transactionId,
    required double amount,
    required String currency,
    required String cardToken,
  }) async {
    // Validate required fields
    if (paymentId.isEmpty || transactionId.isEmpty || cardToken.isEmpty) {
      return ThreeDValidationResult(
        isValid: false,
        errorMessage: 'Missing required authentication parameters',
        riskLevel: FraudRiskLevel.high,
      );
    }

    // Validate amount limits
    if (amount <= 0) {
      return ThreeDValidationResult(
        isValid: false,
        errorMessage: 'Invalid amount',
        riskLevel: FraudRiskLevel.high,
      );
    }

    // Validate currency
    if (currency.length != 3) {
      return ThreeDValidationResult(
        isValid: false,
        errorMessage: 'Invalid currency format',
        riskLevel: FraudRiskLevel.high,
      );
    }

    // Validate card token format based on provider
    final tokenValidation = _validateCardToken(cardToken);
    if (!tokenValidation.isValid) {
      return ThreeDValidationResult(
        isValid: false,
        errorMessage: tokenValidation.errorMessage,
        riskLevel: FraudRiskLevel.high,
      );
    }

    return ThreeDValidationResult(
      isValid: true,
      errorMessage: null,
      riskLevel: FraudRiskLevel.low,
    );
  }

  /// Create 3D Secure authentication session
  Future<ThreeDSession> _createAuthenticationSession({
    required String paymentId,
    required String transactionId,
    required double amount,
    required String currency,
    required String cardToken,
    required Map<String, dynamic> browserData,
    required Map<String, dynamic> deviceData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Api-Secret': _apiSecret,
        },
        body: json.encode({
          'payment_id': paymentId,
          'transaction_id': transactionId,
          'amount': amount,
          'currency': currency,
          'card_token': cardToken,
          'browser_data': browserData,
          'device_data': deviceData,
          'provider': _provider.name,
          'return_url': 'https://app.videowindow.com/3ds-complete',
          'callback_url': 'https://api.videowindow.com/3ds-callback',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ThreeDSession.fromJson(data);
      } else {
        throw Exception('Failed to create 3D Secure session: ${response.body}');
      }
    } catch (e) {
      throw Exception('3D Secure session creation error: $e');
    }
  }

  /// Perform risk assessment for the transaction
  Future<ThreeDRiskAssessment> _performRiskAssessment({
    required String paymentId,
    required double amount,
    required String cardToken,
    required Map<String, dynamic> browserData,
    required Map<String, dynamic> deviceData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/risk-assessment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Api-Secret': _apiSecret,
        },
        body: json.encode({
          'payment_id': paymentId,
          'amount': amount,
          'card_token': cardToken,
          'browser_data': browserData,
          'device_data': deviceData,
          'assessment_type': 'pre_authentication',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ThreeDRiskAssessment.fromJson(data);
      } else {
        throw Exception('Risk assessment failed: ${response.body}');
      }
    } catch (e) {
      // Fallback to default risk assessment
      return ThreeDRiskAssessment(
        riskScore: 0.5,
        requiresStepUp: amount > 100, // Step-up for amounts over $100
        riskFactors: ['network_error'],
        recommendedAction: ThreeDAction.challenge,
      );
    }
  }

  /// Perform step-up authentication
  Future<ThreeDSecureResult> _performStepUpAuthentication({
    required ThreeDSession authSession,
    required ThreeDRiskAssessment riskAssessment,
  }) async {
    try {
      // For mobile app, we'll handle this through a webview
      final challengeUrl = _buildChallengeUrl(authSession);

      return ThreeDSecureResult(
        success: false, // Will be updated after authentication
        authenticationStatus: ThreeDAuthenticationStatus.challengeRequired,
        challengeUrl: challengeUrl,
        acsUrl: authSession.acsUrl,
        creq: authSession.creq,
        riskLevel: riskAssessment.riskLevel,
        transactionId: authSession.transactionId,
      );
    } catch (e) {
      return ThreeDSecureResult(
        success: false,
        authenticationStatus: ThreeDAuthenticationStatus.error,
        error: 'Step-up authentication failed: $e',
        riskLevel: FraudRiskLevel.high,
      );
    }
  }

  /// Complete frictionless authentication
  Future<ThreeDSecureResult> _completeFrictionlessAuthentication({
    required ThreeDSession authSession,
    required ThreeDRiskAssessment riskAssessment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/authenticate/frictionless'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Api-Secret': _apiSecret,
        },
        body: json.encode({
          'session_id': authSession.id,
          'transaction_id': authSession.transactionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ThreeDSecureResult.fromJson(data);
      } else {
        throw Exception('Frictionless authentication failed: ${response.body}');
      }
    } catch (e) {
      return ThreeDSecureResult(
        success: false,
        authenticationStatus: ThreeDAuthenticationStatus.error,
        error: 'Frictionless authentication failed: $e',
        riskLevel: FraudRiskLevel.high,
      );
    }
  }

  /// Complete 3D Secure authentication after challenge
  Future<ThreeDSecureResult> completeAuthentication({
    required String sessionId,
    required String transactionId,
    required Map<String, dynamic> authData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/authenticate/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Api-Secret': _apiSecret,
        },
        body: json.encode({
          'session_id': sessionId,
          'transaction_id': transactionId,
          'auth_data': authData,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ThreeDSecureResult.fromJson(data);
      } else {
        throw Exception('Authentication completion failed: ${response.body}');
      }
    } catch (e) {
      return ThreeDSecureResult(
        success: false,
        authenticationStatus: ThreeDAuthenticationStatus.error,
        error: 'Authentication completion failed: $e',
        riskLevel: FraudRiskLevel.high,
      );
    }
  }

  /// Build challenge URL for step-up authentication
  String _buildChallengeUrl(ThreeDSession session) {
    final params = {
      'creq': session.creq,
      'session_id': session.id,
      'transaction_id': session.transactionId,
      'return_url': 'https://app.videowindow.com/3ds-complete',
    };

    return '${session.acsUrl}?${Uri(queryParameters: params).query}';
  }

  /// Validate card token format
  TokenValidationResult _validateCardToken(String token) {
    switch (_provider) {
      case ThreeDProvider.stripe:
        if (token.startsWith('tok_') || token.startsWith('pm_')) {
          return TokenValidationResult(isValid: true);
        }
        return TokenValidationResult(
          isValid: false,
          errorMessage: 'Invalid Stripe token format',
        );
      case ThreeDProvider.braintree:
        if (token.startsWith('bt_')) {
          return TokenValidationResult(isValid: true);
        }
        return TokenValidationResult(
          isValid: false,
          errorMessage: 'Invalid Braintree token format',
        );
      case ThreeDProvider.adyen:
        if (token.length >= 20) {
          return TokenValidationResult(isValid: true);
        }
        return TokenValidationResult(
          isValid: false,
          errorMessage: 'Invalid Adyen token format',
        );
    }
  }

  /// Get 3D Secure configuration for a specific provider
  Future<ThreeDConfiguration> getConfiguration() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/configuration'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'X-Api-Secret': _apiSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ThreeDConfiguration.fromJson(data);
      } else {
        throw Exception('Failed to get 3D Secure configuration: ${response.body}');
      }
    } catch (e) {
      // Return default configuration
      return ThreeDConfiguration(
        provider: _provider,
        challengePreference: ChallengePreference.challenge,
        exemptionEnabled: true,
        maxAmountForExemption: 30.0,
      );
    }
  }

  /// Check if a transaction qualifies for 3D Secure exemption
  Future<bool> qualifiesForExemption({
    required double amount,
    required String cardToken,
    required Map<String, dynamic> transactionData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/exemption-check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Api-Secret': _apiSecret,
        },
        body: json.encode({
          'amount': amount,
          'card_token': cardToken,
          'transaction_data': transactionData,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['exemption_granted'] as bool;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Handle 3D Secure authentication in a webview
  Widget buildChallengeWebView({
    required String challengeUrl,
    required void Function(ThreeDSecureResult) onComplete,
  }) {
    // This would be implemented with a webview package
    // For now, return a placeholder
    return Container(
      child: Text('3D Secure Challenge WebView would be rendered here'),
    );
  }
}

/// 3D Secure provider options
enum ThreeDProvider {
  stripe,
  braintree,
  adyen,
}

/// 3D Secure authentication result
class ThreeDSecureResult {
  final bool success;
  final ThreeDAuthenticationStatus authenticationStatus;
  final String? error;
  final FraudRiskLevel riskLevel;
  final String? challengeUrl;
  final String? acsUrl;
  final String? creq;
  final String? transactionId;
  final String? cavv;
  final String? eci;
  final String? dsTransId;
  final String? threeDSServerTransId;
  final String? messageVersion;

  ThreeDSecureResult({
    required this.success,
    required this.authenticationStatus,
    this.error,
    required this.riskLevel,
    this.challengeUrl,
    this.acsUrl,
    this.creq,
    this.transactionId,
    this.cavv,
    this.eci,
    this.dsTransId,
    this.threeDSServerTransId,
    this.messageVersion,
  });

  factory ThreeDSecureResult.fromJson(Map<String, dynamic> json) {
    return ThreeDSecureResult(
      success: json['success'] as bool,
      authenticationStatus: ThreeDAuthenticationStatus.values.firstWhere(
        (e) => e.name == json['authentication_status'],
        orElse: () => ThreeDAuthenticationStatus.failed,
      ),
      error: json['error'] as String?,
      riskLevel: FraudRiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => FraudRiskLevel.low,
      ),
      challengeUrl: json['challenge_url'] as String?,
      acsUrl: json['acs_url'] as String?,
      creq: json['creq'] as String?,
      transactionId: json['transaction_id'] as String?,
      cavv: json['cavv'] as String?,
      eci: json['eci'] as String?,
      dsTransId: json['ds_trans_id'] as String?,
      threeDSServerTransId: json['three_ds_server_trans_id'] as String?,
      messageVersion: json['message_version'] as String?,
    );
  }

  bool get isAuthenticated => success &&
      (authenticationStatus == ThreeDAuthenticationStatus.successful ||
       authenticationStatus == ThreeDAuthenticationStatus.attempted);

  bool get requiresChallenge => authenticationStatus == ThreeDAuthenticationStatus.challengeRequired;
}

/// 3D Secure authentication status
enum ThreeDAuthenticationStatus {
  successful,
  attempted,
  failed,
  challengeRequired,
  error,
  cancelled,
}

/// 3D Secure session
class ThreeDSession {
  final String id;
  final String transactionId;
  final String acsUrl;
  final String creq;
  final DateTime createdAt;
  final DateTime expiresAt;

  ThreeDSession({
    required this.id,
    required this.transactionId,
    required this.acsUrl,
    required this.creq,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ThreeDSession.fromJson(Map<String, dynamic> json) {
    return ThreeDSession(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      acsUrl: json['acs_url'] as String,
      creq: json['creq'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// 3D Secure risk assessment
class ThreeDRiskAssessment {
  final double riskScore;
  final bool requiresStepUp;
  final List<String> riskFactors;
  final ThreeDAction recommendedAction;
  final FraudRiskLevel riskLevel;

  ThreeDRiskAssessment({
    required this.riskScore,
    required this.requiresStepUp,
    required this.riskFactors,
    required this.recommendedAction,
    required this.riskLevel,
  });

  factory ThreeDRiskAssessment.fromJson(Map<String, dynamic> json) {
    return ThreeDRiskAssessment(
      riskScore: (json['risk_score'] as num).toDouble(),
      requiresStepUp: json['requires_step_up'] as bool,
      riskFactors: List<String>.from(json['risk_factors'] as List),
      recommendedAction: ThreeDAction.values.firstWhere(
        (e) => e.name == json['recommended_action'],
        orElse: () => ThreeDAction.challenge,
      ),
      riskLevel: FraudRiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => FraudRiskLevel.medium,
      ),
    );
  }
}

/// 3D Secure action types
enum ThreeDAction {
  frictionless,
  challenge,
  decline,
  exempt,
}

/// 3D Secure configuration
class ThreeDConfiguration {
  final ThreeDProvider provider;
  final ChallengePreference challengePreference;
  final bool exemptionEnabled;
  final double maxAmountForExemption;

  ThreeDConfiguration({
    required this.provider,
    required this.challengePreference,
    required this.exemptionEnabled,
    required this.maxAmountForExemption,
  });

  factory ThreeDConfiguration.fromJson(Map<String, dynamic> json) {
    return ThreeDConfiguration(
      provider: ThreeDProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => ThreeDProvider.stripe,
      ),
      challengePreference: ChallengePreference.values.firstWhere(
        (e) => e.name == json['challenge_preference'],
        orElse: () => ChallengePreference.challenge,
      ),
      exemptionEnabled: json['exemption_enabled'] as bool,
      maxAmountForExemption: (json['max_amount_for_exemption'] as num).toDouble(),
    );
  }
}

/// Challenge preference options
enum ChallengePreference {
  noPreference,
  challenge,
  noChallenge,
}

/// Fraud risk level (duplicate from fraud detection model)
enum FraudRiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Validation result for 3D Secure authentication request
class ThreeDValidationResult {
  final bool isValid;
  final String? errorMessage;
  final FraudRiskLevel riskLevel;

  ThreeDValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.riskLevel,
  });
}

/// Token validation result
class TokenValidationResult {
  final bool isValid;
  final String? errorMessage;

  TokenValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}