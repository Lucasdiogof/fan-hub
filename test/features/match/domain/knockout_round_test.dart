import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

const _home = Team(id: 1, name: 'A', shortName: 'A', color: Color(0xFF000000));
const _away = Team(id: 2, name: 'B', shortName: 'B', color: Color(0xFF000000));

KnockoutTie _tie() => const KnockoutTie(
  homeTeam: _home,
  awayTeam: _away,
  legs: [
    KnockoutLeg(
      legType: KnockoutLegType.single,
      status: MatchStatus.finished,
      homeScore: 1,
      awayScore: 0,
    ),
  ],
  aggregateHome: 1,
  aggregateAway: 0,
);

KnockoutRound _round(
  String id, {
  bool isCurrent = false,
  StageStatus status = StageStatus.active,
}) => KnockoutRound(
  id: id,
  name: id,
  order: 0,
  status: status,
  isCurrent: isCurrent,
  ties: [_tie()],
);

void main() {
  group(
    'CompetitionStage.currentRound — "current knockout round" (spec item 8)',
    () {
      test('escolhe a rodada marcada isCurrent pelo Worker', () {
        final stage = CompetitionStage(
          id: 'knockout',
          name: 'Mata-mata',
          order: 0,
          type: StageType.knockout,
          status: StageStatus.active,
          isCurrent: true,
          rounds: [_round('oitavas'), _round('quartas', isCurrent: true)],
        );
        expect(stage.currentRound?.id, 'quartas');
      });

      test('sem nenhuma isCurrent, cai pra última rodada', () {
        final stage = CompetitionStage(
          id: 'knockout',
          name: 'Mata-mata',
          order: 0,
          type: StageType.knockout,
          status: StageStatus.active,
          isCurrent: true,
          rounds: [_round('oitavas'), _round('quartas')],
        );
        expect(stage.currentRound?.id, 'quartas');
      });

      test('Stage sem nenhuma rodada -> currentRound nulo', () {
        const stage = CompetitionStage(
          id: 'knockout',
          name: 'Mata-mata',
          order: 0,
          type: StageType.knockout,
          status: StageStatus.upcoming,
          isCurrent: false,
        );
        expect(stage.currentRound, isNull);
      });

      test(
        'Stage de tabela (não-knockout) também tem currentRound nulo (rounds sempre vazio)',
        () {
          const stage = CompetitionStage(
            id: 'main',
            name: 'Brasileirão',
            order: 0,
            type: StageType.leagueTable,
            status: StageStatus.active,
            isCurrent: true,
          );
          expect(stage.currentRound, isNull);
          expect(stage.hasData, isFalse);
        },
      );

      test('hasData é true quando há rounds, mesmo sem standings/groups', () {
        final stage = CompetitionStage(
          id: 'knockout',
          name: 'Mata-mata',
          order: 0,
          type: StageType.knockout,
          status: StageStatus.active,
          isCurrent: true,
          rounds: [_round('final')],
        );
        expect(stage.hasData, isTrue);
      });
    },
  );
}
