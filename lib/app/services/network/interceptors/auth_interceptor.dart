import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../storage/secure_storage.dart';

/// Callback invoked when the server rejects our token (401): the session is
/// cleared and the router redirect takes the user to login (navigation.md §8).
typedef UnauthorizedCallback = Future<void> Function();

/// Injects `Authorization: Bearer <token>` and reacts to 401 by clearing
/// auth state (architecture.md §7).
class AuthInterceptor extends Interceptor {
  /// Creates with secure storage and an [onUnauthorized] hook.
  AuthInterceptor({
    required SecureStorage storage,
    required UnauthorizedCallback onUnauthorized,
  })  : _storage = storage,
        _onUnauthorized = onUnauthorized;

  final SecureStorage _storage;
  final UnauthorizedCallback _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(kAccessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.clear();
      unawaited(_onUnauthorized());
    }
    handler.next(err);
  }
}
