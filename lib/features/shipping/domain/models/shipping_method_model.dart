import 'package:equatable/equatable.dart';

/// Shipping method model
class ShippingMethodModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String carrier;
  final String serviceType;
  final double baseCost;
  final double costPerKg;
  final double costPerKm;
  final int estimatedDeliveryDaysMin;
  final int estimatedDeliveryDaysMax;
  final bool isInternational;
  final bool requiresSignature;
  final bool includesInsurance;
  final double maxWeightKg;
  final double maxLengthCm;
  final double maxWidthCm;
  final double maxHeightCm;
  final List<String> supportedCountries;
  final Map<String, dynamic> restrictions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShippingMethodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.carrier,
    required this.serviceType,
    required this.baseCost,
    required this.costPerKg,
    required this.costPerKm,
    required this.estimatedDeliveryDaysMin,
    required this.estimatedDeliveryDaysMax,
    required this.isInternational,
    required this.requiresSignature,
    required this.includesInsurance,
    required this.maxWeightKg,
    required this.maxLengthCm,
    required this.maxWidthCm,
    required this.maxHeightCm,
    required this.supportedCountries,
    required this.restrictions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate shipping cost based on package details
  double calculateCost({
    required double weightKg,
    required double distanceKm,
    double? declaredValue,
    String? destinationCountry,
  }) {
    double totalCost = baseCost;

    // Add weight-based cost
    totalCost += weightKg * costPerKg;

    // Add distance-based cost
    totalCost += distanceKm * costPerKm;

    // Add international surcharge
    if (isInternational && destinationCountry != null && destinationCountry != 'US') {
      totalCost *= 1.5; // 50% surcharge for international
    }

    // Add insurance cost if required
    if (includesInsurance && declaredValue != null && declaredValue > 100) {
      totalCost += declaredValue * 0.01; // 1% insurance
    }

    return totalCost;
  }

  /// Check if package meets size and weight restrictions
  bool isValidPackage({
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    String? destinationCountry,
  }) {
    if (weightKg > maxWeightKg) return false;
    if (lengthCm > maxLengthCm) return false;
    if (widthCm > maxWidthCm) return false;
    if (heightCm > maxHeightCm) return false;

    if (isInternational && destinationCountry != null) {
      if (!supportedCountries.contains(destinationCountry)) return false;
    }

    return true;
  }

  /// Get delivery estimate as string
  String get deliveryEstimate {
    if (estimatedDeliveryDaysMin == estimatedDeliveryDaysMax) {
      return '$estimatedDeliveryDaysMin business days';
    } else {
      return '${estimatedDeliveryDaysMin}-${estimatedDeliveryDaysMax} business days';
    }
  }

  /// Get estimated delivery date range
  ({DateTime minDate, DateTime maxDate}) getEstimatedDeliveryDates(DateTime orderDate) {
    final minDate = _addBusinessDays(orderDate, estimatedDeliveryDaysMin);
    final maxDate = _addBusinessDays(orderDate, estimatedDeliveryDaysMax);
    return (minDate: minDate, maxDate: maxDate);
  }

  DateTime _addBusinessDays(DateTime date, int days) {
    var result = date;
    var remainingDays = days;

    while (remainingDays > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        remainingDays--;
      }
    }

    return result;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'carrier': carrier,
      'serviceType': serviceType,
      'baseCost': baseCost,
      'costPerKg': costPerKg,
      'costPerKm': costPerKm,
      'estimatedDeliveryDaysMin': estimatedDeliveryDaysMin,
      'estimatedDeliveryDaysMax': estimatedDeliveryDaysMax,
      'isInternational': isInternational,
      'requiresSignature': requiresSignature,
      'includesInsurance': includesInsurance,
      'maxWeightKg': maxWeightKg,
      'maxLengthCm': maxLengthCm,
      'maxWidthCm': maxWidthCm,
      'maxHeightCm': maxHeightCm,
      'supportedCountries': supportedCountries,
      'restrictions': restrictions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    return ShippingMethodModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      carrier: json['carrier'],
      serviceType: json['serviceType'],
      baseCost: json['baseCost'].toDouble(),
      costPerKg: json['costPerKg'].toDouble(),
      costPerKm: json['costPerKm'].toDouble(),
      estimatedDeliveryDaysMin: json['estimatedDeliveryDaysMin'],
      estimatedDeliveryDaysMax: json['estimatedDeliveryDaysMax'],
      isInternational: json['isInternational'],
      requiresSignature: json['requiresSignature'],
      includesInsurance: json['includesInsurance'],
      maxWeightKg: json['maxWeightKg'].toDouble(),
      maxLengthCm: json['maxLengthCm'].toDouble(),
      maxWidthCm: json['maxWidthCm'].toDouble(),
      maxHeightCm: json['maxHeightCm'].toDouble(),
      supportedCountries: List<String>.from(json['supportedCountries']),
      restrictions: Map<String, dynamic>.from(json['restrictions']),
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      name,
      description,
      carrier,
      serviceType,
      baseCost,
      costPerKg,
      costPerKm,
      estimatedDeliveryDaysMin,
      estimatedDeliveryDaysMax,
      isInternational,
      requiresSignature,
      includesInsurance,
      maxWeightKg,
      maxLengthCm,
      maxWidthCm,
      maxHeightCm,
      supportedCountries,
      isActive,
      createdAt,
      updatedAt,
    ];
  }
}