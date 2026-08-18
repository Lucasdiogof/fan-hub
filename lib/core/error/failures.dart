import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro ao carregar os dados. Tente novamente.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado. Tente novamente.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Verifique sua conexão com a internet.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
