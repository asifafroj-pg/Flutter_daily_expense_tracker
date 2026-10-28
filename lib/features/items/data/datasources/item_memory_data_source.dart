import 'dart:convert';

import '../../../core/data/data_source.dart';
import '../../../core/error/failures.dart';
import '../../../services/storage/local_key_value_store.dart';
import '../models/item_model.dart';

/// Offline-first default backend for [ItemModel] (the user's requirement:
/// "totally offline based, but keep the option for REST/Supabase/Firebase").
///
/// Data lives in memory and is persisted as JSON through [LocalKeyValueStore]
/// (offline-optional.md §5: cache JSON-decoded payloads, never raw objects).
class ItemMemoryDataSource implements DataSource<ItemModel> {
  /// Creates with the persistence seam.
  ItemMemoryDataSource({required LocalKeyValueStore store}) : _store = store;

  /// Storage key for the whole collection.
  static const String storageKey = 'items_v1';

  final LocalKeyValueStore _store;
  List<ItemModel>? _cache;

  Future<List<ItemModel>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await _store.read(storageKey);
    final items = <ItemModel>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded.whereType<Map<String, dynamic>>()) {
            items.add(ItemModel.fromJson(entry));
          }
        }
      } on FormatException {
        // Corrupt local data: start clean rather than crash (fail-safe).
        await _store.write(storageKey, null);
      }
    }
    return _cache = items;
  }

  Future<Either<Failure, void>> _save(List<ItemModel> items) async {
    _cache = items;
    try {
      await _store.write(
        storageKey,
        jsonEncode(items.map((m) => m.toJson()).toList()),
      );
      return const Right(null);
    } catch (_) {
      return const CacheFailure('Could not save local data');
    }
  }

  @override
  Future<Either<Failure, List<ItemModel>>> fetchAll() async {
    final items = await _load();
    final sorted = [...items]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Right(sorted);
  }

  @override
  Future<Either<Failure, ItemModel>> fetchById(String id) async {
    final items = await _load();
    for (final item in items) {
      if (item.id == id) return Right(item);
    }
    return const Left(ServerFailure('Item not found', statusCode: 404));
  }

  @override
  Future<Either<Failure, ItemModel>> create(ItemModel data) async {
    final items = await _load();
    await _save([...items, data]);
    return Right(data);
  }

  @override
  Future<Either<Failure, ItemModel>> update(ItemModel data) async {
    final items = await _load();
    final exists = items.any((m) => m.id == data.id);
    if (!exists) {
      return const Left(ServerFailure('Item not found', statusCode: 404));
    }
    await _save([
      for (final m in items) m.id == data.id ? data : m,
    ]);
    return Right(data);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    final items = await _load();
    final result = await _save(items.where((m) => m.id != id).toList());
    return result.fold((f) => Left(f), (_) => const Right(null));
  }
}
