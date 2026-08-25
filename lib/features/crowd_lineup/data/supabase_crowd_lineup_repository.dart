import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCrowdLineupRepository implements CrowdLineupRepository {
  SupabaseCrowdLineupRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Result<LineupVote?>> getMyVote(String matchId) async {
    try {
      final row = await _client
          .from('match_lineup_votes')
          .select('formation, slots')
          .eq('match_id', matchId)
          .eq('user_id', _uid)
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
    } catch (_) {
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
      await _client.from('match_lineup_votes').upsert({
        'match_id': matchId,
        'user_id': _uid,
        'formation': vote.formationId,
        'slots': slots,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'match_id,user_id');
      return const Success(null);
    } catch (_) {
      return const Error(
        ServerFailure('Não foi possível enviar sua escalação.'),
      );
    }
  }

  @override
  Future<Result<CrowdLineup>> getCrowdLineup(String matchId) async {
    try {
      final data = await _client.rpc<Map<String, dynamic>>(
        'crowd_lineup',
        params: {'p_match_id': matchId},
      );
      return Success(_parseCrowd(data));
    } catch (_) {
      return const Error(
        ServerFailure('Não foi possível carregar a escalação da torcida.'),
      );
    }
  }

  CrowdLineup _parseCrowd(Map<String, dynamic> data) {
    final totalVotes = (data['total_votes'] as num?)?.toInt() ?? 0;
    final formationCounts =
        (data['formations'] as Map<String, dynamic>?) ?? const {};
    if (totalVotes == 0 || formationCounts.isEmpty) {
      return const CrowdLineup.empty();
    }

    // Formação mais votada.
    final topFormationId = formationCounts.entries
        .reduce((a, b) => (a.value as num) >= (b.value as num) ? a : b)
        .key;
    final formation = formationById(topFormationId);
    final formationVotes = (formationCounts[topFormationId] as num).toInt();

    final slotsData =
        ((data['slots'] as Map<String, dynamic>?)?[topFormationId]
            as Map<String, dynamic>?) ??
        const {};

    final results = <CrowdSlotResult>[];
    for (var i = 0; i < formation.slots.length; i++) {
      final counts = (slotsData['$i'] as Map<String, dynamic>?) ?? const {};
      String? topPid;
      var topCount = 0;
      counts.forEach((pid, count) {
        final c = (count as num).toInt();
        if (c > topCount) {
          topCount = c;
          topPid = pid;
        }
      });
      results.add(
        CrowdSlotResult(
          slotIndex: i,
          position: formation.slots[i].position,
          player: topPid == null ? null : squadById[topPid],
          percent: formationVotes == 0
              ? 0
              : ((topCount / formationVotes) * 100).round(),
        ),
      );
    }

    return CrowdLineup(
      totalVotes: totalVotes,
      topFormation: formation,
      slots: results,
    );
  }
}
