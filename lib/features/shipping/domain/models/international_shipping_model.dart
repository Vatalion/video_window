import 'package:equatable/equatable.dart';

/// International shipping restriction model
class InternationalShippingRestrictionModel extends Equatable {
  final String id;
  final String originCountry;
  final String destinationCountry;
  final List<String> restrictedItems;
  final double maxWeightKg;
  final double maxValue;
  final List<String> requiredDocuments;
  final Map<String, dynamic> customsRegulations;
  final List<String> prohibitedItems;
  final double dutiesPercentage;
  final double taxesPercentage;
  final bool requiresLicense;
  final bool requiresInspection;
  final bool isRestricted;
  final DateTime updatedAt;

  const InternationalShippingRestrictionModel({
    required this.id,
    required this.originCountry,
    required this.destinationCountry,
    required this.restrictedItems,
    required this.maxWeightKg,
    required this.maxValue,
    required this.requiredDocuments,
    required this.customsRegulations,
    required this.prohibitedItems,
    required this.dutiesPercentage,
    required this.taxesPercentage,
    required this.requiresLicense,
    required this.requiresInspection,
    required this.isRestricted,
    required this.updatedAt,
  });

  /// Check if item is restricted
  bool isItemRestricted(String itemCategory) {
    return restrictedItems.contains(itemCategory) || prohibitedItems.contains(itemCategory);
  }

  /// Check if shipment meets weight requirements
  bool meetsWeightRequirements(double weightKg) {
    return weightKg <= maxWeightKg;
  }

  /// Check if shipment meets value requirements
  bool meetsValueRequirements(double value) {
    return value <= maxValue;
  }

  /// Calculate total duties and taxes
  double calculateDutiesAndTaxes(double value) {
    return (value * dutiesPercentage / 100) + (value * taxesPercentage / 100);
  }

  /// Get required documents list
  List<String> getRequiredDocuments() {
    return List.from(requiredDocuments);
  }

  /// Get customs information
  Map<String, dynamic> getCustomsInfo() {
    return Map.from(customsRegulations);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originCountry': originCountry,
      'destinationCountry': destinationCountry,
      'restrictedItems': restrictedItems,
      'maxWeightKg': maxWeightKg,
      'maxValue': maxValue,
      'requiredDocuments': requiredDocuments,
      'customsRegulations': customsRegulations,
      'prohibitedItems': prohibitedItems,
      'dutiesPercentage': dutiesPercentage,
      'taxesPercentage': taxesPercentage,
      'requiresLicense': requiresLicense,
      'requiresInspection': requiresInspection,
      'isRestricted': isRestricted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory InternationalShippingRestrictionModel.fromJson(Map<String, dynamic> json) {
    return InternationalShippingRestrictionModel(
      id: json['id'],
      originCountry: json['originCountry'],
      destinationCountry: json['destinationCountry'],
      restrictedItems: List<String>.from(json['restrictedItems']),
      maxWeightKg: json['maxWeightKg'].toDouble(),
      maxValue: json['maxValue'].toDouble(),
      requiredDocuments: List<String>.from(json['requiredDocuments']),
      customsRegulations: Map<String, dynamic>.from(json['customsRegulations']),
      prohibitedItems: List<String>.from(json['prohibitedItems']),
      dutiesPercentage: json['dutiesPercentage'].toDouble(),
      taxesPercentage: json['taxesPercentage'].toDouble(),
      requiresLicense: json['requiresLicense'],
      requiresInspection: json['requiresInspection'],
      isRestricted: json['isRestricted'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      originCountry,
      destinationCountry,
      restrictedItems,
      maxWeightKg,
      maxValue,
      requiredDocuments,
      customsRegulations,
      prohibitedItems,
      dutiesPercentage,
      taxesPercentage,
      requiresLicense,
      requiresInspection,
      isRestricted,
      updatedAt,
    ];
  }
}

/// International shipping form model
class InternationalShippingFormModel extends Equatable {
  final String id;
  final String orderId;
  final String exporterName;
  final String exporterAddress;
  final String importerName;
  final String importerAddress;
  final String descriptionOfGoods;
  final double value;
  final String currency;
  final double weightKg;
  final String countryOfOrigin;
  final String harmonizedCode;
  final List<String> specialInstructions;
  final bool isCommercialShipment;
  final String reasonForExport;
  final Map<String, dynamic> additionalInformation;
  final DateTime createdAt;
  final String status; // 'draft', 'submitted', 'approved', 'rejected', 'cleared'

  const InternationalShippingFormModel({
    required this.id,
    required this.orderId,
    required this.exporterName,
    required this.exporterAddress,
    required this.importerName,
    required this.importerAddress,
    required this.descriptionOfGoods,
    required this.value,
    required this.currency,
    required this.weightKg,
    required this.countryOfOrigin,
    required this.harmonizedCode,
    required this.specialInstructions,
    required this.isCommercialShipment,
    required this.reasonForExport,
    required this.additionalInformation,
    required this.createdAt,
    required this.status,
  });

  /// Get status display
  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cleared':
        return 'Cleared';
      default:
        return 'Unknown';
    }
  }

