import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

/// Reads a single item for the detail screen.
class GetItemDetailUseCase {
  /// Creates with the repository contract.
  const GetItemDetailUseCase(this._repository);

  final ItemRepository _repository;

  /// Executes the read by [id].
  Future<Either<Failure, ItemEntity>> call(String id) =>
      _repository.getItem(id);
}
