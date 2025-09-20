import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'address_model.g.dart';

enum AddressType {
  shipping,
  billing,
  both,
}

@JsonSerializable()
class AddressModel extends Equatable {
  final String id;
  final String userId;
  final AddressType type;
  final String firstName;
  final String lastName;
  final String company;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phone;
  final bool isDefault;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phone,
    this.isDefault = false,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  AddressModel copyWith({
    String? id,
    String? userId,
    AddressType? type,
    String? firstName,
    String? lastName,
    String? company,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phone,
    bool? isDefault,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName';
  String get fullAddress {
    final lines = [
      if (company.isNotEmpty) company,
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      '$city, $state $postalCode',
      country,
    ];
    return lines.where((line) => line.isNotEmpty).join('\n');
  }

  List<ValidationRule> validate() {
    final rules = <ValidationRule>[];

    if (firstName.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'firstName',
        message: 'First name is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (lastName.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'lastName',
        message: 'Last name is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (addressLine1.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'addressLine1',
        message: 'Address line 1 is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (city.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'city',
        message: 'City is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (state.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'state',
        message: 'State is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (postalCode.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'postalCode',
        message: 'Postal code is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (country.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'country',
        message: 'Country is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    // Phone validation
    if (phone.trim().isEmpty) {
      rules.add(ValidationRule(
        field: 'phone',
        message: 'Phone number is required',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    } else if (!RegExp(r'^[\+]?[\d\s\-\(\)]{10,}$').hasMatch(phone)) {
      rules.add(ValidationRule(
        field: 'phone',
        message: 'Invalid phone number format',
        type: ValidationType.format,
        severity: ValidationSeverity.warning,
      ));
    }

    // PCI compliance check for address
    if (firstName.toLowerCase().contains('test') ||
        lastName.toLowerCase().contains('test')) {
      rules.add(ValidationRule(
        field: 'name',
        message: 'Test names are not allowed for real transactions',
        type: ValidationType.pci,
        severity: ValidationSeverity.error,
      ));
    }

    return rules;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        firstName,
        lastName,
        company,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        phone,
        isDefault,
        isVerified,
        createdAt,
        updatedAt,
      ];
}