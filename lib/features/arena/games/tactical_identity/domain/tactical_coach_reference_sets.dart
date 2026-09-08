import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_scoped_fallback.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_engine.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Dataset de referências da "Identidade Futebolística" por clube (mesmo
/// mecanismo de `ClubScopedFallback` usado pelos repositories) —
/// arquitetura multiclube adicionada em 2026-09-08. O dataset original do
/// Goiás (`tacticalCoachReferences`) segue byte a byte intacto; o do
/// Bragantino foi escrito editorialmente já nos dois eixos e nas quatro
/// auxiliares, nunca convertido de outro schema (ver o cabeçalho de
/// `bragantino_tactical_coach_references.dart`).
///
/// Deliberadamente NUNCA cai pra outro clube quando o código pedido não
/// está aqui — [tacticalIdentityEngineForClub] lança se isso acontecer,
/// nunca mostra silenciosamente os técnicos do Goiás pra outro clube.
const tacticalCoachReferenceSets =
    ClubScopedFallback<List<TacticalCoachReference>>({
      'goias': tacticalCoachReferences,
    });

/// Monta o `TacticalIdentityEngine` com o dataset do clube ativo. Lança
/// [StateError] se o clube não tiver dataset cadastrado — isso só pode
/// acontecer se `enabledArenaGames` incluir `'tactical_identity'` sem o
/// dataset correspondente aqui, um erro de configuração, nunca um estado
/// de runtime esperado.
TacticalIdentityEngine tacticalIdentityEngineForClub(ClubConfig clubConfig) {
  final references = tacticalCoachReferenceSets.forClub(
    clubConfig.identity.code,
  );
  if (references == null) {
    throw StateError(
      'Sem dataset de "Identidade Futebolística" pro clube '
      '${clubConfig.identity.code} — não habilite "tactical_identity" em '
      'enabledArenaGames até cadastrar em tacticalCoachReferenceSets.',
    );
  }
  return TacticalIdentityEngine(references);
}
