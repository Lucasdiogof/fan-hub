import 'package:equatable/equatable.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPasswordRecovery extends AuthState {
  const AuthPasswordRecovery();
}
