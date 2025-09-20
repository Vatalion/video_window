import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';
import '../models/two_factor_config_model.dart';

class EnableTotpTwoFactorUseCase {
  final TwoFactorRepository repository;

  EnableTotpTwoFactorUseCase(this.repository);

  Future<Either<Failure, TwoFactorConfig>> call({
    required String userId,
    required String totpSecret,
  }) async {
    return await repository.enableTotpTwoFactor(userId, totpSecret);
  }
}
