import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/word_evaluation_service.dart';

void main() {
  group('WordEvaluationService.normalize', () {
    test('remove acentos comuns', () {
      expect(WordEvaluationService.normalize('TOLÓI'), 'TOLOI');
      expect(WordEvaluationService.normalize('VIÇOSA'), 'VICOSA');
      expect(WordEvaluationService.normalize('GÊGÊ'), 'GEGE');
    });

    test('ignora maiúsculas/minúsculas', () {
      expect(WordEvaluationService.normalize('moura'), 'MOURA');
      expect(WordEvaluationService.normalize('MoUrA'), 'MOURA');
    });

    test('ignora espaços', () {
      expect(
        WordEvaluationService.normalize('CARLOS ALBERTO'),
        'CARLOSALBERTO',
      );
    });

    test('ignora hífen', () {
      expect(WordEvaluationService.normalize('JEAN-PIERRE'), 'JEANPIERRE');
    });

    test('ignora apóstrofo', () {
      expect(WordEvaluationService.normalize("D'ANGELO"), 'DANGELO');
      expect(WordEvaluationService.normalize('D’ANGELO'), 'DANGELO');
    });
  });

  group('WordEvaluationService.evaluate', () {
    test('todas as letras corretas ficam correct', () {
      final result = WordEvaluationService.evaluate(
        normalizedAnswer: 'MOURA',
        normalizedGuess: 'MOURA',
      );
      expect(result, List.filled(5, LetterStatus.correct));
    });

    test('letra ausente fica absent', () {
      final result = WordEvaluationService.evaluate(
        normalizedAnswer: 'MOURA',
        normalizedGuess: 'PLANO',
      );
      // P,L,N não existem em MOURA; O existe mas na posição errada; A existe
      // na posição errada.
      expect(result[0], LetterStatus.absent); // P
      expect(result[1], LetterStatus.absent); // L
      expect(result[2], LetterStatus.present); // A -> existe, posição errada
      expect(result[3], LetterStatus.absent); // N
      expect(result[4], LetterStatus.present); // O -> existe, posição errada
    });

    test(
      'letra repetida na tentativa não pode ficar amarela/verde além da quantidade real na resposta '
      '(MOURA vs MORRO)',
      () {
        // MOURA: M O U R A — só um R, só um O.
        // MORRO: M O R R O — dois R, dois O.
        final result = WordEvaluationService.evaluate(
          normalizedAnswer: 'MOURA',
          normalizedGuess: 'MORRO',
        );
        expect(result[0], LetterStatus.correct); // M
        expect(result[1], LetterStatus.correct); // O (mesma posição do único O)
        expect(
          result[2],
          LetterStatus.absent,
        ); // R — o único R da resposta já foi
        // consumido pelo match exato no índice 3, não sobra R pra este ficar
        // amarelo.
        expect(result[3], LetterStatus.correct); // R (mesma posição do único R)
        expect(
          result[4],
          LetterStatus.absent,
        ); // O — o único O já foi consumido
        // pelo match exato no índice 1.
      },
    );

    test(
      'caso clássico de letra repetida sem nenhum acerto de posição (SPEED vs ERASE)',
      () {
        // SPEED tem duas letras E; ERASE também tem duas letras E — as duas
        // devem ficar amarelas (nenhuma está na posição certa), não mais que
        // isso.
        final result = WordEvaluationService.evaluate(
          normalizedAnswer: 'SPEED',
          normalizedGuess: 'ERASE',
        );
        expect(result, [
          LetterStatus.present, // E
          LetterStatus.absent, // R
          LetterStatus.absent, // A
          LetterStatus.present, // S
          LetterStatus.present, // E
        ]);
      },
    );

    test(
      'resposta com uma letra repetida e tentativa com três ocorrências só acerta o que existe de verdade',
      () {
        // Resposta com um único A; tentativa com três A's — só pode haver,
        // no total, tantos verdes+amarelos de A quanto existem na resposta.
        const answer =
            'CARTA'; // C A R T A -> na verdade tem 2 A's, ajuste abaixo
        final result = WordEvaluationService.evaluate(
          normalizedAnswer: answer,
          normalizedGuess: 'AAAAA',
        );
        final aCount = result.where((s) => s != LetterStatus.absent).length;
        // CARTA tem exatamente 2 letras A — no máximo 2 das 5 posições podem
        // não ser absent, nunca as 5.
        expect(aCount, 2);
      },
    );
  });

  group('WordEvaluationService.mergeKeyboardState', () {
    test('prioridade correct > present > absent — uma tecla nunca regride', () {
      var keyboard = <String, LetterStatus>{};

      // Primeira tentativa: R fica correct.
      keyboard = WordEvaluationService.mergeKeyboardState(
        previous: keyboard,
        normalizedGuess: 'MOURA',
        statuses: [
          LetterStatus.correct,
          LetterStatus.correct,
          LetterStatus.correct,
          LetterStatus.correct,
          LetterStatus.correct,
        ],
      );
      expect(keyboard['R'], LetterStatus.correct);

      // Segunda tentativa: R aparece como absent em outra posição — não
      // pode rebaixar o que já sabíamos.
      keyboard = WordEvaluationService.mergeKeyboardState(
        previous: keyboard,
        normalizedGuess: 'PARTE',
        statuses: [
          LetterStatus.absent,
          LetterStatus.absent,
          LetterStatus.absent,
          LetterStatus.absent,
          LetterStatus.absent,
        ],
      );
      expect(keyboard['R'], LetterStatus.correct);
    });

    test('present nunca regride pra absent', () {
      var keyboard = <String, LetterStatus>{};
      keyboard = WordEvaluationService.mergeKeyboardState(
        previous: keyboard,
        normalizedGuess: 'A',
        statuses: [LetterStatus.present],
      );
      keyboard = WordEvaluationService.mergeKeyboardState(
        previous: keyboard,
        normalizedGuess: 'A',
        statuses: [LetterStatus.absent],
      );
      expect(keyboard['A'], LetterStatus.present);
    });

    test('present pode evoluir pra correct', () {
      var keyboard = <String, LetterStatus>{};
      keyboard = WordEvaluationService.mergeKeyboardState(
        previous: keyboard,
        normalizedGuess: 'A',
        statuses: [LetterStatus.present],
      );
      keyboard = WordEvaluationService.mergeKeyboardState(
        previous: keyboard,
        normalizedGuess: 'A',
        statuses: [LetterStatus.correct],
      );
      expect(keyboard['A'], LetterStatus.correct);
    });
  });
}
