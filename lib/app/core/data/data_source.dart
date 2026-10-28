import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Backend-agnostic read/write contract (architecture.md §2).
///
/// The app is **offline-first by default**: the built-in implementation is
/// `MemoryDataSource` (in-memory + persisted JSON on device). A REST /
/// Supabase / Firebase backend only has to satisfy this one contract —
/// nothing else in the app changes. Switch backends in `service_locator`.
abstract class DataSource<T extends Object> {
  /// Returns every record, or a typed [Failure].
  Future<Either<Failure, List<T>>> fetchAll();

  /// Returns one record by identity, or a typed [Failure].
  Future<Either<Failure, T>> fetchById(String id);

  /// Creates a record; returns the stored copy, or a typed [Failure].
  Future<Either<Failure, T>> create(T data);

  /// Replaces an existing record, or a typed [Failure].
  Future<Either<Failure, T>> update(T data);

  /// Deletes the record with [id], or a typed [Failure].
  Future<Either<Failure, void>> delete(String id);
}
