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

/// Sign-out involuntário — a sessão não pôde ser renovada (refresh token
/// inválido/revogado). Trata como não-autenticado pra tudo que já checa
/// `is AuthAuthenticated` (o redirect do router não precisa saber a
/// diferença), mas é um estado distinto pra UI decidir mostrar o aviso
/// "sua sessão expirou" só nesse caso, nunca depois de um logout comum.
class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}

class AuthPasswordRecovery extends AuthState {
  const AuthPasswordRecovery();
}
