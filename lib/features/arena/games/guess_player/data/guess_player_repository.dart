import 'dart:async';

import 'package:goias_app/features/arena/games/guess_player/data/guess_player_catalog.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/squad/domain/squad_photos.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Catálogo do Quem Vestiu o Manto. Fonte da verdade é o Supabase
/// (editável sem republicar o app); o const `guessPlayerCatalog` fica como
/// fallback offline / tabela vazia. `photo_key` guarda só a chave de
/// `squadPhotoAssets` — a foto em si continua resolvida aqui, nunca uma URL
/// duplicada/guardada na tabela (só o elenco atual tem foto).
class GuessPlayerRepository {
  GuessPlayerRepository(this._client);

  final SupabaseClient _client;

  Future<List<GuessPlayer>> load() async {
    try {
      final rows = await _client
          .from('guess_players')
          .select(
            'id, name, display_name, aliases, position, shirt_number, '
            'academy_club, nationality_code, nationality_name, '
            'goias_debut_year, photo_key, data_status',
          )
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      final parsed = <GuessPlayer>[];
      for (final row in rows) {
        final player = _map(row);
        if (player != null) parsed.add(player);
      }
      return parsed.isEmpty ? guessPlayerCatalog : parsed;
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return guessPlayerCatalog;
    }
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
      goiasDebutYear: (row['goias_debut_year'] as num?)?.toInt(),
      imageUrl: photoKey != null ? squadPhotoAssets[photoKey] : null,
      dataStatus: _dataStatusFrom(row['data_status'] as String?),
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
