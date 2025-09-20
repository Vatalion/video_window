import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';

class GenerateBackupCodesUseCase {
  final TwoFactorRepository repository;

  GenerateBackupCodesUseCase(this.repository);

  Future<Either<Failure, List<String>>> call(String userId) async {
    return await repository.generateBackupCodes(userId);
  }
}
