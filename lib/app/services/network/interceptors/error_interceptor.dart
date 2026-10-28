import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';

/// Parses the shared error envelope `{ success:false, code, message,
/// details?, requestId }` and throws the matching typed exception.
/// Never logs response bodies (coding-style.md §10).
Never throwServerException(DioException e) {
  final data = e.response?.data;
  String message = 'Something went wrong on our side';
  String? requestId;
  if (data is Map<String, dynamic>) {
    final rawMessage = data['message'];
    if (rawMessage is String && rawMessage.isNotEmpty) message = rawMessage;
    final rawRequestId = data['requestId'];
    if (rawRequestId is String) requestId = rawRequestId;
  }
  final status = e.response?.statusCode;
  if (status == 401 || status == 403) {
    throw AuthException(message);
  }
  throw ServerException(
    message,
    statusCode: status,
    requestId: requestId,
  );
}

/// Maps transport-level failures to [NetworkException]; anything else
/// becomes a [ServerException] with the parsed envelope.
class ErrorInterceptor extends Interceptor {
  /// Creates the interceptor.
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(err);
        throw const NetworkException('The request timed out');
      case DioExceptionType.connectionError:
        handler.reject(err);
        throw const NetworkException();
      case DioExceptionType.badCertificate:
        handler.reject(err);
        throw const ServerException('Insecure connection rejected');
      case DioExceptionType.cancel:
        handler.next(err);
        return;
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        handler.next(err);
        throwServerException(err);
    }
  }
}
