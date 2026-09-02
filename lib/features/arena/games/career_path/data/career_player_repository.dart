import 'dart:async';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/club_scoped_fallback.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fallback offline por clube — só `'goias'` cadastrado hoje (único clube
/// real), mas o mecanismo (`ClubScopedFallback`) já é genérico: um 2º
/// clube nunca reaproveita este fallback sem entrada própria aqui.
final careerPlayersFallback = ClubScopedFallback<List<CareerPlayer>>({
  'goias': careerPlayers,
});

/// Banco de jogadores do Adivinhe o Jogador. Fonte da verdade é o Supabase,
/// SEMPRE filtrada pelo clube ativo (`club_id`); o fallback offline
/// também é resolvido por clube — nunca cai pro fallback de outro clube
/// (`careerPlayers`, hoje o único cadastrado, é especificamente o do
/// Goiás, não um "fallback genérico").
class CareerPlayerRepository {
  CareerPlayerRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  /// Duas semânticas de erro, NUNCA conflatadas (rodada de revisão):
  ///   1. consulta bem-sucedida, 0 linhas pro clube — dataset ausente, não
  ///      é erro nenhum. Sem fallback: `ClubDataUnavailableException`.
  ///   2. consulta/parse FALHOU de verdade (rede, timeout, PostgREST,
  ///      `TypeError` num row malformado etc.) — sem fallback, a exceção
  ///      ORIGINAL sobe intacta (stack trace preservado via
  ///      `Error.throwWithStackTrace`), NUNCA convertida em
  ///      `ClubDataUnavailableException` — que significaria "sabemos que
  ///      não tem dado", uma afirmação falsa quando na verdade nem
  ///      conseguimos perguntar.
  Future<List<CareerPlayer>> load() async {
    final clubCode = _clubConfig.identity.code;
    List<CareerPlayer> parsed;
    try {
      final rows = await _client
          .from('career_players')
          .select(
            'id, answer, accepted_answers, position, club_career, national_teams, aggregate_stats, person_id',
          )
          .eq('club_id', _clubConfig.identity.canonicalClubId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      parsed = <CareerPlayer>[];
      for (final row in rows) {
        final player = _map(row);
        if (player != null) parsed.add(player);
      }
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      final fallback = careerPlayersFallback.forClub(clubCode);
      if (fallback != null) return fallback;
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (parsed.isNotEmpty) return parsed;
    // Consulta funcionou e não é erro — só não há linha pra este clube
    // ainda (dataset não provisionado). Nunca reporta ao Sentry por isso.
    final fallback = careerPlayersFallback.forClub(clubCode);
    if (fallback != null) return fallback;
    throw ClubDataUnavailableException(
      table: 'career_players',
      clubCode: clubCode,
    );
  }

  CareerPlayer? _map(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final answer = row['answer'] as String?;
    final clubCareerRaw = row['club_career'] as List?;
    if (id == null || answer == null || clubCareerRaw == null) return null;

    final clubCareer = clubCareerRaw
        .map((e) => _mapEntry(e as Map<String, dynamic>))
        .whereType<CareerEntry>()
        .toList();
    if (clubCareer.isEmpty) return null;

    final nationalTeams = ((row['national_teams'] as List?) ?? [])
        .map((e) => _mapEntry(e as Map<String, dynamic>))
        .whereType<CareerEntry>()
        .toList();

    final acceptedAnswers = ((row['accepted_answers'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    final aggregateStats = ((row['aggregate_stats'] as List?) ?? [])
        .map((e) => _mapAggregate(e as Map<String, dynamic>))
        .whereType<CareerAggregateStat>()
        .toList();

    return CareerPlayer(
      id: id,
      answer: answer,
      acceptedAnswers: acceptedAnswers.isEmpty ? [answer] : acceptedAnswers,
      position: row['position'] as String?,
      clubCareer: clubCareer,
      nationalTeams: nationalTeams,
      aggregateStats: aggregateStats,
      personId: row['person_id'] as String?,
    );
  }

  CareerEntry? _mapEntry(Map<String, dynamic> json) {
    final period = json['period'] as String?;
    final team = json['team'] as String?;
    if (period == null || team == null) return null;
    return CareerEntry(
      period: period,
      team: team,
      appearances: (json['appearances'] as num?)?.toInt(),
      goals: (json['goals'] as num?)?.toInt(),
      loan: json['loan'] as bool? ?? false,
      isGoias: json['is_goias'] as bool? ?? false,
    );
  }

  CareerAggregateStat? _mapAggregate(Map<String, dynamic> json) {
    final club = json['club'] as String?;
    if (club == null) return null;
    return CareerAggregateStat(
      club: club,
      spells: ((json['spells'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      appearances: (json['appearances'] as num?)?.toInt(),
      goals: (json['goals'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }
}
