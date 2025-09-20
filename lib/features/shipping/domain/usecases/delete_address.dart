import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/address_repository.dart';

/// Use case for deleting an address
class DeleteAddress {
  final AddressRepository repository;

  DeleteAddress(this.repository);

  Future<Either<Failure, void>> call(String addressId) async {
    return await repository.deleteAddress(addressId);
  }
}