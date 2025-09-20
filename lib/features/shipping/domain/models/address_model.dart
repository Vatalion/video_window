import 'package:equatable/equatable.dart';

/// Address model representing a shipping address
class AddressModel extends Equatable {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String company;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final bool isResidential;
  final String phoneNumber;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isValidated;
  final String? validationStatus;
  final Map<String, dynamic>? validationDetails;
  final Map<String, dynamic>? metadata;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    required this.isResidential,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.isValidated,
    this.validationStatus,
    this.validationDetails,
    this.metadata,
  });

  /// Create a copy of this address with updated fields
  AddressModel copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? company,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    bool? isResidential,
    String? phoneNumber,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isValidated,
    String? validationStatus,
    Map<String, dynamic>? validationDetails,
    Map<String, dynamic>? metadata,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      isResidential: isResidential ?? this.isResidential,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isValidated: isValidated ?? this.isValidated,
      validationStatus: validationStatus ?? this.validationStatus,
      validationDetails: validationDetails ?? this.validationDetails,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get full formatted address
  String get fullAddress {
    final lines = <String>[];

    if (company.isNotEmpty) {
      lines.add(company);
    }

    lines.add('$firstName $lastName');
    lines.add(addressLine1);

    if (addressLine2.isNotEmpty) {
      lines.add(addressLine2);
    }

    lines.add('$city, $state $postalCode');
    lines.add(country);

    return lines.join('\n');
  }

  /// Get short address (city, state)
  String get shortAddress => '$city, $state';

  /// Validate required fields
  bool get isValid {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           addressLine1.isNotEmpty &&
           city.isNotEmpty &&
           state.isNotEmpty &&
           postalCode.isNotEmpty &&
           country.isNotEmpty &&
           email.isNotEmpty;
  }

  /// Check if address is international
  bool get isInternational => country.toUpperCase() != 'US';

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
      'isResidential': isResidential,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isValidated': isValidated,
      'validationStatus': validationStatus,
      'validationDetails': validationDetails,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      userId: json['userId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      company: json['company'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
      isDefault: json['isDefault'] ?? false,
      isResidential: json['isResidential'] ?? false,
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isValidated: json['isValidated'] ?? false,
      validationStatus: json['validationStatus'],
      validationDetails: json['validationDetails'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      userId,
      firstName,
      lastName,
      company,
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
      isDefault,
      isResidential,
      phoneNumber,
      email,
      createdAt,
      updatedAt,
      isValidated,
    ];
  }
}