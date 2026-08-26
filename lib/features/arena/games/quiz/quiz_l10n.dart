import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Descrição de cada nível do quiz, resolvida por dificuldade — o conteúdo
/// (const `_levels`) segue guardando ícone/gradiente; o texto vem daqui.
String quizLevelTagline(AppLocalizations l10n, QuizDifficulty difficulty) =>
    switch (difficulty) {
      QuizDifficulty.torcedor => l10n.quizLevelDescTorcedor,
      QuizDifficulty.esmeraldino => l10n.quizLevelDescEsmeraldino,
      QuizDifficulty.fanatico => l10n.quizLevelDescFanatico,
    };
