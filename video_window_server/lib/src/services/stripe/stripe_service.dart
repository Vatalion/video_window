import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../capabilities/capability_service.dart';
import '../verification_service.dart';
import '../../generated/capabilities/capability_type.dart';
import '../../generated/capabilities/verification_task_type.dart';
import '../../generated/capabilities/verification_task_status.dart';
import '../../generated/capabilities/verification_task.dart';
import '../../generated/capabilities/user_capabilities.dart';

/// Stripe service for payout onboarding and webhook handling
/// Implements Story 2-3: Payout & Compliance Activation
class StripeService {
  final Session _session;
  String? _apiKey;
  String? _webhookSecret;

  StripeService(this._session) {
    // Initialize Stripe API key from config
    // In production, this should come from secure config
    _apiKey = _getStripeApiKey();
    _webhookSecret = _getStripeWebhookSecret();
  }

  /// Get Stripe API key from configuration
  String? _getStripeApiKey() {
    // TODO: Load from config/environment securely
    // For now, return null - will be configured via environment variables
    return null;
  }

  /// Get Stripe webhook secret from configuration
  String? _getStripeWebhookSecret() {
    // TODO: Load from config/environment securely
    // For now, return null - will be configured via environment variables
    return null;
  }

  /// Create Stripe Express account onboarding link
  ///
  /// AC1: Provides Stripe Express onboarding CTA
  /// Returns onboarding URL for user to complete payout setup
  Future<String> createOnboardingLink({
    required int userId,
    required String returnUrl,
  }) async {
    try {
      // Create Express account if it doesn't exist
      final accountId = await _getOrCreateExpressAccount(userId);

      // Create account link for onboarding via Stripe API
      final accountLinkResponse = await _stripeApiCall(
        'POST',
        '/v1/account_links',
        {
          'account': accountId,
          'refresh_url': returnUrl,
          'return_url': returnUrl,
          'type': 'account_onboarding',
        },
      );

      _session.log(
        'Stripe onboarding link created for user $userId, account: $accountId',
        level: LogLevel.info,
      );

      return accountLinkResponse['url'] as String;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to create Stripe onboarding link for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get or create Stripe Express account for user
  Future<String> _getOrCreateExpressAccount(int userId) async {
    try {
      // Check if account already exists in verification task payload
      final tasks = await VerificationTask.db.find(
        _session,
        where: (t) =>
            t.userId.equals(userId) &
            t.capability.equals(CapabilityType.collectPayments),
      );

      // Find existing Stripe account ID
      for (final task in tasks) {
        if (task.taskType == VerificationTaskType.stripePayout) {
          final payload = jsonDecode(task.payload) as Map<String, dynamic>;
          final accountId = payload['stripeAccountId'] as String?;
          if (accountId != null && accountId.isNotEmpty) {
            return accountId;
          }
        }
      }

      // AC7: Emit payout_activation_started analytics event
      _session.log(
        '[ANALYTICS] payout_activation_started | userId=$userId | entryPoint=stripe_onboarding',
        level: LogLevel.info,
      );

      // Create new Express account via Stripe API
      final accountResponse = await _stripeApiCall(
        'POST',
        '/v1/accounts',
        {
          'type': 'express',
          'country': 'US', // TODO: Get from user profile
          'email': '', // TODO: Get from user profile
        },
      );

      final accountId = accountResponse['id'] as String;

      // Store account ID in verification task
      final verificationService = VerificationService(_session);
      await verificationService.createVerificationTask(
        userId: userId,
        capability: CapabilityType.collectPayments,
        taskType: VerificationTaskType.stripePayout,
        metadata: {
          'stripeAccountId': accountId,
          'status': 'pending',
        },
      );

      _session.log(
        'Stripe Express account created for user $userId: $accountId',
        level: LogLevel.info,
      );

      return accountId;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get or create Stripe account for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Handle Stripe webhook event
  ///
  /// AC2: Processes Stripe webhook to update payoutConfiguredAt
  /// AC5: Emits capability.unlocked audit event
  Future<void> handleWebhook({
    required String payload,
    required String signature,
  }) async {
    try {
      // Verify webhook signature
      if (_webhookSecret == null || _webhookSecret!.isEmpty) {
        _session.log(
          'Stripe webhook secret not configured, skipping signature validation',
          level: LogLevel.warning,
        );
      } else {
        final isValid = _verifyWebhookSignature(
          payload: payload,
          signature: signature,
          secret: _webhookSecret!,
        );
        if (!isValid) {
          throw Exception('Invalid Stripe webhook signature');
        }
      }

      final event = jsonDecode(payload) as Map<String, dynamic>;
      final eventType = event['type'] as String;

      _session.log(
        'Processing Stripe webhook event: $eventType',
        level: LogLevel.info,
      );

      switch (eventType) {
        case 'account.updated':
          await _handleAccountUpdated(
              event['data']['object'] as Map<String, dynamic>);
          break;
        case 'account.application.deauthorized':
          await _handleAccountDeauthorized(
              event['data']['object'] as Map<String, dynamic>);
          break;
        default:
          _session.log(
            'Unhandled Stripe webhook event type: $eventType',
            level: LogLevel.info,
          );
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to handle Stripe webhook: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Handle account.updated webhook event
  Future<void> _handleAccountUpdated(Map<String, dynamic> account) async {
    try {
      final accountId = account['id'] as String;
      final chargesEnabled = account['charges_enabled'] as bool? ?? false;
      final payoutsEnabled = account['payouts_enabled'] as bool? ?? false;
      final requirementsDue =
          account['requirements']?['currently_due'] as List<dynamic>? ?? [];

      // Find verification task by Stripe account ID
      final allTasks = await VerificationTask.db.find(
        _session,
        where: (t) => t.taskType.equals(VerificationTaskType.stripePayout),
      );

      VerificationTask? matchingTask;
      for (final task in allTasks) {
        final payload = jsonDecode(task.payload) as Map<String, dynamic>;
        if (payload['stripeAccountId'] == accountId) {
          matchingTask = task;
          break;
        }
      }

      if (matchingTask == null) {
        _session.log(
          'No verification task found for Stripe account: $accountId',
          level: LogLevel.warning,
        );
        return;
      }

      final capabilityService = CapabilityService(_session);

      // Update verification task payload with current status
      final currentPayload =
          jsonDecode(matchingTask.payload) as Map<String, dynamic>;
      currentPayload.addAll({
        'chargesEnabled': chargesEnabled,
        'payoutsEnabled': payoutsEnabled,
        'requirementsDue': requirementsDue.map((e) => e.toString()).toList(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      matchingTask.payload = jsonEncode(currentPayload);
      matchingTask.updatedAt = DateTime.now().toUtc();
      await VerificationTask.db.updateRow(_session, matchingTask);

      // If account is fully enabled, complete verification and unlock capability
      if (chargesEnabled && payoutsEnabled && requirementsDue.isEmpty) {
        matchingTask.status = VerificationTaskStatus.completed;
        matchingTask.completedAt = DateTime.now().toUtc();
        await VerificationTask.db.updateRow(_session, matchingTask);

        // Update capability
        await capabilityService.updateCapability(
          userId: matchingTask.userId,
          capability: CapabilityType.collectPayments,
          enabled: true,
        );

        // AC5: Audit event is emitted by updateCapability method
        // AC7: Emit payout_activation_completed analytics event
        _session.log(
          '[ANALYTICS] payout_activation_completed | userId=${matchingTask.userId} | capability=collectPayments | stripeAccountId=$accountId | success=true',
          level: LogLevel.info,
        );

        // Additional logging for capability.unlocked event
        _session.log(
          '[AUDIT] capability.unlocked | userId=${matchingTask.userId} | capability=collectPayments | stripeAccountId=$accountId',
          level: LogLevel.info,
        );

        _session.log(
          'Payout capability unlocked for user ${matchingTask.userId} via Stripe webhook',
          level: LogLevel.info,
        );
      } else {
        // Update blockers map with requirements due
        final blockers = <String, String>{};
        if (!chargesEnabled) {
          blockers['stripe_charges_disabled'] =
              'Stripe account charges not enabled';
        }
        if (!payoutsEnabled) {
          blockers['stripe_payouts_disabled'] =
              'Stripe account payouts not enabled';
        }
        if (requirementsDue.isNotEmpty) {
          blockers['stripe_requirements_due'] =
              'Stripe account requirements pending: ${requirementsDue.join(", ")}';
        }

        // Update user capabilities blockers
        final capabilities =
            await capabilityService.getUserCapabilities(matchingTask.userId);
        final currentBlockers =
            jsonDecode(capabilities.blockers) as Map<String, dynamic>;
        currentBlockers.addAll(blockers);
        capabilities.blockers = jsonEncode(currentBlockers);
        await UserCapabilities.db.updateRow(_session, capabilities);
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to handle account.updated webhook: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Handle account deauthorization
  Future<void> _handleAccountDeauthorized(Map<String, dynamic> account) async {
    try {
      final accountId = account['id'] as String;

      // Find and mark verification task as failed
      final allTasks = await VerificationTask.db.find(
        _session,
        where: (t) => t.taskType.equals(VerificationTaskType.stripePayout),
      );

      for (final task in allTasks) {
        final payload = jsonDecode(task.payload) as Map<String, dynamic>;
        if (payload['stripeAccountId'] == accountId) {
          task.status = VerificationTaskStatus.failed;
          task.updatedAt = DateTime.now().toUtc();
          await VerificationTask.db.updateRow(_session, task);

          // Revoke capability
          final capabilityService = CapabilityService(_session);
          await capabilityService.updateCapability(
            userId: task.userId,
            capability: CapabilityType.collectPayments,
            enabled: false,
          );

          _session.log(
            'Stripe account deauthorized for user ${task.userId}, capability revoked',
            level: LogLevel.warning,
          );
          break;
        }
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to handle account deauthorization: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Verify Stripe webhook signature
  bool _verifyWebhookSignature({
    required String payload,
    required String signature,
    required String secret,
  }) {
    try {
      // Stripe webhook signature format: timestamp,signature
      final parts = signature.split(',');
      if (parts.length != 2) {
        return false;
      }

      final timestamp = parts[0].split('=')[1];
      final signatureHash = parts[1].split('=')[1];

      // Create expected signature
      final signedPayload = '$timestamp.$payload';
      final bytes = utf8.encode(signedPayload);
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(bytes);
      final expectedSignature = digest.toString();

      return expectedSignature == signatureHash;
    } catch (e) {
      _session.log(
        'Error verifying Stripe webhook signature: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Get Stripe account requirements for user
  Future<Map<String, dynamic>> getAccountRequirements(int userId) async {
    try {
      final tasks = await VerificationTask.db.find(
        _session,
        where: (t) =>
            t.userId.equals(userId) &
            t.capability.equals(CapabilityType.collectPayments),
      );

      for (final task in tasks) {
        if (task.taskType == VerificationTaskType.stripePayout) {
          final payload = jsonDecode(task.payload) as Map<String, dynamic>;
          final accountId = payload['stripeAccountId'] as String?;
          if (accountId != null) {
            final account =
                await _stripeApiCall('GET', '/v1/accounts/$accountId', {});
            return {
              'chargesEnabled': account['charges_enabled'] ?? false,
              'payoutsEnabled': account['payouts_enabled'] ?? false,
              'requirementsDue':
                  account['requirements']?['currently_due'] ?? [],
            };
          }
        }
      }

      return {
        'chargesEnabled': false,
        'payoutsEnabled': false,
        'requirementsDue': [],
      };
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get Stripe account requirements for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return {
        'chargesEnabled': false,
        'payoutsEnabled': false,
        'requirementsDue': [],
      };
    }
  }

  /// Make Stripe API call using HTTP
  Future<Map<String, dynamic>> _stripeApiCall(
    String method,
    String endpoint,
    Map<String, dynamic> params,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Stripe API key not configured');
    }

    final uri = Uri.parse('https://api.stripe.com$endpoint');
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      final body = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      response = await http.post(uri, headers: headers, body: body);
    } else {
      throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Stripe API error: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
