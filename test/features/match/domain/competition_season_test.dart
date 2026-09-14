import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

Standing _standing() => const Standing(
  position: 1,
  team: Team(id: 1, name: 'Time', shortName: 'TIM', color: Color(0xFF000000)),
  isActiveClub: false,
  points: 10,
  played: 5,
  wins: 3,
  draws: 1,
  losses: 1,
  goalDifference: 4,
);

CompetitionStage _emptyStage(String id, int order, {bool isCurrent = false}) =>
    CompetitionStage(
      id: id,
      name: id,
      order: order,
      type: StageType.leagueTable,
      status: StageStatus.upcoming,
      isCurrent: isCurrent,
    );

CompetitionStage _stageWithData(String id, int order) => CompetitionStage(
  id: id,
  name: id,
  order: order,
  type: StageType.leagueTable,
  status: StageStatus.completed,
  isCurrent: false,
  standings: [_standing()],
);

void main() {
  group('CompetitionStage.hasData', () {
    test('falsa sem standings/groups/rounds', () {
      expect(_emptyStage('a', 0).hasData, isFalse);
    });

    test('verdadeira quando standings não está vazio', () {
      expect(_stageWithData('a', 0).hasData, isTrue);
    });
  });

  group('CompetitionSeason.currentStage — prioridade (spec item 8)', () {
    test('1) escolhe a fase marcada isCurrent, mesmo não sendo a última', () {
      final season = CompetitionSeason(
        id: 's',
        label: 'Temporada',
        stages: [
          _emptyStage('oitavas', 0),
          _emptyStage('quartas', 1, isCurrent: true),
          _emptyStage('semi', 2),
        ],
      );
      expect(season.currentStage?.id, 'quartas');
    });

    test(
      '2) sem nenhuma isCurrent, escolhe a ÚLTIMA fase (mais recente) que tem dado',
      () {
        final season = CompetitionSeason(
          id: 's',
          label: 'Temporada',
          stages: [
            _stageWithData('oitavas', 0),
            _stageWithData('quartas', 1),
            _emptyStage('semi', 2),
          ],
        );
        expect(season.currentStage?.id, 'quartas');
      },
    );

    test('3) sem isCurrent e sem nenhum dado, cai pra primeira fase', () {
      final season = CompetitionSeason(
        id: 's',
        label: 'Temporada',
        stages: [_emptyStage('a', 0), _emptyStage('b', 1)],
      );
      expect(season.currentStage?.id, 'a');
    });

    test('temporada sem nenhuma fase -> currentStage nulo', () {
      const season = CompetitionSeason(id: 's', label: 'Temporada', stages: []);
      expect(season.currentStage, isNull);
    });
  });

  // Spec 2026-09-11, item 7/14: cenários REAIS de cada competição — a
  // Champions só tem 1 fase hoje (não inventa uma 2ª), a Sudamericana é a
  // validação de verdade da arquitetura híbrida (grupos + mata-mata na
  // MESMA Season). Os shapes de "Champions futura" no último teste são só
  // pra provar CAPACIDADE arquitetural — nunca apresentados como o estado
  // real da temporada atual dela (ver `standings.test.ts` pro estado real).
  group('Cenários reais — item 7', () {
    test(
      'Champions hoje: 1 fase só (Fase de liga) -> currentStage é ela mesma, sem selector necessário',
      () {
        final championsToday = CompetitionSeason(
          id: 'champions-league',
          label: 'UEFA Champions League',
          stages: [
            CompetitionStage(
              id: 'main',
              name: 'Fase de liga',
              order: 0,
              type: StageType.leagueTable,
              status: StageStatus.active,
              isCurrent: true,
              standings: [_standing()],
            ),
          ],
        );
        expect(championsToday.stages, hasLength(1));
        expect(championsToday.currentStage?.name, 'Fase de liga');
      },
    );

    test('Sudamericana durante grupos: abre Fase de Grupos', () {
      const duringGroups = CompetitionSeason(
        id: 'sudamericana',
        label: 'CONMEBOL Sudamericana',
        stages: [
          CompetitionStage(
            id: 'main',
            name: 'CONMEBOL Sudamericana',
            order: 0,
            type: StageType.groupStage,
            status: StageStatus.active,
            isCurrent: true,
            groups: [],
          ),
        ],
      );
      expect(duringGroups.currentStage?.type, StageType.groupStage);
    });

    test(
      'Sudamericana no mata-mata: abre Mata-mata, mas Fase de Grupos continua acessível pelo StageSelector (a lista de stages não perde a fase anterior)',
      () {
        const inKnockout = CompetitionSeason(
          id: 'sudamericana',
          label: 'CONMEBOL Sudamericana',
          stages: [
            CompetitionStage(
              id: 'main',
              name: 'CONMEBOL Sudamericana',
              order: 0,
              type: StageType.groupStage,
              status: StageStatus.completed,
              isCurrent: false,
              groups: [],
            ),
            CompetitionStage(
              id: 'knockout',
              name: 'Mata-mata',
              order: 1,
              type: StageType.knockout,
              status: StageStatus.active,
              isCurrent: true,
            ),
          ],
        );
        expect(inKnockout.currentStage?.name, 'Mata-mata');
        // Continua no `stages` — o usuário consegue voltar pelo selector.
        expect(inKnockout.stages.map((s) => s.name), [
          'CONMEBOL Sudamericana',
          'Mata-mata',
        ]);
      },
    );

    test(
      'CAPACIDADE arquitetural: uma Season consegue evoluir pra 2 fases usando o mesmo shape já visto na Sudamericana — NUNCA apresentado como o estado real da Champions hoje',
      () {
        final hypotheticalFutureChampions = CompetitionSeason(
          id: 'champions-league',
          label: 'UEFA Champions League',
          stages: [
            CompetitionStage(
              id: 'main',
              name: 'Fase de liga',
              order: 0,
              type: StageType.leagueTable,
              status: StageStatus.completed,
              isCurrent: false,
              standings: [_standing()],
            ),
            const CompetitionStage(
              id: 'knockout',
              name: 'Mata-mata',
              order: 1,
              type: StageType.knockout,
              status: StageStatus.active,
              isCurrent: true,
            ),
          ],
        );
        expect(hypotheticalFutureChampions.stages, hasLength(2));
        expect(hypotheticalFutureChampions.currentStage?.name, 'Mata-mata');
      },
    );
  });
}
