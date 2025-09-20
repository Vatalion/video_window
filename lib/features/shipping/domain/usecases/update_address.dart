import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/address_repository.dart';
import '../models/address_model.dart';

/// Use case for updating an address
class UpdateAddress {
  final AddressRepository repository;

  UpdateAddress(this.repository);

  Future<Either<Failure, AddressModel>> call(AddressModel address) async {
    return await repository.updateAddress(address);
  }
}