/// Localization strings for capability statuses
///
/// AC1 (Task 3): Add localization strings for capability statuses
class CapabilityStrings {
  CapabilityStrings._();

  // Status labels
  static const String statusInactive = 'Inactive';
  static const String statusInProgress = 'In Progress';
  static const String statusInReview = 'In Review';
  static const String statusReady = 'Ready';
  static const String statusBlocked = 'Blocked';

  // Capability names
  static const String capabilityPublish = 'Publish Stories';
  static const String capabilityCollectPayments = 'Collect Payments';
  static const String capabilityFulfillOrders = 'Fulfill Orders';

  // Descriptions
  static const String publishDescription =
      'Share your video stories with the community';
  static const String paymentsDescription =
      'Accept payments from buyers through secure checkout';
  static const String fulfillmentDescription =
      'Manage order fulfillment and shipping tracking';

  // Actions
  static const String actionEnable = 'Enable';
  static const String actionEnabled = 'Enabled';
  static const String actionEnablePublishing = 'Enable Publishing';
  static const String actionEnablePayments = 'Enable Payments';
  static const String actionEnableFulfillment = 'Enable Fulfillment';
  static const String actionSetupPayments = 'Set Up Payments';
  static const String actionCancel = 'Cancel';
  static const String actionRetry = 'Retry';
  static const String actionRefresh = 'Refresh';

  // Messages
  static const String messageCheckingUpdates = 'Checking for updates...';
  static const String messagePublishingLocked = 'Publishing Locked';
  static const String messagePaymentSetupRequired = 'Payment Setup Required';
  static const String messageFulfillmentNotEnabled = 'Fulfillment Not Enabled';
  static const String messageFailedToLoad = 'Failed to Load Capabilities';

  // Requirements
  static const String requirementIdentityVerification =
      'Complete identity verification';
  static const String requirementCreatorTerms = 'Accept creator terms';
  static const String requirementContactVerification =
      'Verify contact information';
  static const String requirementStripeAccount =
      'Connect Stripe payout account';
  static const String requirementTaxInfo = 'Provide tax information';
  static const String requirementPaymentEnabled =
      'Payment collection must be enabled';
  static const String requirementTrustedDevice =
      'Trusted device registration required';

  // Headers
  static const String headerManageCapabilities = 'Manage Your Capabilities';
  static const String headerCapabilities = 'Capabilities';
  static const String headerRequirements = 'Requirements:';
  static const String headerCompleteSteps = 'Complete These Steps:';
  static const String headerPrerequisites = 'Prerequisites:';

  // Body text
  static const String bodyCapabilityDescription =
      'Enable capabilities to unlock publishing, payments, and fulfillment features.';
  static const String bodyPublishSteps =
      'Complete these steps to publish your story';
  static const String bodyPaymentSetup = 'Set up payments to start selling';
  static const String bodyFulfillmentInfo =
      'Enable order fulfillment to manage shipping and tracking';
}
