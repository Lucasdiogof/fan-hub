import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_state.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// Governa só a NAVEGAÇÃO e a coleta de respostas do questionário — nunca
/// calcula atributo/arquétipo/jogador aqui dentro (isso é
/// `PlayerIdentityEngine`, chamado só quando as 10 respostas já existem,
/// ver `finalAnswers`). Nenhuma chamada a ranking/pontuação/XP/streak: este
/// jogo não participa de nada disso.
class PlayerIdentityCubit extends Cubit<PlayerIdentityState> {
  PlayerIdentityCubit() : super(PlayerIdentityState());

  void selectOption(PlayerIdentityOption option) {
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

  void restart() => emit(PlayerIdentityState());

  /// As 10 respostas em ordem, prontas pro `PlayerIdentityEngine` — só deve
  /// ser lida quando `state.allAnswered` é `true` (a última pergunta só
  /// libera "Ver resultado" nesse ponto).
  List<PlayerIdentityOption> get finalAnswers =>
      state.answers.cast<PlayerIdentityOption>();
}
