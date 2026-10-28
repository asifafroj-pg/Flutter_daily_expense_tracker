import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_key_value_store.dart';

/// File-backed [LocalKeyValueStore]: one JSON file per key inside the
/// application-support directory. Fully offline; no plugins in the UI path.
class FileKeyValueStore implements LocalKeyValueStore {
  /// Creates the store; the directory resolves lazily on first use.
  FileKeyValueStore();

  Directory? _dir;

  Future<Directory> _root() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/app_base_store');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  File _fileFor(String key) => File('${_dir!.path}/$key.json');

  @override
  Future<String?> read(String key) async {
    try {
      await _root();
      final file = _fileFor(key);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String key, String? value) async {
    await _root();
    final file = _fileFor(key);
    if (value == null) {
      if (await file.exists()) await file.delete();
    } else {
      await file.writeAsString(value);
    }
  }

  @override
  Future<void> clear() async {
    final root = await _root();
    if (await root.exists()) {
      await root.delete(recursive: true);
      await root.create(recursive: true);
    }
  }
}
