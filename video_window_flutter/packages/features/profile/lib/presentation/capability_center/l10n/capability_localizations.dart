/// Localization strings for capability feature
/// Extracted from hard-coded strings to support future i18n
class CapabilityLocalizations {
  const CapabilityLocalizations();

  /// Status labels for capabilities
  String get statusInactive => 'Inactive';
  String get statusInProgress => 'In Progress';
  String get statusInReview => 'In Review';
  String get statusReady => 'Ready';
  String get statusBlocked => 'Blocked';

  /// Get status label by enum or string value
  String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
      case 'active':
        return statusReady;
      case 'in_review':
      case 'inreview':
      case 'pending':
        return statusInReview;
      case 'blocked':
        return statusBlocked;
      case 'inactive':
      default:
        return statusInactive;
    }
  }
}

/// Default instance for English localization
const capabilityLocalizations = CapabilityLocalizations();

