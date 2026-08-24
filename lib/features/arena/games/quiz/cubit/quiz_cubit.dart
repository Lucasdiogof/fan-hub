import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_state.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';

class QuizCubit extends Cubit<QuizState> {
  QuizCubit({required this.difficulty, this.avoid = const {}, required this.loadBest, required this.saveBest})
    : super(QuizState(questions: pickQuizQuestions(difficulty, avoid: avoid))) {
    _init();
  }

  final QuizDifficulty difficulty;
  final Set<String> avoid;
  final Future<int> Function() loadBest;
  final Future<void> Function(int score) saveBest;

  Future<void> _init() async {
    final best = await loadBest();
    emit(state.copyWith(best: best));
  }

  void selectAnswer(int optionIndex) {
    if (state.answered) return;
    final isCorrect = optionIndex == state.currentQuestion.correctIndex;
    emit(state.copyWith(selected: optionIndex, correctCount: state.correctCount + (isCorrect ? 1 : 0)));
  }

  Future<void> next() async {
    if (!state.answered) return;
    if (state.isLastQuestion) {
      final score = quizScore(state.correctCount);
      final isNewRecord = score > state.best;
      if (isNewRecord) await saveBest(score);
      emit(state.copyWith(finished: true, best: isNewRecord ? score : state.best, isNewRecord: isNewRecord));
      return;
    }
    emit(state.copyWith(index: state.index + 1, clearSelected: true));
  }
}
