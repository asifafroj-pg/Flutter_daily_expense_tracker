import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';

/// Auth lifecycle status (bloc-conventions.md: explicit, few states).
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Immutable [AuthBloc] state. `Equatable` props only — no mutable fields.
class AuthState extends Equatable {
  /// Creates a state; default is the cold-start `unknown` state.
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserEntity? user;

  /// True while a login request is in flight (drives button disabled state —
  /// double-submit guard, performance-login.md §2).
  final bool isSubmitting;

  /// Last user-facing failure message, or `null`.
  final String? errorMessage;

  /// True when the form may be submitted (fields filled + not in flight).
  bool get canSubmitForm => !isSubmitting;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool clearUser = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}

/// App-scoped events (bloc-conventions.md §3): session changes live here.
sealed class AuthEvent {}

/// Fired once on cold start by the splash screen.
class AuthSessionRestoreRequested extends AuthEvent {}

/// Emitted internally after a successful login.
class AuthLoggedIn extends AuthEvent {
  AuthLoggedIn(this.user);

  final UserEntity user;
}

/// Emitted internally after a failed login / restore.
class AuthOperationFailed extends AuthEvent {
  AuthOperationFailed(this.message);

  final String message;
}

/// Fires when the user taps logout.
class AuthLogoutRequested extends AuthEvent {}

/// Owns the session for the whole app lifetime (registered as a GetIt
/// singleton, provided high in the widget tree).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Wires the bloc to its three use cases.
  AuthBloc({
    required RestoreSessionUseCase restoreSession,
    required LoginUseCase login,
    required LogoutUseCase logout,
  })  : _restoreSession = restoreSession,
        _login = login,
        _logout = logout,
        super(const AuthState()) {
    on<AuthSessionRestoreRequested>(_onRestore);
    on<AuthLoggedIn>((event, emit) => emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: event.user,
            isSubmitting: false,
            clearError: true,
          ),
        ));
    on<AuthOperationFailed>((event, emit) => emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: event.message,
          ),
        ));
    on<AuthLogoutRequested>(_onLogout);
  }

  final RestoreSessionUseCase _restoreSession;
  final LoginUseCase _login;
  final LogoutUseCase _logout;

  Future<void> _onRestore(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _restoreSession();
    result.fold(
      (failure) => add(AuthOperationFailed(failure.message)),
      (user) => emit(state.copyWith(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
      )),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      clearError: true,
    ));
  }

  /// Performs a login and promotes the session on success.
  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _login(LoginParams(email: email, password: password));
    await result.fold(
      (failure) async => add(AuthOperationFailed(failure.message)),
      (_) async {
        final restored = await _restoreSession();
        restored.fold(
          (failure) => add(AuthOperationFailed(failure.message)),
          (user) => add(AuthLoggedIn(user ?? UserEntity(id: email.trim().toLowerCase(), email: email.trim().toLowerCase()))),
        );
      },
    );
  }
}
