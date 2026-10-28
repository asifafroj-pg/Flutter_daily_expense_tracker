import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../repositories/item_repository.dart';

/// Removes an item permanently.
class DeleteItemUseCase {
  /// Creates with the repository contract.
  const DeleteItemUseCase(this._repository);

  final ItemRepository _repository;

  /// Executes the delete by [id].
  Future<Either<Failure, void>> call(String id) => _repository.deleteItem(id);
}
