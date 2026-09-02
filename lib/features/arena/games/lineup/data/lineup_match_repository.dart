import 'dart:async';
import 'dart:ui';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/club_scoped_fallback.dart';
import 'package:goias_app/features/arena/games/lineup/formation_layout_service.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/word_evaluation_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fallback offline por clube — ver comentário equivalente em
/// `career_player_repository.dart`.
final orderedLineupMatchesFallback = ClubScopedFallback<List<LineupMatch>>({
  'goias': orderedLineupMatches,
});

/// Banco de partidas do Adivinhe a Escalação. Fonte da verdade é o
/// Supabase, SEMPRE filtrada pelo clube ativo (`club_id`); fallback também
/// resolvido por clube. Só o que foi curado à mão (posição, número, nome,
/// resposta, apelidos) vem do banco — coordenadas de campo e resposta
/// normalizada são sempre recalculadas aqui, igual o dataset local já
/// fazia, nunca duplicadas na tabela. O jsonb `lineup` continua editorial,
/// sem `person_id` (F7) — esta mudança só filtra a LINHA por `club_id`,
/// nunca toca o conteúdo do slot.
class LineupMatchRepository {
  LineupMatchRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  /// Ver o comentário equivalente em `career_player_repository.dart`: 0
  /// linhas (sucesso) e falha real (rede/parse) NUNCA são conflatadas —
  /// só a 1ª pode virar `ClubDataUnavailableException` sem fallback; a 2ª
  /// sobe a exceção original intacta.
  Future<List<LineupMatch>> load() async {
    final clubCode = _clubConfig.identity.code;
    List<LineupMatch> parsed;
    try {
      final rows = await _client
          .from('lineup_matches')
          .select(
            'id, competition, season, phase, match_date, venue, home_team, '
            'away_team, home_score, away_score, formation, '
            'formation_confidence, lineup',
          )
          .eq('club_id', _clubConfig.identity.canonicalClubId)
          .eq('is_active', true)
          .order('display_order', ascending: true);
      parsed = <LineupMatch>[];
      for (final row in rows) {
        final match = _map(row);
        if (match != null) parsed.add(match);
      }
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      final fallback = orderedLineupMatchesFallback.forClub(clubCode);
      if (fallback != null) return fallback;
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (parsed.isNotEmpty) return parsed;
    final fallback = orderedLineupMatchesFallback.forClub(clubCode);
    if (fallback != null) return fallback;
    throw ClubDataUnavailableException(
      table: 'lineup_matches',
      clubCode: clubCode,
    );
  }

  LineupMatch? _map(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final formation = row['formation'] as String?;
    final lineupRaw = row['lineup'] as List?;
    final confidence = _confidenceFrom(row['formation_confidence'] as String?);
    final matchDate = row['match_date'] as String?;
    if (id == null ||
        formation == null ||
        lineupRaw == null ||
        confidence == null ||
        matchDate == null) {
      return null;
    }

    final positions = FormationLayoutService.positionsFor(formation);
    if (lineupRaw.length != 11 || positions.length != 11) return null;

    final players = <LineupPlayer>[];
    for (var i = 0; i < lineupRaw.length; i++) {
      final player = _mapPlayer(
        '$id-p$i',
        positions[i],
        lineupRaw[i] as Map<String, dynamic>,
      );
      if (player == null) return null;
      players.add(player);
    }

    return LineupMatch(
      id: id,
      competition: row['competition'] as String? ?? '',
      season: row['season'] as String? ?? '',
      phase: row['phase'] as String? ?? '',
      date: DateTime.parse(matchDate),
      venue: row['venue'] as String?,
      homeTeam: row['home_team'] as String? ?? '',
      awayTeam: row['away_team'] as String? ?? '',
      homeScore: (row['home_score'] as num?)?.toInt() ?? 0,
      awayScore: (row['away_score'] as num?)?.toInt() ?? 0,
      teamToGuess: _clubConfig.identity.shortName,
      formation: formation,
      formationConfidence: confidence,
      players: players,
    );
  }

  LineupPlayer? _mapPlayer(
    String id,
    Offset position,
    Map<String, dynamic> json,
  ) {
    final pos = json['pos'] as String?;
    final name = json['name'] as String?;
    final rawAnswer = json['answer'] as String?;
    if (pos == null || name == null || rawAnswer == null) return null;
    final answer = rawAnswer.toUpperCase();
    return LineupPlayer(
      id: id,
      position: pos,
      x: position.dx,
      y: position.dy,
      shirtNumber: (json['no'] as num?)?.toInt(),
      fullName: name,
      displayName: name,
      puzzleAnswer: answer,
      answerParts: answer.split(' ').map((word) => word.length).toList(),
      normalizedAnswer: WordEvaluationService.normalize(answer),
      aliases: ((json['aliases'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  FormationConfidence? _confidenceFrom(String? value) {
    for (final candidate in FormationConfidence.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}
