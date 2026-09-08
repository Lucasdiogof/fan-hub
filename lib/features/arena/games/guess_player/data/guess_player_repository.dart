import 'dart:async';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/club_scoped_fallback.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_catalog.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fallback offline por clube — ver comentário equivalente em
/// `career_player_repository.dart`.
final guessPlayerCatalogFallback = ClubScopedFallback<List<GuessPlayer>>({
  'goias': guessPlayerCatalog,
});

/// Catálogo do Quem Vestiu o Manto. Fonte da verdade é o Supabase, SEMPRE
/// filtrada pelo clube ativo (`club_id`); fallback também resolvido por
/// clube — nunca cai pro fallback de outro clube. `photo_key` guarda só a
/// chave de `ClubConfig.assets.guessPlayerPhotos` — a foto em si continua
/// resolvida aqui, nunca uma URL duplicada/guardada na tabela.
class GuessPlayerRepository {
  GuessPlayerRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  /// Ver o comentário equivalente em `career_player_repository.dart`: 0
  /// linhas (sucesso) e falha real (rede/parse) NUNCA são conflatadas —
  /// só a 1ª pode virar `ClubDataUnavailableException` sem fallback; a 2ª
  /// sobe a exceção original intacta.
  Future<List<GuessPlayer>> load() async {
    final clubCode = _clubConfig.identity.code;
    List<GuessPlayer> parsed;
    try {
      final rows = await _client
          .from('guess_players')
          .select(
            'id, name, display_name, aliases, position, shirt_number, '
            'academy_club, nationality_code, nationality_name, '
            'club_debut_year, photo_key, data_status, person_id',
          )
          .eq('club_id', _clubConfig.identity.canonicalClubId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      parsed = <GuessPlayer>[];
      for (final row in rows) {
        final player = _map(row);
        if (player != null) parsed.add(player);
      }
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      final fallback = guessPlayerCatalogFallback.forClub(clubCode);
      if (fallback != null) return fallback;
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (parsed.isNotEmpty) return parsed;
    final fallback = guessPlayerCatalogFallback.forClub(clubCode);
    if (fallback != null) return fallback;
    throw ClubDataUnavailableException(
      table: 'guess_players',
      clubCode: clubCode,
    );
  }

  GuessPlayer? _map(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final name = row['name'] as String?;
    final displayName = row['display_name'] as String?;
    if (id == null || name == null || displayName == null) return null;

    final photoKey = row['photo_key'] as String?;

    return GuessPlayer(
      id: id,
      name: name,
      displayName: displayName,
      aliases: ((row['aliases'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      position: _positionFrom(row['position'] as String?),
      shirtNumber: (row['shirt_number'] as num?)?.toInt(),
      academyClub: row['academy_club'] as String?,
      nationalityCode: row['nationality_code'] as String?,
      nationalityName: row['nationality_name'] as String?,
      clubDebutYear: (row['club_debut_year'] as num?)?.toInt(),
      // `photo_key` pode apontar pro elenco atual/histórico deste jogo
      // (`ClubConfig.assets.guessPlayerPhotos`, POR CLUBE — pro Goiás são
      // os mesmos assets locais de sempre, `squadPhotoAssets`; pro
      // Bragantino é uma mistura de URLs remotas do CDN oficial + assets
      // locais históricos) ou pro acervo global só-deste-jogo
      // (`goiasGuessPlayerPhotos`, ainda só do Goiás). Campo separado de
      // `squadPhotos` porque `SquadAvatar` (dono de `squadPhotos`) só sabe
      // tratar asset local — colocar uma URL remota lá quebra o Elenco
      // silenciosamente (achado ao vivo em 2026-09-08 com o goleiro
      // Cleiton, que aparece tanto no elenco atual quanto como carta
      // histórica deste jogo).
      imageUrl: photoKey == null
          ? null
          // SEM fallback pra outro clube: se a chave não está no mapa do
          // clube ativo, o card fica sem foto. Antes caía num mapa global de
          // fotos do Goiás, o que faria um clube sem foto própria mostrar o
          // rosto de um jogador esmeraldino no card dele.
          : _clubConfig.assets.guessPlayerPhotos[photoKey],
      dataStatus: _dataStatusFrom(row['data_status'] as String?),
      personId: row['person_id'] as String?,
    );
  }

  PlayerPosition? _positionFrom(String? value) {
    if (value == null) return null;
    for (final candidate in PlayerPosition.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }

  GuessPlayerDataStatus _dataStatusFrom(String? value) {
    for (final candidate in GuessPlayerDataStatus.values) {
      if (candidate.name == value) return candidate;
    }
    return GuessPlayerDataStatus.incomplete;
  }
}
