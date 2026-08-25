import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/shared/domain/player_position.dart';

GuessPlayer _fullPlayer({
  GuessPlayerDataStatus status = GuessPlayerDataStatus.verified,
}) {
  return GuessPlayer(
    id: 'x',
    name: 'X',
    displayName: 'X',
    position: PlayerPosition.ata,
    shirtNumber: 9,
    academyClub: 'Goiás',
    nationalityCode: 'BR',
    nationalityName: 'Brasil',
    goiasDebutYear: 2020,
    imageUrl: 'lib/assets/squad/x.jpg',
    dataStatus: status,
  );
}

void main() {
  group('GuessPlayer.eligibleAsSecret', () {
    test('true quando os 5 atributos + foto existem e status é verified', () {
      expect(_fullPlayer().eligibleAsSecret, isTrue);
    });

    test('false quando status não é verified, mesmo com todos os dados', () {
      expect(
        _fullPlayer(status: GuessPlayerDataStatus.review).eligibleAsSecret,
        isFalse,
      );
      expect(
        _fullPlayer(status: GuessPlayerDataStatus.incomplete).eligibleAsSecret,
        isFalse,
      );
    });

    test('false quando falta imageUrl', () {
      const player = GuessPlayer(
        id: 'x',
        name: 'X',
        displayName: 'X',
        position: PlayerPosition.ata,
        shirtNumber: 9,
        academyClub: 'Goiás',
        nationalityCode: 'BR',
        nationalityName: 'Brasil',
        goiasDebutYear: 2020,
        dataStatus: GuessPlayerDataStatus.verified,
      );
      expect(player.eligibleAsSecret, isFalse);
    });

    test('false quando falta qualquer um dos 5 atributos', () {
      final base = _fullPlayer();
      expect(
        GuessPlayer(
          id: base.id,
          name: base.name,
          displayName: base.displayName,
          shirtNumber: base.shirtNumber,
          academyClub: base.academyClub,
          nationalityCode: base.nationalityCode,
          nationalityName: base.nationalityName,
          goiasDebutYear: base.goiasDebutYear,
          imageUrl: base.imageUrl,
          dataStatus: base.dataStatus,
        ).eligibleAsSecret,
        isFalse,
      );
    });
  });

  group('GuessPlayerRoundState', () {
    test('blurSigma segue os níveis por tentativa usada', () {
      const round = GuessPlayerRoundState(secretPlayerId: 'x');
      expect(round.blurSigma, blurLevelsByAttempt[0]);

      final afterTwo = round.copyWith(guessedPlayerIds: ['a', 'b']);
      expect(afterTwo.blurSigma, blurLevelsByAttempt[2]);
    });

    test('blurSigma é 0 quando venceu, independente da tentativa', () {
      const round = GuessPlayerRoundState(
        secretPlayerId: 'x',
        guessedPlayerIds: ['a'],
        won: true,
      );
      expect(round.blurSigma, 0);
    });

    test('attemptsRemaining conta corretamente até o máximo', () {
      const round = GuessPlayerRoundState(secretPlayerId: 'x');
      expect(round.attemptsRemaining, maxGuessAttempts);

      final afterThree = round.copyWith(guessedPlayerIds: ['a', 'b', 'c']);
      expect(afterThree.attemptsRemaining, maxGuessAttempts - 3);
    });

    test('isOver é true quando ganhou ou perdeu', () {
      const round = GuessPlayerRoundState(secretPlayerId: 'x');
      expect(round.isOver, isFalse);
      expect(round.copyWith(won: true).isOver, isTrue);
      expect(round.copyWith(lost: true).isOver, isTrue);
    });

    test('toJson/fromJson faz round-trip sem perda', () {
      const round = GuessPlayerRoundState(
        secretPlayerId: 'x',
        guessedPlayerIds: ['a', 'b'],
        won: false,
        lost: false,
      );
      final restored = GuessPlayerRoundState.fromJson(round.toJson());
      expect(restored.secretPlayerId, round.secretPlayerId);
      expect(restored.guessedPlayerIds, round.guessedPlayerIds);
      expect(restored.won, round.won);
      expect(restored.lost, round.lost);
    });
  });
}
