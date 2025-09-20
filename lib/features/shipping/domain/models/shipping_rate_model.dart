import 'package:equatable/equatable.dart';
import 'address_model.dart';
import 'shipping_method_model.dart';

/// Shipping rate calculation result
class ShippingRateModel extends Equatable {
  final String id;
  final ShippingMethodModel shippingMethod;
  final AddressModel origin;
  final AddressModel destination;
  final double weightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final double distanceKm;
  double baseCost;
  double taxAmount;
  double dutyAmount;
  double totalCost;
  final String currency;
  final DateTime estimatedDeliveryDate;
  final bool isAvailable;
  final List<String> warnings;
  final List<String> restrictions;
  final DateTime calculatedAt;

  const ShippingRateModel({
    required this.id,
    required this.shippingMethod,
    required this.origin,
    required this.destination,
    required this.weightKg,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.distanceKm,
    required this.baseCost,
    required this.taxAmount,
    required this.dutyAmount,
    required this.totalCost,
    required this.currency,
    required this.estimatedDeliveryDate,
    required this.isAvailable,
    required this.warnings,
    required this.restrictions,
    required this.calculatedAt,
  });

  /// Create a copy of this shipping rate with updated fields
  ShippingRateModel copyWith({
    String? id,
    ShippingMethodModel? shippingMethod,
    AddressModel? origin,
    AddressModel? destination,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? distanceKm,
    double? baseCost,
    double? taxAmount,
    double? dutyAmount,
    double? totalCost,
    String? currency,
    DateTime? estimatedDeliveryDate,
    bool? isAvailable,
    List<String>? warnings,
    List<String>? restrictions,
    DateTime? calculatedAt,
  }) {
    return ShippingRateModel(
      id: id ?? this.id,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      distanceKm: distanceKm ?? this.distanceKm,
      baseCost: baseCost ?? this.baseCost,
      taxAmount: taxAmount ?? this.taxAmount,
      dutyAmount: dutyAmount ?? this.dutyAmount,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      isAvailable: isAvailable ?? this.isAvailable,
      warnings: warnings ?? this.warnings,
      restrictions: restrictions ?? this.restrictions,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  /// Get formatted total cost
  String get formattedTotalCost {
    return '${currency.toUpperCase()} ${totalCost.toStringAsFixed(2)}';
  }

  /// Get formatted breakdown
  Map<String, String> get formattedBreakdown {
    return {
      'Base Cost': '${currency.toUpperCase()} ${baseCost.toStringAsFixed(2)}',
      'Tax': '${currency.toUpperCase()} ${taxAmount.toStringAsFixed(2)}',
      'Duty': '${currency.toUpperCase()} ${dutyAmount.toStringAsFixed(2)}',
      'Total': formattedTotalCost,
    };
  }

  /// Check if this is an international shipment
  bool get isInternational => origin.country != destination.country;

  /// Get delivery status
  String get deliveryStatus {
    if (!isAvailable) return 'Not Available';
    if (warnings.isNotEmpty) return 'Available with Warnings';
    return 'Available';
  }

  /// Get delivery urgency level
  String get urgencyLevel {
    final daysUntilDelivery = estimatedDeliveryDate.difference(DateTime.now()).inDays;
    if (daysUntilDelivery <= 1) return 'Express';
    if (daysUntilDelivery <= 3) return 'Standard';
    return 'Economy';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shippingMethod': shippingMethod.toJson(),
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'weightKg': weightKg,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'distanceKm': distanceKm,
      'baseCost': baseCost,
      'taxAmount': taxAmount,
      'dutyAmount': dutyAmount,
      'totalCost': totalCost,
      'currency': currency,
      'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
      'isAvailable': isAvailable,
      'warnings': warnings,
      'restrictions': restrictions,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ShippingRateModel.fromJson(Map<String, dynamic> json) {
    return ShippingRateModel(
      id: json['id'],
      shippingMethod: ShippingMethodModel.fromJson(json['shippingMethod']),
      origin: AddressModel.fromJson(json['origin']),
      destination: AddressModel.fromJson(json['destination']),
      weightKg: json['weightKg'].toDouble(),
      lengthCm: json['lengthCm'].toDouble(),
      widthCm: json['widthCm'].toDouble(),
      heightCm: json['heightCm'].toDouble(),
      distanceKm: json['distanceKm'].toDouble(),
      baseCost: json['baseCost'].toDouble(),
      taxAmount: json['taxAmount'].toDouble(),
      dutyAmount: json['dutyAmount'].toDouble(),
      totalCost: json['totalCost'].toDouble(),
      currency: json['currency'],
      estimatedDeliveryDate: DateTime.parse(json['estimatedDeliveryDate']),
      isAvailable: json['isAvailable'],
      warnings: List<String>.from(json['warnings']),
      restrictions: List<String>.from(json['restrictions']),
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      shippingMethod,
      origin,
      destination,
      weightKg,
      lengthCm,
      widthCm,
      heightCm,
      distanceKm,
      baseCost,
      taxAmount,
      dutyAmount,
      totalCost,
      currency,
      estimatedDeliveryDate,
      isAvailable,
      warnings,
      restrictions,
      calculatedAt,
    ];
  }
}