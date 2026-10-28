import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/item_entity.dart';

/// Repository contract — abstract, pure Dart (definition-of-done.md).
/// The Presentation/Domain layers never know whether the backend is the
/// offline memory store, REST, Supabase or Firebase.
abstract class ItemRepository {
  /// Returns all items, newest mutation order preserved by the backend.
  Future<Either<Failure, List<ItemEntity>>> getItems();

  /// Returns one item by [id].
  Future<Either<Failure, ItemEntity>> getItem(String id);

  /// Creates an item; returns the stored copy.
  Future<Either<Failure, ItemEntity>> createItem({
    required String title,
    required String description,
  });

  /// Toggles the `done` flag of [id] (optimistic-friendly mutation).
  Future<Either<Failure, ItemEntity>> toggleItem(String id);

  /// Deletes the item with [id].
  Future<Either<Failure, void>> deleteItem(String id);
}
