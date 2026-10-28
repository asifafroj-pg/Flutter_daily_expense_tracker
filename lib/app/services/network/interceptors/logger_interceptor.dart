import 'package:dio/dio.dart';

import '../../../../core/utils/app_logger.dart';

/// Logs method + URI only. Request and response bodies are NEVER logged
/// (coding-style.md §10, security.md §4).
class LoggerInterceptor extends Interceptor {
  /// Creates with the debug flag from [AppConfig.isDebug].
  LoggerInterceptor({required bool isDebug}) : _isDebug = isDebug;

  final bool _isDebug;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isDebug) AppLogger.debug('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_isDebug) {
      AppLogger.debug(
        '<-- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isDebug) {
      AppLogger.warn(
        '<-- ERR ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri}',
      );
    }
    handler.next(err);
  }
}
