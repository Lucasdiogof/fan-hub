import 'package:goias_app/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapArenaRankingError(Object error) {
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
