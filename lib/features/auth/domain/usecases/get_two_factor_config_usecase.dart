import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';
import '../models/two_factor_config_model.dart';

class GetTwoFactorConfigUseCase {
  final TwoFactorRepository repository;

  GetTwoFactorConfigUseCase(this.repository);

  Future<Either<Failure, TwoFactorConfig>> call(String userId) async {
    return await repository.getTwoFactorConfig(userId);
  }
}
