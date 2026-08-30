import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mesmo padrão de `membership_error_mapper.dart` — manda o erro original
/// pro Sentry antes de traduzir pra mensagem amigável. Cobre tanto os
/// repositórios locais da Loja (catálogo mock, carrinho/favoritos em
/// SharedPreferences) quanto o Supabase (pedidos).
Failure mapStoreError(Object error, StackTrace stackTrace) {
  unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  final name = error.runtimeType.toString();
  if (name.contains('SocketException') ||
      name.contains('ClientException') ||
      name.contains('TimeoutException')) {
    return const NetworkFailure();
  }
  if (error is PostgrestException) {
    return const ServerFailure(
      'Não foi possível concluir agora. Tente novamente.',
    );
  }
  return const ServerFailure(
    'Não foi possível concluir agora. Tente novamente.',
  );
}
