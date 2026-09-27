// REGRESSÃO 2026-09-15 — placares de partidas históricas (1943-1999) que só
// têm `club_score`/`opponent_score` (o resultado é confirmado, mas a fonte
// não distingue mandante/visitante) ficavam invisíveis em 3 telas: cada uma
// checava `homeScore`/`awayScore` diretamente. `PassportMatch.score`
// centraliza a resolução (ver `PassportScoreMode`); este teste trava o
// contrato pra nunca duas telas divergirem de novo.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';

PassportMatch _match({
  int? homeScore,
  int? awayScore,
  int? clubScore,
  int? opponentScore,
  bool? clubIsHome,
  PassportOutcome? outcome,
}) => PassportMatch(
  id: 'm1',
  season: 1946,
  matchDate: DateTime(1946, 6, 30),
  status: PassportMatchStatus.finished,
  competition: 'Campeonato Goiano',
  competitionCode: 'GOIANO',
  opponent: 'ABG-GO',
  attended: false,
  clubIsHome: clubIsHome,
  homeScore: homeScore,
  awayScore: awayScore,
  clubScore: clubScore,
  opponentScore: opponentScore,
  outcome: outcome,
);

void main() {
  group('PassportMatch.score', () {
    test('homeScore/awayScore completos -> modo homeAway', () {
      final match = _match(
        homeScore: 4,
        awayScore: 1,
        clubScore: 4,
        opponentScore: 1,
        clubIsHome: true,
      );
      final score = match.score;
      expect(score.mode, PassportScoreMode.homeAway);
      expect(score.isKnown, isTrue);
      expect(score.firstScore, 4);
      expect(score.secondScore, 1);
    });

    test(
      'só clubScore/opponentScore (goias_is_home null) -> modo clubPerspective, sem inferir mando',
      () {
        final match = _match(clubScore: 0, opponentScore: 2, clubIsHome: null);
        final score = match.score;
        expect(score.mode, PassportScoreMode.clubPerspective);
        expect(score.isKnown, isTrue);
        expect(score.firstScore, 0);
        expect(score.secondScore, 2);
      },
    );

    test('placar 0x0 na perspectiva do clube continua "conhecido"', () {
      // Regressão específica: 0 é falsy-like em várias linguagens — a
      // resolução usa `!= null`, nunca uma checagem de truthiness, então
      // 0x0 nunca é confundido com "desconhecido".
      final match = _match(clubScore: 0, opponentScore: 0);
      final score = match.score;
      expect(score.isKnown, isTrue);
      expect(score.firstScore, 0);
      expect(score.secondScore, 0);
    });

    test('placar 0x0 no modo homeAway também continua "conhecido"', () {
      final match = _match(
        homeScore: 0,
        awayScore: 0,
        clubScore: 0,
        opponentScore: 0,
      );
      final score = match.score;
      expect(score.mode, PassportScoreMode.homeAway);
      expect(score.isKnown, isTrue);
      expect(score.firstScore, 0);
      expect(score.secondScore, 0);
    });

    test(
      'nenhum dos dois pares completo -> modo unknown, nunca inventa placar',
      () {
        final match = _match();
        final score = match.score;
        expect(score.mode, PassportScoreMode.unknown);
        expect(score.isKnown, isFalse);
        expect(score.firstScore, isNull);
        expect(score.secondScore, isNull);
      },
    );

    test(
      'exceção real do catálogo (hist-f80-0042, Goiás x ABG 1946): sem nenhum placar',
      () {
        final match = _match(
          homeScore: null,
          awayScore: null,
          clubScore: null,
          opponentScore: null,
          clubIsHome: null,
        );
        expect(match.score.isKnown, isFalse);
      },
    );

    test('outcome (vitória/empate/derrota) é independente do modo do placar', () {
      final win = _match(
        clubScore: 4,
        opponentScore: 1,
        outcome: PassportOutcome.win,
      );
      final draw = _match(
        clubScore: 1,
        opponentScore: 1,
        outcome: PassportOutcome.draw,
      );
      final loss = _match(
        clubScore: 0,
        opponentScore: 2,
        outcome: PassportOutcome.loss,
      );
      expect(win.outcome, PassportOutcome.win);
      expect(draw.outcome, PassportOutcome.draw);
      expect(loss.outcome, PassportOutcome.loss);
      // As 3 continuam clubPerspective — outcome não afeta a resolução do placar.
      for (final match in [win, draw, loss]) {
        expect(match.score.mode, PassportScoreMode.clubPerspective);
      }
    });
  });
}
