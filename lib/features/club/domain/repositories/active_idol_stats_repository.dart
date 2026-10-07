import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Números ATUAIS dos ídolos que ainda jogam: baseline auditado + partidas
/// posteriores (ver `computeIdolStats`).
abstract interface class ActiveIdolStatsRepository {
  /// Calcula, em UMA passada (sem consulta por jogador), os números de todos
  /// os ídolos de [idols] que têm `tracking`; os demais são ignorados. A
  /// chave do mapa é `ClubIdol.name`.
  ///
  /// NUNCA lança e FALHA FECHADO: só devolve um total NOVO quando TODAS as
  /// partidas finalizadas posteriores ao baseline foram verificadas. Se
  /// qualquer uma não puder ser carregada, devolve o último snapshot COMPLETO
  /// conhecido ou, não havendo, o baseline auditado — nunca um total parcial
  /// que pareça atual (subcontagem silenciosa) e nunca zero/`null`.
  Future<Map<String, IdolStats>> loadStats(List<ClubIdol> idols);

  /// Último snapshot COMPLETO já calculado nesta sessão para [idol], ou
  /// `null`. A tela parte dele (e não do baseline) ao reabrir.
  IdolStats? lastCompleteFor(ClubIdol idol);
}
