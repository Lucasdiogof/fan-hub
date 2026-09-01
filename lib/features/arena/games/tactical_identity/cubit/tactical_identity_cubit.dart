import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_state.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Governa só a NAVEGAÇÃO e a coleta de respostas do questionário — nunca
/// calcula eixo/arquétipo/técnico aqui dentro (isso é
/// `TacticalIdentityEngine`, chamado só quando as 10 respostas já existem,
/// ver `finalAnswers`). Nenhuma chamada a ranking/pontuação/XP/streak: este
/// jogo não participa de nada disso.
class TacticalIdentityCubit extends Cubit<TacticalIdentityState> {
  TacticalIdentityCubit() : super(TacticalIdentityState());

  void selectOption(TacticalOption option) {
    final answers = [...state.answers];
    answers[state.index] = option;
    emit(state.copyWith(answers: answers));
  }

  void next() {
    if (!state.answered || state.isLastQuestion) return;
    emit(state.copyWith(index: state.index + 1));
  }

  /// A alternativa escolhida anteriormente continua marcada — nunca reseta
  /// ao voltar, pra o usuário poder revisar/trocar sem perder o que já
  /// tinha escolhido.
  void back() {
    if (state.isFirstQuestion) return;
    emit(state.copyWith(index: state.index - 1));
  }

  void restart() => emit(TacticalIdentityState());

  /// As 10 respostas em ordem, prontas pro `TacticalIdentityEngine` — só
  /// deve ser lida quando `state.allAnswered` é `true` (a última pergunta
  /// só libera "Ver resultado" nesse ponto).
  List<TacticalOption> get finalAnswers => state.answers.cast<TacticalOption>();
}