  /// Check if form is complete
  bool get isComplete {
    return exporterName.isNotEmpty &&
           exporterAddress.isNotEmpty &&
           importerName.isNotEmpty &&
           importerAddress.isNotEmpty &&
           descriptionOfGoods.isNotEmpty &&
           value > 0 &&
           weightKg > 0 &&
           countryOfOrigin.isNotEmpty &&
           harmonizedCode.isNotEmpty &&
           reasonForExport.isNotEmpty;
  }

  /// Get required fields missing
  List<String> get missingFields {
    final missing = <String>[];
    if (exporterName.isEmpty) missing.add('Exporter Name');
    if (exporterAddress.isEmpty) missing.add('Exporter Address');
    if (importerName.isEmpty) missing.add('Importer Name');
    if (importerAddress.isEmpty) missing.add('Importer Address');
    if (descriptionOfGoods.isEmpty) missing.add('Description of Goods');
    if (value <= 0) missing.add('Value');
    if (weightKg <= 0) missing.add('Weight');
    if (countryOfOrigin.isEmpty) missing.add('Country of Origin');
    if (harmonizedCode.isEmpty) missing.add('Harmonized Code');
    if (reasonForExport.isEmpty) missing.add('Reason for Export');
    return missing;
  }

  /// Get formatted value
  String get formattedValue => '${currency.toUpperCase()} ${value.toStringAsFixed(2)}';

  /// Get formatted weight
  String get formattedWeight => '${weightKg.toStringAsFixed(2)} kg';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'exporterName': exporterName,
      'exporterAddress': exporterAddress,
      'importerName': importerName,
      'importerAddress': importerAddress,
      'descriptionOfGoods': descriptionOfGoods,
      'value': value,
      'currency': currency,
      'weightKg': weightKg,
      'countryOfOrigin': countryOfOrigin,
      'harmonizedCode': harmonizedCode,
      'specialInstructions': specialInstructions,
      'isCommercialShipment': isCommercialShipment,
      'reasonForExport': reasonForExport,
      'additionalInformation': additionalInformation,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// Create from JSON
  factory InternationalShippingFormModel.fromJson(Map<String, dynamic> json) {
    return InternationalShippingFormModel(
      id: json['id'],
      orderId: json['orderId'],
      exporterName: json['exporterName'],
      exporterAddress: json['exporterAddress'],
      importerName: json['importerName'],
      importerAddress: json['importerAddress'],
      descriptionOfGoods: json['descriptionOfGoods'],
      value: json['value'].toDouble(),
      currency: json['currency'],
      weightKg: json['weightKg'].toDouble(),
      countryOfOrigin: json['countryOfOrigin'],
      harmonizedCode: json['harmonizedCode'],
      specialInstructions: List<String>.from(json['specialInstructions']),
      isCommercialShipment: json['isCommercialShipment'],
      reasonForExport: json['reasonForExport'],
      additionalInformation: Map<String, dynamic>.from(json['additionalInformation']),
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'],
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      orderId,
      exporterName,
      exporterAddress,
      importerName,
      importerAddress,
      descriptionOfGoods,
      value,
      currency,
      weightKg,
      countryOfOrigin,
      harmonizedCode,
      specialInstructions,
      isCommercialShipment,
      reasonForExport,
      additionalInformation,
      createdAt,
      status,
    ];
  }
}