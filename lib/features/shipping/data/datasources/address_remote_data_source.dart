import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../models/address_model.dart';
import '../models/address_validation_model.dart';

/// Remote data source for address operations
abstract class AddressRemoteDataSource {
  /// Fetch addresses from remote server
  Future<List<AddressModel>> getAddresses(String userId);

  /// Get address by ID from remote server
  Future<AddressModel> getAddressById(String addressId);

  /// Create address on remote server
  Future<AddressModel> createAddress(AddressModel address);

  /// Update address on remote server
  Future<AddressModel> updateAddress(AddressModel address);

  /// Delete address from remote server
  Future<void> deleteAddress(String addressId);

  /// Set default address on remote server
  Future<void> setDefaultAddress(String addressId);

  /// Validate address using remote service
  Future<AddressValidationModel> validateAddress(AddressModel address);

  /// Get address suggestions from remote service
  Future<List<String>> getAddressSuggestions(String partialAddress);

  /// Geocode address using remote service
  Future<Map<String, double>> geocodeAddress(AddressModel address);

  /// Reverse geocode coordinates using remote service
  Future<AddressModel> reverseGeocode(double latitude, double longitude);

  /// Search addresses using remote service
  Future<List<AddressModel>> searchAddresses(String query);
}

/// Implementation of address remote data source
class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final http.Client client;

  AddressRemoteDataSourceImpl({required this.client});

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.baseUrl}/addresses?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['addresses'];
        return data.map((json) => AddressModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to get addresses: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> getAddressById(String addressId) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.baseUrl}/addresses/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AddressModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to get address: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> createAddress(AddressModel address) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.baseUrl}/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
        body: json.encode(address.toJson()),
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AddressModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to create address: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    try {
      final response = await client.put(
        Uri.parse('${AppConstants.baseUrl}/addresses/${address.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
        body: json.encode(address.toJson()),
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AddressModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to update address: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    try {
      final response = await client.delete(
        Uri.parse('${AppConstants.baseUrl}/addresses/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete address: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final response = await client.patch(
        Uri.parse('${AppConstants.baseUrl}/addresses/$addressId/default'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to set default address: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<AddressValidationModel> validateAddress(AddressModel address) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.baseUrl}/addresses/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
        body: json.encode(address.toJson()),
      ).timeout(Duration(seconds: AppConstants.addressValidationTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AddressValidationModel.fromJson(data);
      } else {
        throw AddressValidationException(
          message: 'Address validation failed: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw AddressValidationException(message: 'Validation error: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getAddressSuggestions(String partialAddress) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.baseUrl}/addresses/suggestions?q=$partialAddress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.addressValidationTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions']);
      } else {
        throw ServerException(
          message: 'Failed to get suggestions: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, double>> geocodeAddress(AddressModel address) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.baseUrl}/addresses/geocode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
        body: json.encode(address.toJson()),
      ).timeout(Duration(seconds: AppConstants.addressValidationTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'latitude': data['latitude'].toDouble(),
          'longitude': data['longitude'].toDouble(),
        };
      } else {
        throw ServerException(
          message: 'Failed to geocode address: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.baseUrl}/addresses/reverse-geocode?lat=$latitude&lng=$longitude'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.addressValidationTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AddressModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to reverse geocode: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<AddressModel>> searchAddresses(String query) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.baseUrl}/addresses/search?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiVersion}',
        },
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['addresses'];
        return data.map((json) => AddressModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to search addresses: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}