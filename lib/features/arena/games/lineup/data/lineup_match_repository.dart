import 'dart:ui';

import 'package:goias_app/features/arena/games/lineup/formation_layout_service.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/word_evaluation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Banco de partidas do Adivinhe a Escalação. Fonte da verdade é o
/// Supabase (editável sem republicar o app); o const `orderedLineupMatches`
/// fica como fallback offline / tabela vazia. Só o que foi curado à mão
/// (posição, número, nome, resposta, apelidos) vem do banco — coordenadas
/// de campo e resposta normalizada são sempre recalculadas aqui, igual o
/// dataset local já fazia, nunca duplicadas na tabela.
class LineupMatchRepository {
  LineupMatchRepository(this._client);

  final SupabaseClient _client;

  Future<List<LineupMatch>> load() async {
    try {
      final rows = await _client
          .from('lineup_matches')
          .select(
            'id, competition, season, phase, match_date, venue, home_team, '
            'away_team, home_score, away_score, formation, '
            'formation_confidence, lineup',
          )
          .eq('is_active', true)
          .order('display_order');
      final parsed = <LineupMatch>[];
      for (final row in rows) {
        final match = _map(row);
        if (match != null) parsed.add(match);
      }
      return parsed.isEmpty ? orderedLineupMatches : parsed;
    } catch (_) {
      return orderedLineupMatches;
    }
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
      teamToGuess: 'Goiás',
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
