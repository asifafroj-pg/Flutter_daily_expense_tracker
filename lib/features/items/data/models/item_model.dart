import '../../../../app/core/utils/data_parser.dart';
import '../../domain/entities/item_entity.dart';

/// Data-layer wire format. Extends the entity (definition-of-done.md
/// "Data"); every field goes through `safeParse<T>` so malformed JSON can
/// never crash a screen (coding-style.md §7).
class ItemModel extends ItemEntity {
  /// Creates a model with all fields explicit.
  const ItemModel({
    required super.id,
    required super.title,
    required super.description,
    required super.createdAt,
    super.done,
  });

  /// Builds from an untrusted JSON map.
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final fallback = DateTime.fromMillisecondsSinceEpoch(0);
    return ItemModel(
      id: safeParse<String>(json['id'], 'id') ??
          safeParse<int>(json['id'], 'id')?.toString() ??
          '',
      title: safeParse<String>(json['title'], 'title') ?? '',
      description: safeParse<String>(json['description'], 'description') ?? '',
      done: safeParse<bool>(json['done'], 'done', defaultValue: false)!,
      createdAt: parseDateTime(json['createdAt'], 'createdAt',
              defaultValue: fallback) ??
          fallback,
    );
  }

  /// Serialises back to JSON (cache payloads are JSON, not Dart objects —
  /// offline-optional.md §5).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Downcasts to the pure domain entity.
  ItemEntity toEntity() => ItemEntity(
        id: id,
        title: title,
        description: description,
        done: done,
        createdAt: createdAt,
      );
}
