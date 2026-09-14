import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_cubit.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';

void main() {
  test('estado inicial começa na pergunta 0, sem nenhuma resposta', () {
    final cubit = TacticalIdentityCubit();
    addTearDown(cubit.close);

    expect(cubit.state.index, 0);
    expect(cubit.state.answered, isFalse);
    expect(cubit.state.allAnswered, isFalse);
    expect(cubit.state.isFirstQuestion, isTrue);
  });

  test('selectOption marca a resposta da pergunta atual', () {
    final cubit = TacticalIdentityCubit();
    addTearDown(cubit.close);
    final option = tacticalIdentityQuestions[0].options.first;

    cubit.selectOption(option);

    expect(cubit.state.answered, isTrue);
    expect(cubit.state.selected, option);
  });

  group('next', () {
    test('sem responder a pergunta atual, não avança', () {
      final cubit = TacticalIdentityCubit();
      addTearDown(cubit.close);

      cubit.next();

      expect(cubit.state.index, 0);
    });

    test('respondida, avança pra próxima pergunta', () {
      final cubit = TacticalIdentityCubit();
      addTearDown(cubit.close);
      cubit.selectOption(tacticalIdentityQuestions[0].options.first);

      cubit.next();

      expect(cubit.state.index, 1);
    });

    test('não avança além da última pergunta', () {
      final cubit = TacticalIdentityCubit();
      addTearDown(cubit.close);
      final lastIndex = tacticalIdentityQuestions.length - 1;
      for (var i = 0; i <= lastIndex; i++) {
        cubit.selectOption(tacticalIdentityQuestions[i].options.first);
        cubit.next();
      }

      expect(cubit.state.index, lastIndex);
    });
  });

  group('back', () {
    test('na primeira pergunta, não faz nada', () {
      final cubit = TacticalIdentityCubit();
      addTearDown(cubit.close);

      cubit.back();

      expect(cubit.state.index, 0);
    });

    test('volta uma pergunta, mantendo a resposta anterior marcada', () {
      final cubit = TacticalIdentityCubit();
      addTearDown(cubit.close);
      final option = tacticalIdentityQuestions[0].options.first;
      cubit
        ..selectOption(option)
        ..next();

      cubit.back();

      expect(cubit.state.index, 0);
      expect(cubit.state.selected, option);
    });
  });

  test('restart zera índice e todas as respostas', () {
    final cubit = TacticalIdentityCubit();
    addTearDown(cubit.close);
    cubit
      ..selectOption(tacticalIdentityQuestions[0].options.first)
      ..next();

    cubit.restart();

    expect(cubit.state.index, 0);
    expect(cubit.state.answered, isFalse);
  });

  test(
    'finalAnswers só fica completo quando todas as perguntas foram respondidas',
    () {
      final cubit = TacticalIdentityCubit();
      addTearDown(cubit.close);

      for (var i = 0; i < tacticalIdentityQuestions.length; i++) {
        cubit.selectOption(tacticalIdentityQuestions[i].options.first);
        if (!cubit.state.isLastQuestion) cubit.next();
      }

      expect(cubit.state.allAnswered, isTrue);
      expect(cubit.finalAnswers.length, tacticalIdentityQuestions.length);
      expect(cubit.finalAnswers, everyElement(isNotNull));
    },
  );
}
