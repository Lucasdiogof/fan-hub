import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/competition_season_dto.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';

void main() {
  test(
    'parseia uma temporada de fase única (liga) igual ao Worker manda hoje',
    () {
      final dto = CompetitionSeasonDto.fromJson({
        'id': 'primary',
        'label': 'Brasileirão Série B',
        'stages': [
          {
            'id': 'main',
            'name': 'Brasileirão Série B',
            'order': 0,
            'type': 'LEAGUE_TABLE',
            'status': 'ACTIVE',
            'isCurrent': true,
            'standings': [],
            'groups': [],
            'rounds': [],
          },
        ],
      });
      final season = dto.toEntity();
      expect(season.stages, hasLength(1));
      expect(season.stages.single.type, StageType.leagueTable);
      expect(season.stages.single.status, StageStatus.active);
      expect(season.stages.single.isCurrent, isTrue);
    },
  );

  test(
    'parseia uma Stage de mata-mata com uma rodada e um confronto de ida/volta',
    () {
      final dto = CompetitionSeasonDto.fromJson({
        'id': 'copa-do-brasil',
        'label': 'Copa do Brasil',
        'stages': [
          {
            'id': 'knockout',
            'name': 'Mata-mata',
            'order': 0,
            'type': 'KNOCKOUT',
            'status': 'ACTIVE',
            'isCurrent': true,
            'rounds': [
              {
                'id': 'round-0',
                'name': 'Semifinais',
                'order': 0,
                'status': 'ACTIVE',
                'isCurrent': true,
                'ties': [
                  {
                    'homeTeam': {
                      'id': 1670,
                      'name': 'Grêmio',
                      'logo': 'https://x/1670.png',
                    },
                    'awayTeam': {
                      'id': 1693,
                      'name': 'Palmeiras',
                      'logo': 'https://x/1693.png',
                    },
                    'legs': [
                      {
                        'legType': 'FIRST',
                        'status': 'finished',
                        'kickoff': '2026-08-20T23:00:00.000Z',
                        'homeScore': 1,
                        'awayScore': 0,
                      },
                      {
                        'legType': 'SECOND',
                        'status': 'finished',
                        'kickoff': '2026-08-27T23:00:00.000Z',
                        'homeScore': 1,
                        'awayScore': 1,
                      },
                    ],
                    'aggregateHome': 1,
                    'aggregateAway': 1,
                    'penaltyHome': null,
                    'penaltyAway': null,
                  },
                ],
              },
            ],
          },
        ],
      });
      final season = dto.toEntity();
      final stage = season.stages.single;
      expect(stage.type, StageType.knockout);
      expect(stage.rounds, hasLength(1));
      final round = stage.rounds.single;
      expect(round.name, 'Semifinais');
      expect(round.isCurrent, isTrue);
      final tie = round.ties.single;
      expect(tie.homeTeam.name, 'Grêmio');
      expect(tie.legs, hasLength(2));
      expect(tie.aggregateHome, 1);
      expect(tie.aggregateAway, 1);
      expect(tie.wentToPenalties, isFalse);
      expect(stage.currentRound?.name, 'Semifinais');
    },
  );

  test('campos ausentes/nulos nunca quebram o parse (defaults seguros)', () {
    final dto = CompetitionSeasonDto.fromJson(const {});
    final season = dto.toEntity();
    expect(season.stages, isEmpty);
  });
}
