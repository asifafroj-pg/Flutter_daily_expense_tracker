import 'package:dartz/dartz.dart';

import '../../../../app/core/constants/api_endpoints.dart';
import '../../../../app/core/data/data_source.dart';
import '../../../../app/core/error/exceptions.dart';
import '../../../../app/core/error/failures.dart';
import '../../../../app/services/network/dio_client.dart';
import '../models/item_model.dart';

/// REST implementation of the item backend (api-integration.md).
///
/// **Not wired by default** — the app ships offline-first. To enable it,
/// register this class instead of `ItemMemoryDataSource` in
/// `service_locator.dart` (or set `DATA_BACKEND=rest`). A future Supabase /
/// Firebase backend plugs in the same way: implement `DataSource<ItemModel>`.
class ItemRemoteDataSource implements DataSource<ItemModel> {
  /// Creates with the shared HTTP client.
  ItemRemoteDataSource({required DioClient client}) : _client = client;

  final DioClient _client;

  List<ItemModel> _decodeList(dynamic data) {
    final raw = data is List ? data : const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ItemModel.fromJson)
        .toList();
  }

  @override
  Future<Either<Failure, List<ItemModel>>> fetchAll() async {
    try {
      final response = await _client.get(ApiEndpoints.items);
      return Right(_decodeList(response['result'] ?? response['data']));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, ItemModel>> fetchById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.item(id));
      return Right(ItemModel.fromJson(response));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, ItemModel>> create(ItemModel data) =>
      _send(
        () => _client.post(ApiEndpoints.items, data: data.toJson()),
      );

  @override
  Future<Either<Failure, ItemModel>> update(ItemModel data) =>
      _send(
        () => _client.put(ApiEndpoints.item(data.id), data: data.toJson()),
      );

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.item(id));
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  Future<Either<Failure, ItemModel>> _send(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return Right(ItemModel.fromJson(response));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }
}
