// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get capabilityStatusInactive => 'Inactive';

  @override
  String get capabilityStatusInReview => 'In Review';

  @override
  String get capabilityStatusReady => 'Ready';

  @override
  String get capabilityStatusBlocked => 'Blocked';

  @override
  String get capabilityPageTitle => 'Capabilities';

  @override
  String get capabilityPageHeadline => 'Manage Your Capabilities';

  @override
  String get capabilityPageDescription =>
      'Enable capabilities to unlock publishing, payments, and fulfillment features.';

  @override
  String get capabilityPublishTitle => 'Publish Stories';

  @override
  String get capabilityPublishDescription =>
      'Share your video stories with the community';

  @override
  String get capabilityPaymentsTitle => 'Collect Payments';

  @override
  String get capabilityPaymentsDescription =>
      'Accept payments from buyers through secure checkout';

  @override
  String get capabilityFulfillmentTitle => 'Fulfill Orders';

  @override
  String get capabilityFulfillmentDescription =>
      'Manage order fulfillment and shipping tracking';

  @override
  String get capabilityActionEnabled => 'Enabled';

  @override
  String get capabilityActionEnablePublishing => 'Enable Publishing';

  @override
  String get capabilityActionEnablePayments => 'Enable Payments';

  @override
  String get capabilityActionEnableFulfillment => 'Enable Fulfillment';

  @override
  String get capabilityPollingMessage => 'Checking for updates...';

  @override
  String get capabilityErrorTitle => 'Failed to Load Capabilities';

  @override
  String get capabilityErrorRetry => 'Retry';
}
