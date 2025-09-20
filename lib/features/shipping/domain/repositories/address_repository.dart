import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../models/address_model.dart';
import '../models/address_validation_model.dart';

/// Abstract repository for address management operations
abstract class AddressRepository {
  /// Get all addresses for a user
  Future<Either<Failure, List<AddressModel>>> getAddresses(String userId);

  /// Get a specific address by ID
  Future<Either<Failure, AddressModel>> getAddressById(String addressId);

  /// Create a new address
  Future<Either<Failure, AddressModel>> createAddress(AddressModel address);

  /// Update an existing address
  Future<Either<Failure, AddressModel>> updateAddress(AddressModel address);

  /// Delete an address
  Future<Either<Failure, void>> deleteAddress(String addressId);

  /// Set address as default
  Future<Either<Failure, void>> setDefaultAddress(String addressId);

  /// Validate an address
  Future<Either<Failure, AddressValidationModel>> validateAddress(AddressModel address);

  /// Get address suggestions
  Future<Either<Failure, List<String>>> getAddressSuggestions(String partialAddress);

  /// Geocode address to get coordinates
  Future<Either<Failure, Map<String, double>>> geocodeAddress(AddressModel address);

  /// Reverse geocode coordinates to address
  Future<Either<Failure, AddressModel>> reverseGeocode(double latitude, double longitude);

  /// Get addresses within a radius
  Future<Either<Failure, List<AddressModel>>> getAddressesWithinRadius(
    double latitude,
    double longitude,
    double radiusKm,
  );

  /// Search addresses by query
  Future<Either<Failure, List<AddressModel>>> searchAddresses(String query);

  /// Get default address for user
  Future<Either<Failure, AddressModel?>> getDefaultAddress(String userId);
}