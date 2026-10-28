import 'package:dartz/dartz.dart';

import '../../../../app/core/data/data_source.dart';
import '../../../../app/core/error/failures.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';
import '../models/item_model.dart';

/// Single repository implementation over the backend-agnostic
/// `DataSource<ItemModel>` seam (architecture.md §2: Data is the only layer
/// that touches storage). Offline memory / REST / Supabase / Firebase are
/// interchangeable — chosen once in `service_locator`.
class ItemRepositoryImpl implements ItemRepository {
  /// Creates with the active backend.
  ItemRepositoryImpl({required DataSource<ItemModel> source})
      : _source = source;

  final DataSource<ItemModel> _source;

  static List<ItemEntity> _toEntities(List<ItemModel> models) =>
      models.map((m) => m.toEntity()).toList();

  @override
  Future<Either<Failure, List<ItemEntity>>> getItems() async {
    final result = await _source.fetchAll();
    return result.fold((f) => Left(f), (m) => Right(_toEntities(m)));
  }

  @override
  Future<Either<Failure, ItemEntity>> getItem(String id) async {
    final result = await _source.fetchById(id);
    return result.fold((f) => Left(f), (m) => Right(m.toEntity()));
  }

  @override
  Future<Either<Failure, ItemEntity>> createItem({
    required String title,
    required String description,
  }) async {
    if (title.trim().isEmpty) {
      return const Left(ValidationFailure('Title is required', field: 'title'));
    }
    final model = ItemModel(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    final result = await _source.create(model);
    return result.fold((f) => Left(f), (m) => Right(m.toEntity()));
  }

  @override
  Future<Either<Failure, ItemEntity>> toggleItem(String id) async {
    final current = await _source.fetchById(id);
    final model = await current.fold(
      (f) async => null,
      (m) async => m,
    );
    if (model == null) {
      return Left(
        current.fold((f) => f, (_) => const CacheFailure('Item not found')),
      );
    }
    final toggled = ItemModel(
      id: model.id,
      title: model.title,
      description: model.description,
      done: !model.done,
      createdAt: model.createdAt,
    );
    final saved = await _source.update(toggled);
    return saved.fold((f) => Left(f), (m) => Right(m.toEntity()));
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) => _source.delete(id);
}
