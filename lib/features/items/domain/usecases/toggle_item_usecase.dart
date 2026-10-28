import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

/// Flips the `done` flag of an item.
class ToggleItemUseCase {
  /// Creates with the repository contract.
  const ToggleItemUseCase(this._repository);

  final ItemRepository _repository;

  /// Executes the toggle by [id].
  Future<Either<Failure, ItemEntity>> call(String id) =>
      _repository.toggleItem(id);
}
