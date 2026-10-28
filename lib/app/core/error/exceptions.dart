/// Data-layer exceptions. These never escape the Data layer: repositories
/// catch them and map each to its own `Failure` (coding-style.md §9).
library;

/// Thrown when the server returns a structured error response.
class ServerException implements Exception {
  /// Creates with a message and optional status code / request id.
  const ServerException(
    this.message, {
    this.statusCode,
    this.requestId,
  });

  /// User-safe message from the error envelope.
  final String message;

  /// HTTP status code, when known.
  final int? statusCode;

  /// Correlation id from the error envelope, for support triage.
  final String? requestId;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when the request could not reach the server at all.
class NetworkException implements Exception {
  /// Creates with an optional custom message.
  const NetworkException([this.message = 'No internet connection']);

  /// Human-readable description.
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when local cache access fails.
class CacheException implements Exception {
  /// Creates with a reason.
  const CacheException([this.message = 'Cache failure']);

  /// Human-readable description.
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown on authentication problems (bad credentials, expired token).
class AuthException implements Exception {
  /// Creates with a reason.
  const AuthException([this.message = 'Authentication failed']);

  /// Human-readable description.
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Thrown when input validation fails in the data layer.
class ValidationException implements Exception {
  /// Creates with a reason and optional field-level details.
  const ValidationException(this.message, {this.field});

  /// Human-readable description.
  final String message;

  /// Offending field, when known.
  final String? field;

  @override
  String toString() => 'ValidationException: $message';
}
