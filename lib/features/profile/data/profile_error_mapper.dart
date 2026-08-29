import 'package:goias_app/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [isWrite] escolhe a mensagem certa pro tipo de operação — uma falha
/// LENDO o perfil não pode dizer "não foi possível salvar" (aconteceu de
/// verdade: `getProfile` reaproveitava a mesma mensagem de escrita e a
/// aba Sócio mostrava "não foi possível salvar seus dados" pra uma
/// simples falha de carregamento, confundindo o usuário sobre o que
/// realmente deu errado).
Failure mapProfileError(Object error, {bool isWrite = true}) {
  final name = error.runtimeType.toString();
  if (name.contains('SocketException') ||
      name.contains('ClientException') ||
      name.contains('TimeoutException')) {
    return const NetworkFailure();
  }
  if (error is PostgrestException || error is StorageException) {
    return ServerFailure(
      isWrite
          ? 'Não foi possível salvar seus dados. Tente novamente.'
          : 'Não foi possível carregar seus dados. Tente novamente.',
    );
  }
  return const ServerFailure(
    'Não foi possível concluir agora. Tente novamente.',
  );
}
