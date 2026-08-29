import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_progress_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/crowd_lineup/presentation/open_crowd_lineup.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/core/error/result.dart';

/// Destaque contextual da Arena na Home — a Arena saiu da bottom nav, então
/// este card é o convite principal pra entrar nela. Dados 100% reaproveitados
/// de `HomeCubit`/`ArenaRankingRepository`/`ArenaProgressRepository` (as
/// mesmas fontes que a própria `ArenaPage` já usa) — nenhuma tabela nova.
/// A chamada principal muda por prioridade: votação da Escalação da Torcida
/// aberta > Quiz incompleto > resumo de ranking (fallback sempre disponível).
class ArenaSpotlightCard extends StatefulWidget {
  const ArenaSpotlightCard({super.key});

  @override
  State<ArenaSpotlightCard> createState() => _ArenaSpotlightCardState();
}

class _ArenaSpotlightCardState extends State<ArenaSpotlightCard> {
  late final Future<ArenaProgressSnapshot?> _progressFuture = _loadProgress();
  late final Future<({int rank, int totalScore})?> _rankFuture = _loadRank();

  Future<ArenaProgressSnapshot?> _loadProgress() async {
    try {
      return await sl<ArenaProgressRepository>().loadSnapshot();
    } catch (_) {
      return null;
    }
  }

  Future<({int rank, int totalScore})?> _loadRank() async {
    final result = await sl<ArenaRankingRepository>().getMyRank(
      RankingPeriod.allTime,
    );
    return result is Success<({int rank, int totalScore})?>
        ? result.data
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: sl<HomeCubit>(),
      builder: (context, homeState) {
        return FutureBuilder<ArenaProgressSnapshot?>(
          future: _progressFuture,
          builder: (context, progressSnapshot) {
            return FutureBuilder<({int rank, int totalScore})?>(
              future: _rankFuture,
              builder: (context, rankSnapshot) {
                final progress = progressSnapshot.data;
                final rank = rankSnapshot.data;
                final content = _contentFor(
                  context,
                  homeState: homeState,
                  progress: progress,
                );
                return _SpotlightSurface(
                  eyebrow: l10n.arenaSpotlightEyebrow,
                  headline: content.headline,
                  subtitle: content.subtitle,
                  ctaLabel: content.ctaLabel,
                  onTap: content.onTap,
                  rank: rank?.rank,
                  totalScore: rank?.totalScore,
                );
              },
            );
          },
        );
      },
    );
  }

  ({String headline, String subtitle, String ctaLabel, VoidCallback onTap})
  _contentFor(
    BuildContext context, {
    required HomeState homeState,
    required ArenaProgressSnapshot? progress,
  }) {
    final l10n = context.l10n;
    final nextMatch = homeState.nextMatch;

    // 1) Escalação da Torcida aberta pro próximo jogo e o usuário ainda não
    // votou — chamada mais forte porque tem prazo (fecha com a bola rolando).
    if (nextMatch != null && !homeState.hasVotedForNextMatch) {
      return (
        headline: l10n.arenaSpotlightLineupHeadline,
        subtitle: l10n.arenaSpotlightLineupSubtitle(nextMatch.awayTeam.name),
        ctaLabel: l10n.arenaSpotlightLineupCta,
        onTap: () => openCrowdLineup(context, nextMatch),
      );
    }

    // 2) Quiz ainda não terminado.
    if (progress != null && progress.quizAnswered < progress.quizTotal) {
      return (
        headline: l10n.arenaSpotlightQuizHeadline,
        subtitle: l10n.arenaSpotlightQuizSubtitle,
        ctaLabel: l10n.arenaSpotlightQuizCta,
        onTap: () => context.push('/arena/quiz'),
      );
    }

    // 3) Fallback — sempre disponível, mesmo pra quem nunca jogou nada.
    return (
      headline: l10n.arenaSpotlightFallbackHeadline,
      subtitle: l10n.arenaSpotlightFallbackSubtitle,
      ctaLabel: l10n.arenaSpotlightFallbackCta,
      onTap: () => context.push('/arena'),
    );
  }
}

class _SpotlightSurface extends StatelessWidget {
  const _SpotlightSurface({
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
    this.rank,
    this.totalScore,
  });

  final String eyebrow;
  final String headline;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;
  final int? rank;
  final int? totalScore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: colors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    eyebrow.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: colors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                headline,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ArenaColors.arenaTop,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(ctaLabel),
                    ),
                  ),
                  const Spacer(),
                  if (rank != null)
                    Text(
                      l10n.arenaSpotlightRankSummary(rank!, totalScore ?? 0),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
