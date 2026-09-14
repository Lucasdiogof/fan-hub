import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_cubit.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';

void main() {
  test('estado inicial começa na pergunta 0, sem nenhuma resposta', () {
    final cubit = PlayerIdentityCubit();
    addTearDown(cubit.close);

    expect(cubit.state.index, 0);
    expect(cubit.state.answered, isFalse);
    expect(cubit.state.allAnswered, isFalse);
    expect(cubit.state.isFirstQuestion, isTrue);
  });

  test('selectOption marca a resposta da pergunta atual', () {
    final cubit = PlayerIdentityCubit();
    addTearDown(cubit.close);
    final option = playerIdentityQuestions[0].options.first;

    cubit.selectOption(option);

    expect(cubit.state.answered, isTrue);
    expect(cubit.state.selected, option);
  });

  group('next', () {
    test('sem responder a pergunta atual, não avança', () {
      final cubit = PlayerIdentityCubit();
      addTearDown(cubit.close);

      cubit.next();

      expect(cubit.state.index, 0);
    });

    test('respondida, avança pra próxima pergunta', () {
      final cubit = PlayerIdentityCubit();
      addTearDown(cubit.close);
      cubit.selectOption(playerIdentityQuestions[0].options.first);

      cubit.next();

      expect(cubit.state.index, 1);
    });

    test('não avança além da última pergunta', () {
      final cubit = PlayerIdentityCubit();
      addTearDown(cubit.close);
      final lastIndex = playerIdentityQuestions.length - 1;
      for (var i = 0; i <= lastIndex; i++) {
        cubit.selectOption(playerIdentityQuestions[i].options.first);
        cubit.next();
      }

      expect(cubit.state.index, lastIndex);
    });
  });

  group('back', () {
    test('na primeira pergunta, não faz nada', () {
      final cubit = PlayerIdentityCubit();
      addTearDown(cubit.close);

      cubit.back();

      expect(cubit.state.index, 0);
    });

    test('volta uma pergunta, mantendo a resposta anterior marcada', () {
      final cubit = PlayerIdentityCubit();
      addTearDown(cubit.close);
      final option = playerIdentityQuestions[0].options.first;
      cubit
        ..selectOption(option)
        ..next();

      cubit.back();

      expect(cubit.state.index, 0);
      expect(cubit.state.selected, option);
    });
  });

  test('restart zera índice e todas as respostas', () {
    final cubit = PlayerIdentityCubit();
    addTearDown(cubit.close);
    cubit
      ..selectOption(playerIdentityQuestions[0].options.first)
      ..next();

    cubit.restart();

    expect(cubit.state.index, 0);
    expect(cubit.state.answered, isFalse);
  });

  test(
    'finalAnswers só fica completo quando todas as perguntas foram respondidas',
    () {
      final cubit = PlayerIdentityCubit();
      addTearDown(cubit.close);

      for (var i = 0; i < playerIdentityQuestions.length; i++) {
        cubit.selectOption(playerIdentityQuestions[i].options.first);
        if (!cubit.state.isLastQuestion) cubit.next();
      }

      expect(cubit.state.allAnswered, isTrue);
      expect(cubit.finalAnswers.length, playerIdentityQuestions.length);
      expect(cubit.finalAnswers, everyElement(isNotNull));
    },
  );
}
