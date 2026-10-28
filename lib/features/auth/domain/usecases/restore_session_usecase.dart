import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Restores a persisted session on cold start (splash screen).
class RestoreSessionUseCase {
  /// Creates with the repository contract.
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the cached user, or `null` when signed out.
  Future<Either<Failure, UserEntity?>> call() => _repository.restoreSession();
}
