import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

class _CapturingRepository implements CrowdLineupRepository {
  LineupVote? submitted;

  @override
  Future<Result<LineupVote?>> getMyVote(String matchId) async =>
      const Success(null);

  @override
  Future<Result<CrowdLineup>> getCrowdLineup(String matchId) async =>
      const Success(CrowdLineup.empty());

  @override
  Future<Result<void>> submitVote(String matchId, LineupVote vote) async {
    submitted = vote;
    return const Success(null);
  }
}

void main() {
  group('F5 — personId não muda o contrato de persistência já em produção', () {
    test(
      'selectPlayer + submit ainda salva o slug (SquadPlayer.id) em playerIdBySlot, nunca o UUID',
      () async {
        final repository = _CapturingRepository();
        final cubit = CrowdLineupCubit(
          repository: repository,
          matchId: 'm-1',
          votingOpen: true,
        );
        await cubit.load();

        cubit.selectFormation('4-3-3');
        final formationSlots = cubit.state.formation.slots;
        for (var i = 0; i < formationSlots.length; i++) {
          final candidate = playersForPosition(formationSlots[i].position)
              .firstWhere(
                (p) => !cubit.state.pickedIds.contains(p.id),
                orElse: () => goiasSquad.firstWhere(
                  (p) => !cubit.state.pickedIds.contains(p.id),
                ),
              );
          cubit.selectPlayer(i, candidate.id);
        }
        expect(cubit.state.isComplete, isTrue);

        final ok = await cubit.submit();
        expect(ok, isTrue);

        final submitted = repository.submitted;
        expect(submitted, isNotNull);
        for (final pid in submitted!.playerIdBySlot.values) {
          expect(
            squadById.containsKey(pid),
            isTrue,
            reason:
                'playerIdBySlot deveria conter o slug ($pid não é um id de goiasSquad)',
          );
          expect(
            _uuidPattern.hasMatch(pid),
            isFalse,
            reason:
                'playerIdBySlot NUNCA deveria carregar um UUID — o contrato de persistência é o slug',
          );
        }
      },
    );

    test(
      'a partir de um slug persistido, dá pra resolver o personId canônico sem mudar o payload',
      () {
        const persistedSlug = 'tadeu'; // como já está salvo em produção hoje
        final player = squadById[persistedSlug];
        expect(player, isNotNull);
        expect(_uuidPattern.hasMatch(player!.personId), isTrue);
        expect(player.personId, 'e2507d62-8cb5-5152-af56-f67464196ac6');
      },
    );
  });
}
