import '../../../../app/core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Ends the local session and wipes stored tokens.
class LogoutUseCase {
  /// Creates with the repository contract.
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the logout. Always succeeds.
  Future<void> call() => _repository.logout();
}
