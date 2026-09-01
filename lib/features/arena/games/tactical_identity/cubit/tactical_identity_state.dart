import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';

/// [answers] é a ÚNICA fonte da verdade da sessão — uma posição por
/// pergunta (`null` = ainda não respondida). Nunca um placar incremental:
/// voltar e escolher outra alternativa só sobrescreve a posição, o
/// resultado final sempre é recalculado percorrendo esta lista inteira.
class TacticalIdentityState {
  TacticalIdentityState({
    this.index = 0,
    List<TacticalOption?>? answers,
  }) : answers =
           answers ??
           List<TacticalOption?>.filled(
             tacticalIdentityQuestions.length,
             null,
           );

  final int index;
  final List<TacticalOption?> answers;

  TacticalQuestion get currentQuestion => tacticalIdentityQuestions[index];
  TacticalOption? get selected => answers[index];
  bool get answered => selected != null;
  bool get isFirstQuestion => index == 0;
  bool get isLastQuestion => index == tacticalIdentityQuestions.length - 1;
  bool get allAnswered => answers.every((option) => option != null);

  TacticalIdentityState copyWith({
    int? index,
    List<TacticalOption?>? answers,
  }) => TacticalIdentityState(
    index: index ?? this.index,
    answers: answers ?? this.answers,
  );
}
