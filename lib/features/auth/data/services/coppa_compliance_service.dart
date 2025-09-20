import 'package:flutter/foundation.dart';

class COPPAComplianceService {
  static const int _minimumAge = 13;
  static const Duration _consentRetentionPeriod = Duration(
    days: 365 * 7,
  ); // 7 years

  /// Validate age verification and check COPPA compliance
  COPPAResult validateAgeVerification({
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
    String? parentalEmail,
    String? parentId,
    Map<String, dynamic>? consentData,
  }) {
    final age = _calculateAge(birthDate);
    final isUnderAge = age < _minimumAge;

    if (isUnderAge) {
      // Check if parental consent is provided
      if (parentalEmail != null && parentId != null) {
        return COPPAResult(
          isCompliant: true,
          requiresParentalConsent: true,
          parentalConsentProvided: true,
          age: age,
          minimumAge: _minimumAge,
          birthDate: birthDate,
          parentalEmail: parentalEmail,
          parentId: parentId,
          consentDate: DateTime.now(),
          ipAddress: ipAddress,
          userAgent: userAgent,
          consentData: consentData,
        );
      } else {
        return COPPAResult(
          isCompliant: false,
          requiresParentalConsent: true,
          parentalConsentProvided: false,
          age: age,
          minimumAge: _minimumAge,
          birthDate: birthDate,
          ipAddress: ipAddress,
          userAgent: userAgent,
          reason: 'Parental consent required for users under $_minimumAge',
        );
      }
    } else {
      // User is of age, no parental consent needed
      return COPPAResult(
        isCompliant: true,
        requiresParentalConsent: false,
        parentalConsentProvided: false,
        age: age,
        minimumAge: _minimumAge,
        birthDate: birthDate,
        consentDate: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        consentData: consentData,
      );
    }
  }

  /// Validate COPPA compliance for an existing user
  Future<COPPAResult> validateUserCompliance({
    required String userId,
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
    String? parentalEmail,
    String? parentId,
    Map<String, dynamic>? consentData,
  }) async {
    // Check if user already has valid consent
    final hasValidConsent = await _hasValidParentalConsent(userId);

    final age = _calculateAge(birthDate);
    final isUnderAge = age < _minimumAge;

    if (isUnderAge && !hasValidConsent) {
      return COPPAResult(
        isCompliant: false,
        requiresParentalConsent: true,
        parentalConsentProvided: false,
        age: age,
        minimumAge: _minimumAge,
        birthDate: birthDate,
        ipAddress: ipAddress,
        userAgent: userAgent,
        reason: 'Valid parental consent required for users under $_minimumAge',
      );
    }

    return validateAgeVerification(
      birthDate: birthDate,
      ipAddress: ipAddress,
      userAgent: userAgent,
      parentalEmail: parentalEmail,
      parentId: parentId,
      consentData: consentData,
    );
  }

  /// Record parental consent
  Future<ParentalConsentRecord> recordParentalConsent({
    required String userId,
    required String childUserId,
    required String parentalEmail,
    required String parentId,
    required ConsentMethod consentMethod,
    required String ipAddress,
    required String userAgent,
    Map<String, dynamic>? consentData,
  }) async {
    final consentRecord = ParentalConsentRecord(
      id: _generateId(),
      userId: userId,
      childUserId: childUserId,
      parentalEmail: parentalEmail,
      parentId: parentId,
      consentMethod: consentMethod,
      consentDate: DateTime.now(),
      expirationDate: DateTime.now().add(_consentRetentionPeriod),
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: true,
      consentData: consentData,
    );

    // Store consent record (mock implementation)
    await _storeConsentRecord(consentRecord);

    return consentRecord;
  }

  /// Check if parental consent is still valid
  Future<bool> isParentalConsentValid(String userId) async {
    final consentRecord = await _getConsentRecord(userId);
    if (consentRecord == null) return false;

    return consentRecord.isActive &&
        consentRecord.expirationDate.isAfter(DateTime.now());
  }

  /// Generate age verification request
  AgeVerificationRequest generateAgeVerificationRequest({
    required String userId,
    required String email,
    required String? ipAddress,
    required String? userAgent,
  }) {
    return AgeVerificationRequest(
      id: _generateId(),
      userId: userId,
      email: email,
      requestDate: DateTime.now(),
      expirationDate: DateTime.now().add(const Duration(hours: 24)),
      ipAddress: ipAddress ?? 'unknown',
      userAgent: userAgent ?? 'unknown',
      status: AgeVerificationStatus.pending,
      verificationToken: _generateVerificationToken(),
    );
  }

