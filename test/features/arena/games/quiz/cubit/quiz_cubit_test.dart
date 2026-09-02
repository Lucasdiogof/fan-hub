import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_cubit.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `SupabaseClient` nunca conectado de verdade — só existe pra satisfazer o
/// construtor das classes concretas que estamos sobrescrevendo abaixo; todo
/// método que o Cubit de fato chama é sobrescrito antes de tocar a rede.
SupabaseClient _dummyClient() => SupabaseClient(
  'https://example.supabase.co',
  'anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

class _SpyQuizProgressRepository extends QuizProgressRepository {
  _SpyQuizProgressRepository() : super(_dummyClient());

  int recordAnswerCallCount = 0;
  int saveSessionCallCount = 0;
  int clearSessionCallCount = 0;

  @override
  Future<Set<String>> getAnsweredIds(QuizDifficulty difficulty) async => {};

  @override
  Future<Set<String>> getPendingReviewIds(QuizDifficulty difficulty) async =>
      {};

  @override
  Future<QuizSession?> loadSession(QuizDifficulty difficulty) async => null;

  @override
  Future<void> saveSession({
    required QuizDifficulty difficulty,
    required List<String> questionIds,
    required int currentIndex,
    required List<Map<String, dynamic>> answers,
    required bool isReview,
  }) async {
    saveSessionCallCount++;
  }

  @override
  Future<void> clearSession(QuizDifficulty difficulty) async {
    clearSessionCallCount++;
  }

  @override
  Future<void> recordAnswer({
    required String questionId,
    required QuizDifficulty difficulty,
    required bool wasCorrect,
  }) async {
    recordAnswerCallCount++;
    // Delay real (não só microtask) — é essa janela assíncrona que um
    // duplo toque explora; sem ela o teste não provaria nada sobre a
    // proteção contra corrida.
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _SpyQuizQuestionRepository extends QuizQuestionRepository {
  _SpyQuizQuestionRepository(this._questions)
    : super(_dummyClient(), goiasClubConfig);

  final List<QuizQuestion> _questions;

  @override
  Future<List<QuizQuestion>> load() async => _questions;
}

class _SpyArenaRankingRepository implements ArenaRankingRepository {
  int recordScoreCallCount = 0;

  @override
  Future<Result<ScoreResult>> recordScore({
    required String gameId,
    required String itemId,
    required String eventType,
    int? attemptNumber,
    String? difficulty,
    int? wrongCount,
    int? foundCount,
    int? totalCount,
    bool wasRevealed = false,
    bool wasAbandoned = false,
  }) async {
    recordScoreCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return const Success(
      ScoreResult(pointsEarned: 8, itemScore: 8, totalScore: 8, gameScore: 8),
    );
  }

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) async => const Success([]);

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) async => const Success(null);

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) async {
    throw UnimplementedError();
  }
}

const _questions = [
  QuizQuestion(
    id: 'torcedor_01',
    question: 'Pergunta 1?',
    options: ['certa', 'errada1', 'errada2'],
    correctIndex: 0,
    difficulty: QuizDifficulty.torcedor,
  ),
  QuizQuestion(
    id: 'torcedor_02',
    question: 'Pergunta 2?',
    options: ['certa', 'errada1', 'errada2'],
    correctIndex: 0,
    difficulty: QuizDifficulty.torcedor,
  ),
];

void main() {
  late _SpyQuizProgressRepository progressRepo;
  late _SpyArenaRankingRepository rankingRepo;
  late QuizCubit cubit;

  setUp(() async {
    progressRepo = _SpyQuizProgressRepository();
    rankingRepo = _SpyArenaRankingRepository();
    cubit = QuizCubit(
      difficulty: QuizDifficulty.torcedor,
      isReview: false,
      repository: progressRepo,
      questionsRepository: _SpyQuizQuestionRepository(_questions),
      loadBest: () async => 0,
      saveBest: (_) async {},
      ranking: rankingRepo,
    );
    await cubit.init();
    cubit.selectAnswer(0); // opção correta, index 0 nas duas perguntas fake.
  });

  tearDown(() => cubit.close());

  test('setUp chegou num estado respondido, pronto pra chamar next()', () {
    expect(cubit.state.answered, isTrue);
    expect(cubit.state.isLastQuestion, isFalse);
  });

  test(
    'duplo toque (2 chamadas de next() sem esperar a primeira) só avança uma vez',
    () async {
      final first = cubit.next();
      final second = cubit.next(); // "segundo toque" durante o await do 1º.
      await Future.wait([first, second]);

      expect(progressRepo.recordAnswerCallCount, 1);
      expect(rankingRepo.recordScoreCallCount, 1);
      expect(cubit.state.index, 1); // avançou exatamente UMA pergunta.
    },
  );

  test('botão fica em loading (submittingNext) durante o next() em curso', () async {
    final future = cubit.next();
    // Ainda dentro do delay assíncrono do repositório fake.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(cubit.state.submittingNext, isTrue);

    await future;
    expect(cubit.state.submittingNext, isFalse);
  });

  test(
    'a guarda existe no Cubit, não só na UI — chamar next() de novo enquanto submittingNext é true é ignorado',
    () async {
      final future = cubit.next();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state.submittingNext, isTrue);

      // Chamada direta no Cubit, sem passar pelo botão — prova que a
      // proteção não depende só do `onPressed: null` da UI.
      await cubit.next();
      await future;

      expect(progressRepo.recordAnswerCallCount, 1);
      expect(rankingRepo.recordScoreCallCount, 1);
    },
  );

  test('next() sem ter respondido (answered=false) nunca chama o repositório', () async {
    final freshCubit = QuizCubit(
      difficulty: QuizDifficulty.torcedor,
      isReview: false,
      repository: _SpyQuizProgressRepository(),
      questionsRepository: _SpyQuizQuestionRepository(_questions),
      loadBest: () async => 0,
      saveBest: (_) async {},
      ranking: _SpyArenaRankingRepository(),
    );
    await freshCubit.init();

    await freshCubit.next();

    expect(freshCubit.state.index, 0);
    await freshCubit.close();
  });
}
