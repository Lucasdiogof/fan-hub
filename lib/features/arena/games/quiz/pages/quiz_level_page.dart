import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';

class QuizLevelPage extends StatefulWidget {
  const QuizLevelPage({super.key});

  @override
  State<QuizLevelPage> createState() => _QuizLevelPageState();
}

class _QuizLevelPageState extends State<QuizLevelPage> with RouteAware {
  Map<QuizDifficulty, QuizLevelSummary>? _summaries;

  @override
  void initState() {
    super.initState();
    _load();
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
    final totals = {
      for (final level in QuizDifficulty.values)
        level: questionsForLevel(level).length,
    };
    final summaries = await sl<QuizProgressRepository>().getAllLevelSummaries(
      totals,
    );
    if (mounted) setState(() => _summaries = summaries);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BackButtonCircle(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'QUIZ DO VERDÃO',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Escolha o nível',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cada nível tem seu próprio banco de perguntas — quanto mais alto, mais difícil.',
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: _summaries == null
                    ? Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      )
                    : ListView.separated(
                        itemCount: _levels.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final level = _levels[index];
                          return _LevelBanner(
                            level: level,
                            summary: _summaries![level.difficulty],
                            onTap: () => context.push(
                              '/arena/quiz/play',
                              extra: (
                                difficulty: level.difficulty,
                                isReview: false,
                              ),
                            ),
                            onReview: () => context.push(
                              '/arena/quiz/play',
                              extra: (
                                difficulty: level.difficulty,
                                isReview: true,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelContent {
  const _LevelContent({
    required this.difficulty,
    required this.tagline,
    required this.icon,
    required this.gradient,
  });

  final QuizDifficulty difficulty;
  final String tagline;
  final IconData icon;
  final List<Color> gradient;
}

const _levels = [
  _LevelContent(
    difficulty: QuizDifficulty.torcedor,
    tagline: 'Fatos básicos, títulos e campanhas que todo torcedor conhece.',
    icon: Icons.groups_rounded,
    gradient: [Color(0xFF1E7A45), Color(0xFF07230F)],
  ),
  _LevelContent(
    difficulty: QuizDifficulty.esmeraldino,
    tagline: 'História, ídolos e jogos marcantes pra quem manja do clube.',
    icon: Icons.shield_rounded,
    gradient: [Color(0xFF0F5C3D), Color(0xFF01140A)],
  ),
  _LevelContent(
    difficulty: QuizDifficulty.fanatico,
    tagline: 'Recordes e números pra quem não erra nenhuma.',
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
                          level.difficulty.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level.tagline,
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
                      '${progress.answered}/${progress.total} perguntas',
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
                            'Concluído',
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
                            '${progress.pendingReview} para revisar',
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
