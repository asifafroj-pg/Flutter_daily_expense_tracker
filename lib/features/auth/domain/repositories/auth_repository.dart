import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/auth_tokens.dart';
import '../entities/user_entity.dart';

/// Auth contract consumed by use cases (Domain ← Data dependency rule).
abstract class AuthRepository {
  /// Authenticates with [email]/[password]. Offline providers accept any
  /// syntactically valid credentials and create a local session.
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  });

  /// Restores a persisted session, if any.
  Future<Either<Failure, UserEntity?>> restoreSession();

  /// Clears the stored session. Always succeeds.
  Future<void> logout();
}
