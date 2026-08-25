import 'package:equatable/equatable.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/shared/state/load_status.dart';

class QuizState extends Equatable {
  const QuizState({
    this.status = LoadStatus.initial,
    this.questions = const [],
    this.index = 0,
    this.selected,
    this.correctCount = 0,
    this.answersSoFar = const [],
    this.isReview = false,
    this.levelTotal = 0,
    this.levelAnsweredBefore = 0,
    this.best = 0,
    this.finished = false,
    this.isNewRecord = false,
    this.justCompletedLevel = false,
    this.levelAnsweredAfter = 0,
  });

  final LoadStatus status;
  final List<QuizQuestion> questions;
  final int index;
  final int? selected;
  final int correctCount;

  /// Espelha `quiz_active_session.answers` — só o necessário pra retomar
  /// (id da pergunta + se acertou), persistido a cada resposta dada.
  final List<Map<String, dynamic>> answersSoFar;
  final bool isReview;

  /// Total de perguntas do nível (não da sessão) — usado só pra saber se
  /// essa sessão terminou de completar o nível (`justCompletedLevel`).
  final int levelTotal;

  /// Quantas do nível já estavam respondidas ANTES desta sessão começar —
  /// distingue "completou agora" de "já estava 100%, isto é um replay",
  /// que senão disparariam a mesma celebração de conclusão toda vez.
  final int levelAnsweredBefore;
  final int best;
  final bool finished;
  final bool isNewRecord;

  /// true só quando esta sessão (não-revisão) respondeu a última pergunta
  /// inédita do nível — dispara a experiência de conclusão.
  final bool justCompletedLevel;
  final int levelAnsweredAfter;

  QuizQuestion get currentQuestion => questions[index];
  bool get isLastQuestion => index == questions.length - 1;
  bool get answered => selected != null;

  QuizState copyWith({
    LoadStatus? status,
    List<QuizQuestion>? questions,
    int? index,
    int? selected,
    bool clearSelected = false,
    int? correctCount,
    List<Map<String, dynamic>>? answersSoFar,
    bool? isReview,
    int? levelTotal,
    int? levelAnsweredBefore,
    int? best,
    bool? finished,
    bool? isNewRecord,
    bool? justCompletedLevel,
    int? levelAnsweredAfter,
  }) {
    return QuizState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      index: index ?? this.index,
      selected: clearSelected ? null : (selected ?? this.selected),
      correctCount: correctCount ?? this.correctCount,
      answersSoFar: answersSoFar ?? this.answersSoFar,
      isReview: isReview ?? this.isReview,
      levelTotal: levelTotal ?? this.levelTotal,
      levelAnsweredBefore: levelAnsweredBefore ?? this.levelAnsweredBefore,
      best: best ?? this.best,
      finished: finished ?? this.finished,
      isNewRecord: isNewRecord ?? this.isNewRecord,
      justCompletedLevel: justCompletedLevel ?? this.justCompletedLevel,
      levelAnsweredAfter: levelAnsweredAfter ?? this.levelAnsweredAfter,
    );
  }

  @override
  List<Object?> get props => [
    status,
    questions,
    index,
    selected,
    correctCount,
    answersSoFar,
    isReview,
    levelTotal,
    levelAnsweredBefore,
    best,
    finished,
    isNewRecord,
    justCompletedLevel,
    levelAnsweredAfter,
  ];
}
