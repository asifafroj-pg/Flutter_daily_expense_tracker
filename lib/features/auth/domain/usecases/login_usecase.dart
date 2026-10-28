import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Params for [LoginUseCase] (single typed params object, bloc-conventions.md).
class LoginParams {
  /// Creates validated inputs at the boundary.
  const LoginParams({required this.email, required this.password});

  /// Raw email input.
  final String email;

  /// Raw password input.
  final String password;
}

/// Authenticates the user and opens a session.
class LoginUseCase {
  /// Creates with the repository contract.
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the login.
  Future<Either<Failure, AuthTokens>> call(LoginParams params) =>
      _repository.login(email: params.email, password: params.password);
}
