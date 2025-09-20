import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';
import '../models/two_factor_config_model.dart';

class EnableSmsTwoFactorUseCase {
  final TwoFactorRepository repository;

  EnableSmsTwoFactorUseCase(this.repository);

  Future<Either<Failure, TwoFactorConfig>> call({
    required String userId,
    required String phoneNumber,
  }) async {
    return await repository.enableSmsTwoFactor(userId, phoneNumber);
  }
}
