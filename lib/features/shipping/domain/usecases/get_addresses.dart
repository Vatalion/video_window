import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/address_repository.dart';
import '../models/address_model.dart';

/// Use case for getting all addresses for a user
class GetAddresses {
  final AddressRepository repository;

  GetAddresses(this.repository);

  Future<Either<Failure, List<AddressModel>>> call(String userId) async {
    return await repository.getAddresses(userId);
  }
}