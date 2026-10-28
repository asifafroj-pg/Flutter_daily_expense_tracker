import 'package:equatable/equatable.dart';

/// Session tokens returned by any future backend (REST / Supabase / Firebase).
///
/// The offline `memory` provider never issues real tokens; it stores an opaque
/// local session marker instead.
class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  @override
  List<Object?> get props => <Object?>[accessToken, refreshToken];
}
