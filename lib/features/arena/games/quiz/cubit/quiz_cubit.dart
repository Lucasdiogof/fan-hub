import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_state.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/shared/state/load_status.dart';

class QuizCubit extends Cubit<QuizState> {
  /// `init()` é chamado explicitamente por quem cria o Cubit (nunca aqui
  /// no construtor) — pra nunca disparar duas buscas concorrentes quando
  /// o carregamento já acontece antes da navegação (ver `GlobalLoading.run`
  /// no ponto de entrada, `quiz_level_page.dart`).
  QuizCubit({
    required this.difficulty,
    required this.isReview,
    required this.repository,
    required this.questionsRepository,
    required this.loadBest,
    required this.saveBest,
    required this.ranking,
  }) : super(const QuizState());

  final QuizDifficulty difficulty;
  final bool isReview;
  final QuizProgressRepository repository;
  final QuizQuestionRepository questionsRepository;
  final Future<int> Function() loadBest;
  final Future<void> Function(int score) saveBest;
  final ArenaRankingRepository ranking;

  Future<void> init() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final bank = await questionsRepository.load();
    final best = await loadBest();
    final levelTotal = questionsForLevel(bank, difficulty).length;

    final answeredBefore = (await repository.getAnsweredIds(difficulty)).length;

    // Revisão nunca retoma uma sessão congelada — o que falta revisar é
    // sempre recalculado do zero a partir do que está pendente agora. Uma
    // sessão de revisão abandonada no meio (voltou antes de terminar) já
    // gravou os acertos/erros individuais no progresso; retomar a lista
    // antiga faria a contagem "restante" divergir do "X para revisar" que
    // aparece no resto do app (que é sempre ao vivo).
    final session = isReview ? null : await repository.loadSession(difficulty);
    if (session != null &&
        session.isReview == isReview &&
        session.questionIds.isNotEmpty) {
      final questions = session.questionIds
          .map((id) => bank.firstWhere((question) => question.id == id))
          .map(shuffleOptions)
          .toList();
      emit(
        state.copyWith(
          status: LoadStatus.success,
          questions: questions,
          index: session.currentIndex,
          correctCount: session.correctCount,
          isReview: isReview,
          levelTotal: levelTotal,
          levelAnsweredBefore: answeredBefore,
          best: best,
        ),
      );
      return;
    }

    final List<QuizQuestion> questions;
    if (isReview) {
      final pending = await repository.getPendingReviewIds(difficulty);
      questions = pickReviewQuestions(
        bank,
        difficulty,
        pendingReviewIds: pending,
      );
    } else {
      final answered = await repository.getAnsweredIds(difficulty);
      questions = pickSessionQuestions(bank, difficulty, answeredIds: answered);
    }

    if (questions.isEmpty) {
      // Só acontece se a revisão foi aberta sem nada pendente (a UI já não
      // deveria oferecer essa opção nesse caso) — mostra vazio em vez de
      // quebrar com índice fora do range.
      emit(
        state.copyWith(
          status: LoadStatus.empty,
          levelTotal: levelTotal,
          best: best,
        ),
      );
      return;
    }

    if (!isReview) {
      await repository.saveSession(
        difficulty: difficulty,
        questionIds: questions.map((question) => question.id).toList(),
        currentIndex: 0,
        answers: const [],
        isReview: isReview,
      );
    }

    emit(
      state.copyWith(
        status: LoadStatus.success,
        questions: questions,
        index: 0,
        correctCount: 0,
        answersSoFar: const [],
        isReview: isReview,
        levelTotal: levelTotal,
        levelAnsweredBefore: answeredBefore,
        best: best,
      ),
    );
  }

  void selectAnswer(int optionIndex) {
    if (state.answered) return;
    final isCorrect = optionIndex == state.currentQuestion.correctIndex;
    emit(
      state.copyWith(
        selected: optionIndex,
        correctCount: state.correctCount + (isCorrect ? 1 : 0),
      ),
    );
  }

  Future<void> next() async {
    if (!state.answered) return;
    final question = state.currentQuestion;
    final wasCorrect = state.selected == question.correctIndex;

    await repository.recordAnswer(
      questionId: question.id,
      difficulty: difficulty,
      wasCorrect: wasCorrect,
    );
    unawaited(
      ranking.recordScore(
        gameId: ArenaGameIds.quiz,
        itemId: question.id,
        eventType: wasCorrect
            ? (isReview ? 'review_correct' : 'first_try_correct')
            : 'wrong_answer',
        difficulty: difficulty.name,
      ),
    );
    final answersSoFar = [
      ...state.answersSoFar,
      {'questionId': question.id, 'correct': wasCorrect},
    ];

    if (state.isLastQuestion) {
      await repository.clearSession(difficulty);
      final score = quizScore(state.correctCount);
      final isNewRecord = score > state.best;
      if (isNewRecord) await saveBest(score);

      final answeredAfter = isReview
          ? state.levelAnsweredBefore
          : (await repository.getAnsweredIds(difficulty)).length;
      // Só "acabou de completar" se ANTES desta sessão ainda faltava
      // conteúdo e agora não falta mais — replay (que já começa 100%) nunca
      // dispara a celebração de novo.
      final justCompletedLevel =
          !isReview &&
          state.levelAnsweredBefore < state.levelTotal &&
          answeredAfter >= state.levelTotal;

      emit(
        state.copyWith(
          answersSoFar: answersSoFar,
          finished: true,
          best: isNewRecord ? score : state.best,
          isNewRecord: isNewRecord,
          justCompletedLevel: justCompletedLevel,
          levelAnsweredAfter: answeredAfter,
        ),
      );
      return;
    }

    final newIndex = state.index + 1;
    if (!isReview) {
      await repository.saveSession(
        difficulty: difficulty,
        questionIds: state.questions.map((q) => q.id).toList(),
        currentIndex: newIndex,
        answers: answersSoFar,
        isReview: isReview,
      );
    }
    emit(
      state.copyWith(
        index: newIndex,
        clearSelected: true,
        answersSoFar: answersSoFar,
      ),
    );
  }
}
