import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [isWrite] escolhe a mensagem certa pro tipo de operação — uma falha
/// LENDO o perfil não pode dizer "não foi possível salvar" (aconteceu de
/// verdade: `getProfile` reaproveitava a mesma mensagem de escrita e a
/// aba Sócio mostrava "não foi possível salvar seus dados" pra uma
/// simples falha de carregamento, confundindo o usuário sobre o que
/// realmente deu errado).
///
/// Manda o erro original pro Sentry antes de traduzir pra mensagem
/// amigável — sem isso, a exceção de verdade (ex.: qual `PostgrestException`
/// específica) nunca fica visível em lugar nenhum depois que vira só um
/// texto genérico pro usuário.
Failure mapProfileError(
  Object error,
  StackTrace stackTrace, {
  bool isWrite = true,
}) {
  unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  final name = error.runtimeType.toString();
  if (name.contains('SocketException') ||
      name.contains('ClientException') ||
      name.contains('TimeoutException')) {
    return const NetworkFailure();
  }
  // 23505 = unique_violation do Postgres — o único índice único em
  // `profiles` além da PK (que não pode colidir num UPDATE) é
  // `profiles_cpf_unique_idx`, então qualquer 23505 aqui é sempre CPF já
  // cadastrado em outra conta.
  if (error is PostgrestException && error.code == '23505') {
    return const ServerFailure('Este CPF já está cadastrado em outra conta.');
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
