import 'package:equatable/equatable.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';

class QuizState extends Equatable {
  const QuizState({
    required this.questions,
    this.index = 0,
    this.selected,
    this.correctCount = 0,
    this.best = 0,
    this.finished = false,
    this.isNewRecord = false,
  });

  final List<QuizQuestion> questions;
  final int index;
  final int? selected;
  final int correctCount;
  final int best;
  final bool finished;
  final bool isNewRecord;

  QuizQuestion get currentQuestion => questions[index];
  bool get isLastQuestion => index == questions.length - 1;
  bool get answered => selected != null;

  QuizState copyWith({
    int? index,
    int? selected,
    bool clearSelected = false,
    int? correctCount,
    int? best,
    bool? finished,
    bool? isNewRecord,
  }) {
    return QuizState(
      questions: questions,
      index: index ?? this.index,
      selected: clearSelected ? null : (selected ?? this.selected),
      correctCount: correctCount ?? this.correctCount,
      best: best ?? this.best,
      finished: finished ?? this.finished,
      isNewRecord: isNewRecord ?? this.isNewRecord,
    );
  }

  @override
  List<Object?> get props => [questions, index, selected, correctCount, best, finished, isNewRecord];
}
