import 'dart:async';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCrowdLineupRepository implements CrowdLineupRepository {
  SupabaseCrowdLineupRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  @override
  Future<Result<LineupVote?>> getMyVote(String matchId) async {
    try {
      final row = await _client
          .from('match_lineup_votes')
          .select('formation, slots')
          .eq('match_id', matchId)
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .maybeSingle();
      if (row == null) return const Success(null);

      final slots = <int, String>{};
      for (final entry in (row['slots'] as List<dynamic>)) {
        final map = entry as Map<String, dynamic>;
        slots[(map['i'] as num).toInt()] = map['pid'] as String;
      }
      return Success(
        LineupVote(
          formationId: row['formation'] as String,
          playerIdBySlot: slots,
        ),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível carregar sua escalação.'),
      );
    }
  }

  @override
  Future<Result<void>> submitVote(String matchId, LineupVote vote) async {
    try {
      final slots = [
        for (final entry in vote.playerIdBySlot.entries)
          {'i': entry.key, 'pid': entry.value},
      ];
      // onConflict continua (match_id, user_id) — KEY_SCOPE_BLOCKED, mesma
      // ressalva das outras tabelas de estado por usuário desta etapa.
      await _client.from('match_lineup_votes').upsert({
        'match_id': matchId,
        'user_id': _uid,
        'club_id': _clubId,
        'formation': vote.formationId,
        'slots': slots,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'match_id,user_id');
      return const Success(null);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível enviar sua escalação.'),
      );
    }
  }

  @override
  Future<Result<CrowdLineup>> getCrowdLineup(String matchId) async {
    try {
      // Runtime novo (M3.2): variante tenant-aware, nunca a `crowd_lineup`
      // legacy (fica só pro app antigo — ver §17 do pedido da M3.2).
      final data = await _client.rpc<Map<String, dynamic>>(
        'crowd_lineup_for_club',
        params: {'p_club_id': _clubId, 'p_match_id': matchId},
      );
      return Success(_parseCrowd(data));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        ServerFailure('Não foi possível carregar a escalação da torcida.'),
      );
    }
  }

  /// A escalação da torcida não segue mais "a formação mais votada, com o
  /// jogador mais escolhido dentro dela" — isso deixava jogador com votos de
  /// verdade de fora só porque a formação vencedora não tinha um slot pra
  /// posição dele (ex.: ponta com votos ficando fora de uma 4-5-1 sem
  /// pontas). Agora: soma os votos de cada jogador por POSIÇÃO em todas as
  /// formações/votos recebidos (não só na formação vencedora), depois
  /// escolhe, entre as formações conhecidas, a que melhor acomoda quem tem
  /// mais voto — e o percentual de cada jogador é sobre o total de
  /// escalações enviadas, nunca sobre o total da formação escolhida (que
  /// pode ser bem menor e inflar o percentual artificialmente).
  CrowdLineup _parseCrowd(Map<String, dynamic> data) {
    final totalVotes = (data['total_votes'] as num?)?.toInt() ?? 0;
    final slotsByFormation =
        (data['slots'] as Map<String, dynamic>?) ?? const {};
    if (totalVotes == 0 || slotsByFormation.isEmpty) {
      return const CrowdLineup.empty();
    }

    // votesByPlayerPosition[pid][position] = quantas escalações colocaram
    // esse jogador nessa posição, somando TODAS as formações votadas.
    final votesByPlayerPosition = <String, Map<PlayerPosition, int>>{};
    slotsByFormation.forEach((formationId, slotsRaw) {
      final formation = formationById(formationId);
      final slotsForFormation = slotsRaw as Map<String, dynamic>;
      slotsForFormation.forEach((slotKey, pidCountsRaw) {
        final slotIndex = int.tryParse(slotKey);
        if (slotIndex == null || slotIndex >= formation.slots.length) return;
        final position = formation.slots[slotIndex].position;
        final pidCounts = pidCountsRaw as Map<String, dynamic>;
        pidCounts.forEach((pid, count) {
          final c = (count as num).toInt();
          final byPosition = votesByPlayerPosition.putIfAbsent(pid, () => {});
          byPosition[position] = (byPosition[position] ?? 0) + c;
        });
      });
    });

    Formation? bestFormation;
    List<_SlotAssignment>? bestAssignments;
    var bestScore = -1;
    for (final formation in formations) {
      final assignments = _assignSlots(formation, votesByPlayerPosition);
      final score = assignments.fold<int>(0, (sum, a) => sum + a.votes);
      if (score > bestScore) {
        bestScore = score;
        bestFormation = formation;
        bestAssignments = assignments;
      }
    }
    if (bestFormation == null || bestAssignments == null) {
      return const CrowdLineup.empty();
    }

    final results = [
      for (final assignment in bestAssignments)
        CrowdSlotResult(
          slotIndex: assignment.slotIndex,
          position: bestFormation.slots[assignment.slotIndex].position,
          player: assignment.playerId == null
              ? null
              : squadById[assignment.playerId],
          percent: totalVotes == 0
              ? 0
              : ((assignment.votes / totalVotes) * 100).round(),
        ),
    ];

    return CrowdLineup(
      totalVotes: totalVotes,
      topFormation: bestFormation,
      slots: results,
    );
  }

  /// Preenche os slots de [formation] com os jogadores mais votados pra cada
  /// posição que ela exige, sem repetir jogador entre slots (quando uma
  /// formação tem 2 zagueiros, por exemplo, pega os 2 zagueiros mais
  /// votados, não o mesmo duas vezes). Slot sem nenhum jogador votado nessa
  /// posição fica vazio — nunca inventa um jogador.
  List<_SlotAssignment> _assignSlots(
    Formation formation,
    Map<String, Map<PlayerPosition, int>> votesByPlayerPosition,
  ) {
    final slotIndicesByPosition = <PlayerPosition, List<int>>{};
    for (var i = 0; i < formation.slots.length; i++) {
      slotIndicesByPosition
          .putIfAbsent(formation.slots[i].position, () => [])
          .add(i);
    }

    final usedPids = <String>{};
    final assignments = List<_SlotAssignment>.generate(
      formation.slots.length,
      (i) => _SlotAssignment(slotIndex: i, playerId: null, votes: 0),
    );

    for (final entry in slotIndicesByPosition.entries) {
      final position = entry.key;
      final slotIndices = entry.value;
      final candidates =
          votesByPlayerPosition.entries
              .where((e) => e.value.containsKey(position))
              .where((e) => !usedPids.contains(e.key))
              .map((e) => (pid: e.key, votes: e.value[position]!))
              .toList()
            ..sort((a, b) => b.votes.compareTo(a.votes));

      for (var i = 0; i < slotIndices.length && i < candidates.length; i++) {
        final candidate = candidates[i];
        usedPids.add(candidate.pid);
        assignments[slotIndices[i]] = _SlotAssignment(
          slotIndex: slotIndices[i],
          playerId: candidate.pid,
          votes: candidate.votes,
        );
      }
    }

    return assignments;
  }
}

class _SlotAssignment {
  const _SlotAssignment({
    required this.slotIndex,
    required this.playerId,
    required this.votes,
  });

  final int slotIndex;
  final String? playerId;
  final int votes;
}
