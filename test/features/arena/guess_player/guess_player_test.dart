import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
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
    clubDebutYear: 2020,
    imageUrl: 'lib/assets/squad/x.jpg',
    dataStatus: status,
  );
}

void main() {
  group('GuessPlayer.eligibleAsSecret', () {
    test('true quando os 4 atributos + foto existem e status é verified', () {
      expect(_fullPlayer().eligibleAsSecret, isTrue);
    });

    test('true mesmo sem nacionalidade (não faz mais parte das pistas)', () {
      const player = GuessPlayer(
        id: 'x',
        name: 'X',
        displayName: 'X',
        position: PlayerPosition.ata,
        shirtNumber: 9,
        academyClub: 'Goiás',
        clubDebutYear: 2020,
        imageUrl: 'lib/assets/squad/x.jpg',
        dataStatus: GuessPlayerDataStatus.verified,
      );
      expect(player.eligibleAsSecret, isTrue);
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
        clubDebutYear: 2020,
        dataStatus: GuessPlayerDataStatus.verified,
      );
      expect(player.eligibleAsSecret, isFalse);
    });

    test('false quando falta qualquer um dos 4 atributos', () {
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
          clubDebutYear: base.clubDebutYear,
          imageUrl: base.imageUrl,
          dataStatus: base.dataStatus,
        ).eligibleAsSecret,
        isFalse,
      );
    });

    test('sem clube formador continua elegível (verified + demais pistas + '
        'foto) — BASE só se preenche com fonte explícita', () {
      const player = GuessPlayer(
        id: 'x',
        name: 'X',
        displayName: 'X',
        position: PlayerPosition.ata,
        shirtNumber: 9,
        clubDebutYear: 2020,
        imageUrl: 'lib/assets/squad/x.jpg',
        dataStatus: GuessPlayerDataStatus.verified,
      );
      expect(player.eligibleAsSecret, isTrue);
      expect(player.hasFullHints, isTrue);
    });

    test('sem clube formador e pré-2008 sem camisa: elegível', () {
      const player = GuessPlayer(
        id: 'x',
        name: 'X',
        displayName: 'X',
        position: PlayerPosition.vol,
        clubDebutYear: 1987,
        imageUrl: 'lib/assets/x.png',
        dataStatus: GuessPlayerDataStatus.verified,
      );
      expect(player.eligibleAsSecret, isTrue);
    });

    test('sem clube formador não vira elegível se não for verified', () {
      const player = GuessPlayer(
        id: 'x',
        name: 'X',
        displayName: 'X',
        position: PlayerPosition.ata,
        shirtNumber: 9,
        clubDebutYear: 2020,
        imageUrl: 'lib/assets/squad/x.jpg',
        dataStatus: GuessPlayerDataStatus.incomplete,
      );
      expect(player.eligibleAsSecret, isFalse);
    });

    GuessPlayer withoutShirt(int? debut) => GuessPlayer(
      id: 'h',
      name: 'H',
      displayName: 'H',
      position: PlayerPosition.zag,
      academyClub: 'Goiás',
      clubDebutYear: debut,
      imageUrl: 'lib/assets/x.png',
      dataStatus: GuessPlayerDataStatus.verified,
    );

    test('camisa vazia não impede o sorteio de quem estreou antes de 2008 '
        '(não há registro de camisa dessa época)', () {
      expect(withoutShirt(1990).eligibleAsSecret, isTrue);
      expect(withoutShirt(2007).eligibleAsSecret, isTrue);
    });

    test('a partir de 2008 (ou sem ano de estreia) a camisa continua '
        'obrigatória', () {
      expect(withoutShirt(2008).eligibleAsSecret, isFalse);
      expect(withoutShirt(2020).eligibleAsSecret, isFalse);
      expect(withoutShirt(null).eligibleAsSecret, isFalse);
    });

    test('camisa vazia do secreto deixa a pista de camisa como desconhecida, '
        'sem acusar acerto nem erro', () {
      expect(compareShirtNumber(null, 9), DirectionalResult.unknown);
    });
  });

  group('GuessPlayer.hasFullHints (filtro do autocomplete)', () {
    GuessPlayer hints({
      PlayerPosition? position = PlayerPosition.ld,
      int? shirt = 2,
      String? academy,
      int? debut = 2015,
    }) => GuessPlayer(
      id: 'h',
      name: 'H',
      displayName: 'H',
      position: position,
      shirtNumber: shirt,
      academyClub: academy,
      clubDebutYear: debut,
      dataStatus: GuessPlayerDataStatus.incomplete,
    );

    test('não depende de clube formador', () {
      expect(hints(academy: 'Goiás').hasFullHints, isTrue);
      expect(hints().hasFullHints, isTrue);
    });

    test('continua exigindo posição e estreia', () {
      expect(hints(position: null).hasFullHints, isFalse);
      expect(hints(debut: null).hasFullHints, isFalse);
    });

    test('camisa segue a regra de 2008', () {
      expect(hints(shirt: null, debut: 2007).hasFullHints, isTrue);
      expect(hints(shirt: null, debut: 2008).hasFullHints, isFalse);
      expect(hints(shirt: null, debut: null).hasFullHints, isFalse);
    });

    test('todo elegível como secreto também aparece como opção de palpite '
        '(senão a rodada fica impossível de acertar)', () {
      for (final debut in [1970, 2007, 2008, 2024]) {
        for (final shirt in [null, 10]) {
          for (final academy in [null, 'Goiás']) {
            final player = GuessPlayer(
              id: 'p',
              name: 'P',
              displayName: 'P',
              position: PlayerPosition.mei,
              shirtNumber: shirt,
              academyClub: academy,
              clubDebutYear: debut,
              imageUrl: 'lib/assets/x.png',
              dataStatus: GuessPlayerDataStatus.verified,
            );
            if (player.eligibleAsSecret) {
              expect(player.hasFullHints, isTrue, reason: '$debut/$shirt');
            }
          }
        }
      }
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
