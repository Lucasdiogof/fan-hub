import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_scoped_fallback.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_engine.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_references.dart';

/// Dataset de referências do "Que craque é você?" por clube (mesmo
/// mecanismo de `ClubScopedFallback` usado pelos repositories) —
/// arquitetura multiclube adicionada em 2026-09-08. O dataset original do
/// Goiás (`playerIdentityReferences`) segue byte a byte intacto; o do
/// Bragantino foi escrito editorialmente nas 6 dimensões reais, nunca
/// convertido de outro schema (ver o cabeçalho de
/// `bragantino_player_identity_references.dart`).
///
/// Deliberadamente NUNCA cai pra outro clube quando o código pedido não
/// está aqui — [playerIdentityEngineForClub] lança se isso acontecer, nunca
/// mostra silenciosamente os jogadores do Goiás pra outro clube.
const playerIdentityReferenceSets =
    ClubScopedFallback<List<PlayerIdentityReference>>({
      'goias': playerIdentityReferences,
    });

/// Monta o `PlayerIdentityEngine` com o dataset do clube ativo. Lança
/// [StateError] se o clube não tiver dataset cadastrado — isso só pode
/// acontecer se `enabledArenaGames` incluir `'player_identity'` sem o
/// dataset correspondente aqui, um erro de configuração, nunca um estado
/// de runtime esperado.
PlayerIdentityEngine playerIdentityEngineForClub(ClubConfig clubConfig) {
  final references = playerIdentityReferenceSets.forClub(
    clubConfig.identity.code,
  );
  if (references == null) {
    throw StateError(
      'Sem dataset de "Que craque é você?" pro clube '
      '${clubConfig.identity.code} — não habilite "player_identity" em '
      'enabledArenaGames até cadastrar em playerIdentityReferenceSets.',
    );
  }
  return PlayerIdentityEngine(references);
}
