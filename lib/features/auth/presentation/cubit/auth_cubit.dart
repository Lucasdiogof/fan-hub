import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    _emitFromSession();
    _subscription = _repository.sessionEvents.listen(_onEvent);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthSessionEvent> _subscription;

  void _emitFromSession() {
    final user = _repository.currentUser;
    emit(user != null ? AuthAuthenticated(user) : const AuthUnauthenticated());
  }

  void _onEvent(AuthSessionEvent event) {
    switch (event) {
      case AuthSessionEvent.signedIn:
      case AuthSessionEvent.userUpdated:
        final user = _repository.currentUser;
        if (user != null) emit(AuthAuthenticated(user));
      case AuthSessionEvent.signedOut:
        emit(const AuthUnauthenticated());
      case AuthSessionEvent.sessionExpired:
        emit(const AuthSessionExpired());
      case AuthSessionEvent.passwordRecovery:
        emit(const AuthPasswordRecovery());
    }
  }

  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }

  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) {
    return _repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
      cpf: cpf,
      birthDate: birthDate,
      phone: phone,
      marketingOptIn: marketingOptIn,
    );
  }

  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) => _repository.verifyEmailOtp(email: email, token: token);

  Future<Result<bool>> isCpfTaken(String cpf) => _repository.isCpfTaken(cpf);

  Future<Result<void>> sendPasswordReset(String email) =>
      _repository.sendPasswordReset(email);

  Future<Result<void>> resendConfirmation(String email) =>
      _repository.resendConfirmationEmail(email);

  Future<Result<void>> updatePassword(String newPassword) =>
      _repository.updatePassword(newPassword);

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  Future<Result<void>> deleteAccount({required String password}) =>
      _repository.deleteAccount(password: password);

  Future<void> signOut() => _repository.signOut();

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
