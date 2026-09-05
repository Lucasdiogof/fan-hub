// M4.4 — achado real: o nível "esmeraldino" do quiz mostrava o texto
// hardcoded "Esmeraldino" pra QUALQUER clube (label era um getter fixo em
// quiz_models.dart). Isso vazaria a identidade do Goiás pro Bragantino
// (ou qualquer clube futuro). Corrigido pra receber o fanDemonym do clube
// ativo — este arquivo prova a correção e a trava de não-regressão.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';

void main() {
  group('QuizDifficulty.label usa o gentílico do clube ativo', () {
    test('Goiás continua mostrando "Esmeraldino" (zero regressão visual)', () {
      final fanDemonym = goiasClubConfig.identity.fanDemonym;
      expect(QuizDifficulty.esmeraldino.label(fanDemonym), 'Esmeraldino');
    });

    test('Bragantino mostra "Massa Bruta", NUNCA "Esmeraldino"', () {
      final fanDemonym = bragantinoClubConfig.identity.fanDemonym;
      final label = QuizDifficulty.esmeraldino.label(fanDemonym);
      expect(label, 'Massa Bruta');
      expect(label.toLowerCase(), isNot(contains('esmeraldino')));
    });

    test(
      'Torcedor/Fanático nunca mudam por clube (só o nível do meio é por gentílico)',
      () {
        for (final fanDemonym in [
          goiasClubConfig.identity.fanDemonym,
          bragantinoClubConfig.identity.fanDemonym,
        ]) {
          expect(QuizDifficulty.torcedor.label(fanDemonym), 'Torcedor');
          expect(QuizDifficulty.fanatico.label(fanDemonym), 'Fanático');
        }
      },
    );
  });

  test(
    'FABRICADO — quizQuestionsFallback nunca tem entrada pro Bragantino '
    '(clube vazio no Supabase precisa lançar, nunca herdar as perguntas do Goiás)',
    () {
      expect(
        quizQuestionsFallback.forClub('bragantino'),
        isNull,
        reason:
            'se existisse fallback pro Bragantino usando a lista do Goiás, '
            'um Supabase vazio mostraria perguntas erradas em vez de dar gap',
      );
      expect(quizQuestionsFallback.forClub('goias'), isNotNull);
    },
  );
}
