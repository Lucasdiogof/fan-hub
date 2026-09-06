import 'package:equatable/equatable.dart';
import 'package:goias_app/core/error/auth_error_code.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = '']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = '']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Verifique sua conexão com a internet.',
  ]);
}

/// Carrega um [code] estável em vez de uma string final — a tradução mora
/// na camada de apresentação (ver
/// `lib/features/auth/presentation/auth_error_localization.dart`), já que
/// a camada de dados/repositório não tem acesso a `BuildContext`/
/// `AppLocalizations`. [rawMessage] só é usado com
/// `AuthErrorCode.functionError` (texto dinâmico vindo do backend, nunca
/// traduzido em runtime — mesma convenção do resto do app pra conteúdo de
/// backend). `message` (herdado de [Failure]) fica só como identificador
/// pra Sentry/debug/Equatable, nunca exibido diretamente pro usuário.
class AuthFailure extends Failure {
  const AuthFailure(this.code, {this.rawMessage}) : super(rawMessage ?? '');

  final AuthErrorCode code;
  final String? rawMessage;

  @override
  List<Object?> get props => [code, rawMessage];
}
