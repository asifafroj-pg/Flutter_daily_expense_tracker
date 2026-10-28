import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logger_interceptor.dart';

/// The single HTTP client wrapper (architecture.md: Data is the only layer
/// that touches Dio). Returns decoded JSON maps/lists; throws typed
/// exceptions which repositories map to `Failure`s.
class DioClient {
  /// Builds the client and installs auth, logger and error interceptors.
  ///
  /// Pass a pre-configured [dio] (e.g. with a `DioAdapter`) in tests.
  DioClient({
    required AppConfig config,
    required SecureStorage storage,
    required UnauthorizedCallback onUnauthorized,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: config.apiBaseUrl,
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.requestTimeout,
              responseType: ResponseType.json,
              headers: <String, dynamic>{'Accept': 'application/json'},
            )) {
    _dio.interceptors.addAll([
      AuthInterceptor(storage: storage, onUnauthorized: onUnauthorized),
      LoggerInterceptor(isDebug: config.isDebug),
      const ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  /// Exposes the underlying client for advanced use (still inside Data).
  Dio get raw => _dio;

  /// GET [path]; returns the decoded JSON map.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _asMap(await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      ));

  /// POST [path] with optional [data]; returns the decoded JSON map.
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _asMap(await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ));

  /// PUT [path] with optional [data]; returns the decoded JSON map.
  Future<Map<String, dynamic>> put(String path, {Object? data}) =>
      _asMap(await _dio.put<dynamic>(path, data: data));

  /// DELETE [path]; returns the decoded JSON map.
  Future<Map<String, dynamic>> delete(String path) =>
      _asMap(await _dio.delete<dynamic>(path));

  Map<String, dynamic> _asMap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{'result': data};
  }
}
