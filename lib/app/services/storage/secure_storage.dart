import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for token/session storage (security.md §3).
abstract class SecureStorage {
  /// Reads a value or returns `null` when unset.
  Future<String?> read(String key);

  /// Writes a value; pass `null` to delete the key.
  Future<void> write(String key, String? value);

  /// Removes every stored app secret (used on logout / 401).
  Future<void> clear();
}

/// Key for the bearer access token.
const String kAccessTokenKey = 'access_token';

/// Implementation backed by platform secure storage.
class SecureStorageImpl implements SecureStorage {
  /// Creates with an injectable [storage] for tests.
  SecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const List<String> _trackedKeys = [kAccessTokenKey];

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  @override
  Future<void> clear() async {
    for (final key in _trackedKeys) {
      await _storage.delete(key: key);
    }
  }
}
