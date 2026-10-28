import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

/// One action, one use case (definition-of-done.md). Pure Dart.
class GetItemsUseCase {
  /// Creates with the repository contract.
  const GetItemsUseCase(this._repository);

  final ItemRepository _repository;

  /// Executes the read.
  Future<Either<Failure, List<ItemEntity>>> call() => _repository.getItems();
}