  /// Validate age verification response
  COPPAResult validateAgeVerificationResponse({
    required String verificationToken,
    required DateTime birthDate,
    required String ipAddress,
    required String userAgent,
  }) {
    // Validate token (mock implementation)
    if (!_isValidVerificationToken(verificationToken)) {
      return COPPAResult(
        isCompliant: false,
        requiresParentalConsent: false,
        parentalConsentProvided: false,
        age: _calculateAge(birthDate),
        minimumAge: _minimumAge,
        birthDate: birthDate,
        ipAddress: ipAddress,
        userAgent: userAgent,
        reason: 'Invalid verification token',
      );
    }

    return validateAgeVerification(
      birthDate: birthDate,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  /// Calculate age from birth date
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Adjust if birthday hasn't occurred yet this year
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Generate unique ID
  String _generateId() {
    return 'coppa_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
  }

  /// Generate verification token
  String _generateVerificationToken() {
    return 'verify_${DateTime.now().millisecondsSinceEpoch}_${_randomString(16)}';
  }

  /// Generate random string
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecond;
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (i) => chars.codeUnitAt((random + i) % chars.length),
      ),
    );
  }

  /// Check if user has valid parental consent (mock)
  Future<bool> _hasValidParentalConsent(String userId) async {
    // In a real implementation, this would check the database
    // For now, return false to indicate no consent exists
    return false;
  }

  /// Store consent record (mock)
  Future<void> _storeConsentRecord(ParentalConsentRecord record) async {
    if (kDebugMode) {
      print('Storing COPPA consent record: ${record.toJson()}');
    }
  }

  /// Get consent record (mock)
  Future<ParentalConsentRecord?> _getConsentRecord(String userId) async {
    // In a real implementation, this would query the database
    // For now, return null to indicate no record exists
    return null;
  }

  /// Validate verification token (mock)
  bool _isValidVerificationToken(String token) {
    // In a real implementation, this would validate against stored tokens
    // For now, return true to simulate valid token
    return true;
  }
}

class COPPAResult {
  final bool isCompliant;
  final bool requiresParentalConsent;
  final bool parentalConsentProvided;
  final int age;
  final int minimumAge;
  final DateTime birthDate;
  final DateTime? consentDate;
  final String ipAddress;
  final String userAgent;
  final String? parentalEmail;
  final String? parentId;
  final Map<String, dynamic>? consentData;
  final String? reason;

  COPPAResult({
    required this.isCompliant,
    required this.requiresParentalConsent,
    required this.parentalConsentProvided,
    required this.age,
    required this.minimumAge,
    required this.birthDate,
    this.consentDate,
    required this.ipAddress,
    required this.userAgent,
    this.parentalEmail,
    this.parentId,
    this.consentData,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'is_compliant': isCompliant,
      'requires_parental_consent': requiresParentalConsent,
      'parental_consent_provided': parentalConsentProvided,
      'age': age,
      'minimum_age': minimumAge,
      'birth_date': birthDate.toIso8601String(),
      'consent_date': consentDate?.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'parental_email': parentalEmail,
      'parent_id': parentId,
      'consent_data': consentData,
      'reason': reason,
    };
  }
}

class ParentalConsentRecord {
  final String id;
  final String userId;
  final String childUserId;
  final String parentalEmail;
  final String parentId;
  final ConsentMethod consentMethod;
  final DateTime consentDate;
  final DateTime expirationDate;
  final String ipAddress;
  final String userAgent;
  final bool isActive;
  final Map<String, dynamic>? consentData;

  ParentalConsentRecord({
    required this.id,
    required this.userId,
    required this.childUserId,
    required this.parentalEmail,
    required this.parentId,
    required this.consentMethod,
    required this.consentDate,
    required this.expirationDate,
    required this.ipAddress,
    required this.userAgent,
    required this.isActive,
    this.consentData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'child_user_id': childUserId,
      'parental_email': parentalEmail,
      'parent_id': parentId,
      'consent_method': consentMethod.name,
      'consent_date': consentDate.toIso8601String(),
      'expiration_date': expirationDate.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'is_active': isActive,
      'consent_data': consentData,
    };
  }
}

class AgeVerificationRequest {
  final String id;
  final String userId;
  final String email;
  final DateTime requestDate;
  final DateTime expirationDate;
  final String ipAddress;
  final String userAgent;
  final AgeVerificationStatus status;
  final String verificationToken;

  AgeVerificationRequest({
    required this.id,
    required this.userId,
    required this.email,
    required this.requestDate,
    required this.expirationDate,
    required this.ipAddress,
    required this.userAgent,
    required this.status,
    required this.verificationToken,
  });

  bool get isExpired => DateTime.now().isAfter(expirationDate);
}

enum ConsentMethod {
  emailVerification,
  documentUpload,
  idVerification,
  parentalAccount,
  thirdPartyService,
}

enum AgeVerificationStatus { pending, verified, expired, failed }
