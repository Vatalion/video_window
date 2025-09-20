import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/address_repository.dart';
import '../models/address_model.dart';
import '../models/address_validation_model.dart';

/// Use case for validating an address
class ValidateAddress {
  final AddressRepository repository;

  ValidateAddress(this.repository);

  Future<Either<Failure, AddressValidationModel>> call(AddressModel address) async {
    return await repository.validateAddress(address);
  }
}