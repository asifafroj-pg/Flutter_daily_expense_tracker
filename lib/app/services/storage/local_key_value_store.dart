
/// Generic on-device key/value persistence contract.
///
/// The default implementation is file-based (works offline, no plugins in
/// the hot path). Swap for Hive/Isar/SQLite by registering another
/// implementation in `service_locator` — callers never change.
abstract class LocalKeyValueStore {
  /// Reads a JSON string or returns `null` when unset.
  Future<String?> read(String key);

  /// Writes a JSON string; pass `null` to delete [key].
  Future<void> write(String key, String? value);

  /// Removes every stored key owned by this app.
  Future<void> clear();
}

/// In-memory implementation (also used as the fallback when the filesystem
/// is unavailable, e.g. widget tests without path_provider mocks).
class MemoryKeyValueStore implements LocalKeyValueStore {
  /// Creates with optional seed values (useful in tests).
  MemoryKeyValueStore([Map<String, String>? seed])
      : _data = <String, String>{...?seed};

  final Map<String, String> _data;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> clear() async => _data.clear();
}
