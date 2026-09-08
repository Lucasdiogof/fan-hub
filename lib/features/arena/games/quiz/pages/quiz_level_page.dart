import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_l10n.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/shared/local_best_score_store.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_cubit.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Resumo de progresso dos 3 níveis — usado tanto pelo carregamento próprio
/// desta tela (fallback de deep-link, e refresh ao voltar de uma partida)
/// quanto pelo pré-carregamento feito na Arena ANTES de navegar pra cá (ver
/// `GlobalLoading.run` em `arena_page.dart`), pra nunca abrir a tela
/// mostrando título/descrição primeiro e um spinner sozinho depois.
Future<Map<QuizDifficulty, QuizLevelSummary>> loadQuizLevelSummaries() async {
  final bank = await sl<QuizQuestionRepository>().load();
  final totals = {
    for (final level in QuizDifficulty.values)
      level: questionsForLevel(bank, level).length,
  };
  return sl<QuizProgressRepository>().getAllLevelSummaries(totals);
}

/// [initialSummaries], quando fornecido, já veio carregado por quem
/// navegou pra cá — a tela só exibe, sem passar por um estado intermediário
/// de "título já visível, lista ainda carregando". Fica `null` (e a tela
/// carrega sozinha) só em navegação direta por URL.
class QuizLevelPage extends StatefulWidget {
  const QuizLevelPage({this.initialSummaries, super.key});

  final Map<QuizDifficulty, QuizLevelSummary>? initialSummaries;

  @override
  State<QuizLevelPage> createState() => _QuizLevelPageState();
}

class _QuizLevelPageState extends State<QuizLevelPage> with RouteAware {
  late Map<QuizDifficulty, QuizLevelSummary>? _summaries =
      widget.initialSummaries;

  @override
  void initState() {
    super.initState();
    if (_summaries == null) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _load();

  Future<void> _load() async {
    final summaries = await loadQuizLevelSummaries();
    if (mounted) setState(() => _summaries = summaries);
  }

  /// Constrói e carrega o Cubit do nível ANTES de navegar (ver
  /// `GlobalLoading.run`) — a tela de jogo já abre com as perguntas e a
  /// sessão restauradas, nunca com um spinner.
  Future<void> _openQuiz(
    QuizDifficulty difficulty, {
    required bool isReview,
  }) async {
    String gameId() => 'quiz_${difficulty.name}';
    final cubit = QuizCubit(
      difficulty: difficulty,
      isReview: isReview,
      repository: sl<QuizProgressRepository>(),
      questionsRepository: sl<QuizQuestionRepository>(),
      loadBest: () => sl<LocalBestScoreStore>().bestScore(gameId()),
      saveBest: (score) =>
          sl<LocalBestScoreStore>().saveIfBest(gameId(), score),
      ranking: sl<ArenaRankingRepository>(),
    );
    await GlobalLoading.run(context, cubit.init);
    if (!mounted) return;
    unawaited(
      context.push(
        '/arena/quiz/play',
        extra: (difficulty: difficulty, isReview: isReview, cubit: cubit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ArenaGameHeader(
                    title: context.l10n
                        .arenaGameQuizTitle(
                          sl<ClubConfig>().identity.code,
                          sl<ClubConfig>().identity.shortName,
                        )
                        .toUpperCase(),
                    onBack: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.l10n.quizChooseLevel,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.quizChooseLevelHint,
                    style: TextStyle(
                      color: colors.textHint,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Expanded(
                    child: _summaries == null
                        ? const Center(child: GoiasLoadingIndicator())
                        : ListView.separated(
                            itemCount: _levels.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.lg),
                            itemBuilder: (context, index) {
                              final level = _levels[index];
                              return _LevelBanner(
                                level: level,
                                summary: _summaries![level.difficulty],
                                onTap: () => _openQuiz(
                                  level.difficulty,
                                  isReview: false,
                                ),
                                onReview: () =>
                                    _openQuiz(level.difficulty, isReview: true),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelContent {
  const _LevelContent({
    required this.difficulty,
    required this.icon,
    required this.gradient,
  });

  final QuizDifficulty difficulty;
  final IconData icon;
  final List<Color> gradient;
}

const _levels = [
  _LevelContent(
    difficulty: QuizDifficulty.torcedor,
    icon: Icons.groups_rounded,
    gradient: [Color(0xFF1E7A45), Color(0xFF07230F)],
  ),
  _LevelContent(
    difficulty: QuizDifficulty.esmeraldino,
    icon: Icons.shield_rounded,
    gradient: [Color(0xFF0F5C3D), Color(0xFF01140A)],
  ),
  _LevelContent(
    difficulty: QuizDifficulty.fanatico,
    icon: Icons.local_fire_department_rounded,
    gradient: [Color(0xFFC79A3D), Color(0xFF2A1B02)],
  ),
];

class _LevelBanner extends StatelessWidget {
  const _LevelBanner({
    required this.level,
    required this.summary,
    required this.onTap,
    required this.onReview,
  });

  final _LevelContent level;
  final QuizLevelSummary? summary;
  final VoidCallback onTap;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final progress = summary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.banner),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.banner),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: level.gradient,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    ),
                    child: Icon(level.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.difficulty
                              .label(sl<ClubConfig>().identity.fanDemonym)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quizLevelTagline(context.l10n, level.difficulty),
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      context.l10n.quizAnsweredCount(
                        progress.answered,
                        progress.total,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    if (progress.isComplete)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.quizDone,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${(progress.total == 0 ? 0 : progress.answered / progress.total * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.total == 0
                        ? 0
                        : progress.answered / progress.total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                if (progress.pendingReview > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: onReview,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.quizPendingReview(
                              progress.pendingReview,
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
