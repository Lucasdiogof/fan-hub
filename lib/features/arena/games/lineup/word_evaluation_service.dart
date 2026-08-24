import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';

const Map<String, String> _accentFolding = {
  'Á': 'A',
  'À': 'A',
  'Ã': 'A',
  'Â': 'A',
  'Ä': 'A',
  'É': 'E',
  'È': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Í': 'I',
  'Ì': 'I',
  'Î': 'I',
  'Ï': 'I',
  'Ó': 'O',
  'Ò': 'O',
  'Õ': 'O',
  'Ô': 'O',
  'Ö': 'O',
  'Ú': 'U',
  'Ù': 'U',
  'Û': 'U',
  'Ü': 'U',
  'Ç': 'C',
};

/// Lógica pura do mini-Wordle — sem Flutter, sem estado, só funções. O
/// Cubit chama isto, nunca o widget diretamente.
class WordEvaluationService {
  const WordEvaluationService._();

  /// Maiúsculo, sem acento, e sem espaço/hífen/apóstrofo — é essa forma que
  /// vira a sequência de casas da grade e o que é comparado letra a letra.
  /// A grafia original continua livre pra exibição (nome do jogador,
  /// `puzzleAnswer` como está no dataset).
  static String normalize(String raw) {
    final upper = raw.toUpperCase();
    final buffer = StringBuffer();
    for (final char in upper.split('')) {
      if (char == ' ' || char == '-' || char == "'" || char == '’') continue;
      buffer.write(_accentFolding[char] ?? char);
    }
    return buffer.toString();
  }

  /// Avalia uma tentativa já normalizada (só A–Z, mesmo comprimento da
  /// resposta) contra a resposta normalizada, no algoritmo de duas
  /// passagens do Wordle — nunca `answer.contains(letter)`, que erra com
  /// letras repetidas.
  static List<LetterStatus> evaluate({
    required String normalizedAnswer,
    required String normalizedGuess,
  }) {
    assert(
      normalizedAnswer.length == normalizedGuess.length,
      'guess e answer precisam ter o mesmo comprimento',
    );

    final length = normalizedAnswer.length;
    final statuses = List<LetterStatus>.filled(length, LetterStatus.absent);

    // Contagem de ocorrências ainda "disponíveis" na resposta pra cada
    // letra — decrementada conforme vai sendo consumida pelas duas
    // passagens, pra nunca marcar mais ocorrências verdes/amarelas do que
    // realmente existem na resposta.
    final available = <String, int>{};
    for (final letter in normalizedAnswer.split('')) {
      available[letter] = (available[letter] ?? 0) + 1;
    }

    // Primeira passagem: só posições exatas, consumindo a ocorrência.
    for (var i = 0; i < length; i++) {
      if (normalizedGuess[i] == normalizedAnswer[i]) {
        statuses[i] = LetterStatus.correct;
        available[normalizedGuess[i]] = available[normalizedGuess[i]]! - 1;
      }
    }

    // Segunda passagem: o que sobrou, só entra amarelo se ainda houver
    // ocorrência disponível daquela letra.
    for (var i = 0; i < length; i++) {
      if (statuses[i] == LetterStatus.correct) continue;
      final letter = normalizedGuess[i];
      final left = available[letter] ?? 0;
      if (left > 0) {
        statuses[i] = LetterStatus.present;
        available[letter] = left - 1;
      }
    }

    return statuses;
  }

  /// Funde o resultado de uma nova tentativa no estado acumulado do
  /// teclado — prioridade correct > present > absent, uma tecla nunca
  /// regride pro que já foi visto de melhor pra ela.
  static Map<String, LetterStatus> mergeKeyboardState({
    required Map<String, LetterStatus> previous,
    required String normalizedGuess,
    required List<LetterStatus> statuses,
  }) {
    final merged = Map<String, LetterStatus>.of(previous);
    for (var i = 0; i < normalizedGuess.length; i++) {
      final letter = normalizedGuess[i];
      final incoming = statuses[i];
      final current = merged[letter];
      if (current == null || _rank(incoming) > _rank(current)) {
        merged[letter] = incoming;
      }
    }
    return merged;
  }

  static int _rank(LetterStatus status) => switch (status) {
    LetterStatus.absent => 0,
    LetterStatus.present => 1,
    LetterStatus.correct => 2,
  };
}
