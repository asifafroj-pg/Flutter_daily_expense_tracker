import 'package:equatable/equatable.dart';

/// Pure domain object for a list item. Immutable, `Equatable`, no raw
/// `Map` and no Flutter imports (definition-of-done.md "Domain").
class ItemEntity extends Equatable {
  /// Creates an entity with all fields explicit.
  const ItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.done = false,
  });

  /// Stable identity used by routes (`AppPages.itemDetail(id)`).
  final String id;

  /// Display title.
  final String title;

  /// Long-form body text.
  final String description;

  /// Whether the item is completed.
  final bool done;

  /// Creation timestamp (freshness display).
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, description, done, createdAt];
}
