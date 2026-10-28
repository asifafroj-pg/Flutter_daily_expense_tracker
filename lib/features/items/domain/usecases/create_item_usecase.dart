import 'package:dartz/dartz.dart';

import '../../../../app/core/error/failures.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

/// Params for [CreateItemUseCase].
class CreateItemParams {
  /// Creates with raw form input; trimming happens in the repository.
  const CreateItemParams({required this.title, required this.description});

  final String title;
  final String description;
}

/// Creates a new item through the active backend.
class CreateItemUseCase {
  /// Creates with the repository contract.
  const CreateItemUseCase(this._repository);

  final ItemRepository _repository;

  /// Executes the create.
  Future<Either<Failure, ItemEntity>> call(CreateItemParams params) =>
      _repository.createItem(title: params.title, description: params.description);
}
