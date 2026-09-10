import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

const _home = Team(
  id: 1,
  name: 'Time A',
  shortName: 'A',
  color: Color(0xFF000000),
);
const _away = Team(
  id: 2,
  name: 'Time B',
  shortName: 'B',
  color: Color(0xFF000000),
);

void main() {
  test('jogo único decidido -> winner é quem tem mais gols no agregado', () {
    const tie = KnockoutTie(
      homeTeam: _home,
      awayTeam: _away,
      legs: [
        KnockoutLeg(
          legType: KnockoutLegType.single,
          status: MatchStatus.finished,
          homeScore: 2,
          awayScore: 1,
        ),
      ],
      aggregateHome: 2,
      aggregateAway: 1,
    );
    expect(tie.isDecided, isTrue);
    expect(tie.winner, _home);
    expect(tie.wentToPenalties, isFalse);
  });

  test(
    'ida e volta com agregado empatado + pênaltis confirmados -> winner vem dos pênaltis',
    () {
      const tie = KnockoutTie(
        homeTeam: _home,
        awayTeam: _away,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.first,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 0,
          ),
          KnockoutLeg(
            legType: KnockoutLegType.second,
            status: MatchStatus.finished,
            homeScore: 0,
            awayScore: 1,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 1,
        penaltyHome: 3,
        penaltyAway: 4,
      );
      expect(
        tie.isDecided,
        isFalse,
        reason: 'agregado empatado não é "decidido" sozinho',
      );
      expect(tie.wentToPenalties, isTrue);
      expect(tie.winner, _away);
    },
  );

  test('confronto futuro sem placar nenhum -> sem vencedor, nunca inventa', () {
    const tie = KnockoutTie(
      homeTeam: _home,
      awayTeam: _away,
      legs: [
        KnockoutLeg(
          legType: KnockoutLegType.single,
          status: MatchStatus.scheduled,
        ),
      ],
    );
    expect(tie.aggregateHome, isNull);
    expect(tie.aggregateAway, isNull);
    expect(tie.isDecided, isFalse);
    expect(tie.winner, isNull);
  });

  test(
    'agregado empatado sem confirmação de pênaltis -> sem vencedor (nunca chuta)',
    () {
      const tie = KnockoutTie(
        homeTeam: _home,
        awayTeam: _away,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 1,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 1,
      );
      expect(tie.winner, isNull);
    },
  );
}
