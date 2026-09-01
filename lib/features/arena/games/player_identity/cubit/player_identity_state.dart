import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';

/// [answers] é a ÚNICA fonte da verdade da sessão — uma posição por
/// pergunta (`null` = ainda não respondida). Nunca um placar incremental:
/// voltar e escolher outra alternativa só sobrescreve a posição, o
/// resultado final sempre é recalculado percorrendo esta lista inteira.
class PlayerIdentityState {
  PlayerIdentityState({this.index = 0, List<PlayerIdentityOption?>? answers})
    : answers =
          answers ??
          List<PlayerIdentityOption?>.filled(
            playerIdentityQuestions.length,
            null,
          );

  final int index;
  final List<PlayerIdentityOption?> answers;

  PlayerIdentityQuestion get currentQuestion => playerIdentityQuestions[index];
  PlayerIdentityOption? get selected => answers[index];
  bool get answered => selected != null;
  bool get isFirstQuestion => index == 0;
  bool get isLastQuestion => index == playerIdentityQuestions.length - 1;
  bool get allAnswered => answers.every((option) => option != null);

  PlayerIdentityState copyWith({
    int? index,
    List<PlayerIdentityOption?>? answers,
  }) => PlayerIdentityState(
    index: index ?? this.index,
    answers: answers ?? this.answers,
  );
}
