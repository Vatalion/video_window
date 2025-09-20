import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/address_repository.dart';
import '../models/address_model.dart';

/// Use case for creating a new address
class CreateAddress {
  final AddressRepository repository;

  CreateAddress(this.repository);

  Future<Either<Failure, AddressModel>> call(AddressModel address) async {
    return await repository.createAddress(address);
  }
}