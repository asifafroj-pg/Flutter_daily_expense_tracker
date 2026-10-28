import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

/// Screen-scoped login state (bloc-conventions.md §3 — feature blocs stay on
/// the screen; only session changes go to `AuthBloc`).
class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.user,
  });

  final String email;
  final String password;
  final bool isSubmitting;
  final String? errorMessage;

  /// Set once credentials succeed; the screen forwards this to `AuthBloc`.
  final UserEntity? user;

  bool get canSubmit =>
      email.trim().isNotEmpty && password.isNotEmpty && !isSubmitting;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    UserEntity? user,
  }) =>
      LoginState(
        email: email ?? this.email,
        password: password ?? this.password,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        user: user ?? this.user,
      );

  @override
  List<Object?> get props => [email, password, isSubmitting, errorMessage, user];
}

sealed class LoginEvent {}

class EmailChanged extends LoginEvent {
  EmailChanged(this.value);

  final String value;
}

class PasswordChanged extends LoginEvent {
  PasswordChanged(this.value);

  final String value;
}

class LoginSubmitted extends LoginEvent {}

/// Validates input locally, then delegates credential checks to [LoginUseCase].
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required LoginUseCase login}) : _login = login, super(const LoginState()) {
    on<EmailChanged>((e, emit) => emit(state.copyWith(email: e.value, clearError: true)));
    on<PasswordChanged>((e, emit) => emit(state.copyWith(password: e.value, clearError: true)));
    on<LoginSubmitted>(_onSubmit);
  }

  final LoginUseCase _login;

  Future<void> _onSubmit(LoginEvent event, Emitter<LoginState> emit) async {
    if (state.isSubmitting) return; // double-submit guard (performance-login.md §2)
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _login(
      LoginParams(email: state.email, password: state.password),
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(isSubmitting: false, errorMessage: failure.message),
      ),
      (tokens) async => emit(
        state.copyWith(
          isSubmitting: false,
          user: UserEntity(id: state.email.trim().toLowerCase(), email: state.email.trim().toLowerCase()),
        ),
      ),
    );
  }
}
