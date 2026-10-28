import 'package:dartz/dartz.dart';

import '../../../../app/core/error/exceptions.dart';
import '../../../../app/core/error/failures.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source_impl.dart';
import '../models/user_model.dart';

/// Auth contract for any provider. The app ships the offline [LocalAuthProvider]
/// by default; REST / Supabase / Firebase only need to implement this one
/// interface (offline-optional.md — swap in `service_locator`, nothing else).
abstract class AuthProvider {
  /// Verifies credentials and returns session tokens, or throws typed
  /// data-layer exceptions (`AuthException`, `NetworkException`).
  Future<({AuthTokens tokens, UserModel user})> signIn({
    required String email,
    required String password,
  });
}

/// Offline-first auth: accepts any syntactically valid credentials, creates a
/// local session, works with zero connectivity.
class LocalAuthProvider implements AuthProvider {
  const LocalAuthProvider();

  @override
  Future<({AuthTokens tokens, UserModel user})> signIn({
    required String email,
    required String password,
  }) async {
    // Demo rule for the offline build: reject a well-known wrong password so
    // the error path is exercised without a backend.
    if (password == 'wrongpass') {
      throw const AuthException('Incorrect email or password');
    }
    final normalized = email.trim().toLowerCase();
    final name = normalized.split('@').first;
    return (
      tokens: AuthTokens(accessToken: 'local-${DateTime.now().millisecondsSinceEpoch}'),
      user: UserModel(id: normalized, email: normalized, name: name),
    );
  }
}

/// Maps provider/local failures to typed `Failure`s and persists sessions in
/// secure storage. Exceptions never escape this layer (coding-style.md §9).
class AuthRepositoryImpl implements AuthRepository {
  /// Creates with the active provider + local session cache.
  AuthRepositoryImpl({required AuthProvider provider, required AuthLocalDataSource local})
      : _provider = provider,
        _local = local;

  final AuthProvider _provider;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _provider.signIn(email: email, password: password);
      await _local.cacheSession(tokens: result.tokens, user: result.user);
      return Right(result.tokens);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> restoreSession() async {
    try {
      if (!await _local.hasSession()) return const Right(null);
      final user = await _local.readCachedUser();
      if (user == null) {
        await _local.clearSession();
        return const Right(null);
      }
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<void> logout() => _local.clearSession();
}
