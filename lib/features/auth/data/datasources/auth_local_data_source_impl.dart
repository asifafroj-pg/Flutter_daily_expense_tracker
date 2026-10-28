import 'dart:convert';

import '../../../../app/services/storage/secure_storage.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// Persists the session through [SecureStorage] — tokens are NEVER kept in
/// plain key/value storage (security.md §2). The user profile is cached as
/// JSON (offline-optional.md §5), and a corrupt cache degrades to `null`
/// instead of crashing.
abstract class AuthLocalDataSource {
  /// Stores tokens + user for an active session.
  Future<void> cacheSession({
    required AuthTokens tokens,
    required UserModel user,
  });

  /// Reads the cached user, or `null` when absent/corrupt.
  Future<UserModel?> readCachedUser();

  /// Whether a session token exists locally.
  Future<bool> hasSession();

  /// Removes every trace of the session.
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// Creates with the secure-storage seam.
  AuthLocalDataSourceImpl(this._storage);

  final SecureStorage _storage;

  static const String _userKey = 'auth.user';

  @override
  Future<void> cacheSession({
    required AuthTokens tokens,
    required UserModel user,
  }) async {
    await _storage.write(kAccessTokenKey, tokens.accessToken);
    await _storage.write('refresh_token', tokens.refreshToken);
    await _storage.write(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> readCachedUser() async {
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserModel.fromJson(decoded);
    } on FormatException {
      return null; // fail-safe: treat corrupt cache as signed out
    }
  }

  @override
  Future<bool> hasSession() async =>
      (await _storage.read(kAccessTokenKey)) != null;

  @override
  Future<void> clearSession() async {
    await _storage.write(kAccessTokenKey, null);
    await _storage.write('refresh_token', null);
    await _storage.write(_userKey, null);
  }
}

/// Maps a domain user to its data model (used by offline providers).
UserModel userModelFrom(UserEntity user) =>
    UserModel(id: user.id, email: user.email, name: user.name);
