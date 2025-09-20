import 'package:equatable/equatable.dart';

/// Address validation result model
class AddressValidationModel extends Equatable {
  final bool isValid;
  final String status;
  final String message;
  final AddressModel? correctedAddress;
  final List<String> suggestions;
  final Map<String, dynamic> validationDetails;
  final List<String> errorCodes;
  final DateTime validatedAt;

  const AddressValidationModel({
    required this.isValid,
    required this.status,
    required this.message,
    this.correctedAddress,
    required this.suggestions,
    required this.validationDetails,
    required this.errorCodes,
    required this.validatedAt,
  });

  /// Create a copy of this validation result with updated fields
  AddressValidationModel copyWith({
    bool? isValid,
    String? status,
    String? message,
    AddressModel? correctedAddress,
    List<String>? suggestions,
    Map<String, dynamic>? validationDetails,
    List<String>? errorCodes,
    DateTime? validatedAt,
  }) {
    return AddressValidationModel(
      isValid: isValid ?? this.isValid,
      status: status ?? this.status,
      message: message ?? this.message,
      correctedAddress: correctedAddress ?? this.correctedAddress,
      suggestions: suggestions ?? this.suggestions,
      validationDetails: validationDetails ?? this.validationDetails,
      errorCodes: errorCodes ?? this.errorCodes,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'status': status,
      'message': message,
      'correctedAddress': correctedAddress?.toJson(),
      'suggestions': suggestions,
      'validationDetails': validationDetails,
      'errorCodes': errorCodes,
      'validatedAt': validatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AddressValidationModel.fromJson(Map<String, dynamic> json) {
    return AddressValidationModel(
      isValid: json['isValid'] ?? false,
      status: json['status'] ?? 'unknown',
      message: json['message'] ?? '',
      correctedAddress: json['correctedAddress'] != null
          ? AddressModel.fromJson(json['correctedAddress'])
          : null,
      suggestions: List<String>.from(json['suggestions'] ?? []),
      validationDetails: Map<String, dynamic>.from(json['validationDetails'] ?? {}),
      errorCodes: List<String>.from(json['errorCodes'] ?? []),
      validatedAt: DateTime.parse(json['validatedAt']),
    );
  }

  @override
  List<Object> get props {
    return [
      isValid,
      status,
      message,
      suggestions,
      validationDetails,
      errorCodes,
      validatedAt,
    ];
  }
}