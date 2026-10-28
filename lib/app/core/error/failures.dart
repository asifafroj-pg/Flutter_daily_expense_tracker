import 'package:equatable/equatable.dart';

/// Base type for every error the UI may receive. Blocs `fold`
/// `Either<Failure, T>` results onto these — never a raw exception.
abstract class Failure extends Equatable {
  /// Creates with a user-facing message.
  const Failure(this.message);

  /// User-facing, typed message (ui-design.md §6, realtime.md §7).
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The server responded with an error envelope.
class ServerFailure extends Failure {
  /// Creates from the envelope message plus optional status/request id.
  const ServerFailure(
    super.message, {
    this.statusCode,
    this.requestId,
  });

  /// HTTP status code, when known.
  final int? statusCode;

  /// Correlation id for support triage, when present.
  final String? requestId;

  @override
  List<Object?> get props => [message, statusCode, requestId];
}

/// The request could not reach the server (offline / timeout).
class NetworkFailure extends Failure {
  /// Creates with an optional custom message.
  const NetworkFailure([String? message])
      : super(message ?? 'No internet connection');
}

/// Local cache read/write failed.
class CacheFailure extends Failure {
  /// Creates with an optional custom message.
  const CacheFailure([String? message])
      : super(message ?? 'Could not read local data');
}

/// Authentication problem: bad credentials or expired session.
class AuthFailure extends Failure {
  /// Creates with an optional custom message.
  const AuthFailure([String? message])
      : super(message ?? 'Authentication failed');
}

/// Input rejected by validation.
class ValidationFailure extends Failure {
  /// Creates from a message and optional offending [field].
  const ValidationFailure(super.message, {this.field});

  /// Offending field, when known.
  final String? field;

  @override
  List<Object?> get props => [message, field];
}
