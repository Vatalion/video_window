import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../models/shipping_method_model.dart';
import '../models/shipping_rate_model.dart';
import '../models/address_model.dart';

/// Abstract repository for shipping operations
abstract class ShippingRepository {
  /// Get all available shipping methods
  Future<Either<Failure, List<ShippingMethodModel>>> getShippingMethods();

  /// Get shipping method by ID
  Future<Either<Failure, ShippingMethodModel>> getShippingMethodById(String methodId);

  /// Calculate shipping rates for a shipment
  Future<Either<Failure, List<ShippingRateModel>>> calculateShippingRates({
    required AddressModel origin,
    required AddressModel destination,
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    double? declaredValue,
    String? currency,
  });

  /// Get shipping rate for a specific method
  Future<Either<Failure, ShippingRateModel>> calculateShippingRate({
    required String shippingMethodId,
    required AddressModel origin,
    required AddressModel destination,
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    double? declaredValue,
    String? currency,
  });

  /// Get available shipping methods for a route
  Future<Either<Failure, List<ShippingMethodModel>>> getAvailableShippingMethods({
    required AddressModel origin,
    required AddressModel destination,
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
  });

  /// Validate shipping requirements
  Future<Either<Failure, Map<String, dynamic>>> validateShippingRequirements({
    required AddressModel origin,
    required AddressModel destination,
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
  });

  /// Get shipping zones
  Future<Either<Failure, List<Map<String, dynamic>>>> getShippingZones();

  /// Get shipping restrictions
  Future<Either<Failure, List<Map<String, dynamic>>>> getShippingRestrictions({
    required String originCountry,
    required String destinationCountry,
  });

  /// Get estimated delivery time
  Future<Either<Failure, Map<String, dynamic>>> getEstimatedDeliveryTime({
    required String shippingMethodId,
    required AddressModel origin,
    required AddressModel destination,
  });

  /// Get shipping cost breakdown
  Future<Either<Failure, Map<String, dynamic>>> getShippingCostBreakdown({
    required String shippingMethodId,
    required AddressModel origin,
    required AddressModel destination,
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    double? declaredValue,
  });
}