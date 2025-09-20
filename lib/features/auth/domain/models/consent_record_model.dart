import 'package:equatable/equatable.dart';

class ConsentRecordModel extends Equatable {
  final String id;
  final String userId;
  final ConsentType consentType;
  final DateTime consentDate;
  final String ipAddress;
  final String? userAgent;
  final Map<String, dynamic> consentData;

  const ConsentRecordModel({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.consentDate,
    required this.ipAddress,
    this.userAgent,
    required this.consentData,
  });

  factory ConsentRecordModel.fromJson(Map<String, dynamic> json) {
    return ConsentRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      consentType: ConsentType.values.firstWhere(
        (e) => e.name == json['consent_type'],
        orElse: () => ConsentType.ageVerification,
      ),
      consentDate: DateTime.parse(json['consent_date'] as String),
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String?,
      consentData: Map<String, dynamic>.from(json['consent_data'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'consent_type': consentType.name,
      'consent_date': consentDate.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'consent_data': consentData,
    };
  }

  ConsentRecordModel copyWith({
    String? id,
    String? userId,
    ConsentType? consentType,
    DateTime? consentDate,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? consentData,
  }) {
    return ConsentRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consentType: consentType ?? this.consentType,
      consentDate: consentDate ?? this.consentDate,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      consentData: consentData ?? this.consentData,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    consentType,
    consentDate,
    ipAddress,
    userAgent ?? '',
    consentData,
  ];
}

enum ConsentType {
  ageVerification,
  termsOfService,
  privacyPolicy,
  marketing,
  dataProcessing,
}
