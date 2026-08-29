import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_progress_repository.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';

/// Destaque contextual da Arena na Home — a Arena saiu da bottom nav, então
/// este card é o convite principal pra entrar nela. A mensagem varia por
/// prioridade (votação da Escalação da Torcida aberta > Quiz incompleto >
/// convite genérico), mas o toque SEMPRE leva pro hub da Arena
/// (`/arena`), nunca direto pra um jogo/voto específico — quem decide o
/// que jogar é a própria tela da Arena.
class ArenaSpotlightCard extends StatefulWidget {
  const ArenaSpotlightCard({super.key});

  @override
  State<ArenaSpotlightCard> createState() => _ArenaSpotlightCardState();
}

class _ArenaSpotlightCardState extends State<ArenaSpotlightCard> {
  late final Future<ArenaProgressSnapshot?> _progressFuture = _loadProgress();

  Future<ArenaProgressSnapshot?> _loadProgress() async {
    try {
      return await sl<ArenaProgressRepository>().loadSnapshot();
    } catch (_) {
      return null;
    }
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
            final content = _contentFor(
              context,
              homeState: homeState,
              progress: progressSnapshot.data,
            );
            return _SpotlightSurface(
              eyebrow: l10n.arenaSpotlightEyebrow,
              headline: content.headline,
              subtitle: content.subtitle,
              ctaLabel: content.ctaLabel,
              onTap: () => context.push('/arena'),
            );
          },
        );
      },
    );
  }

  ({String headline, String subtitle, String ctaLabel}) _contentFor(
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
      );
    }

    // 2) Quiz ainda não terminado.
    if (progress != null && progress.quizAnswered < progress.quizTotal) {
      return (
        headline: l10n.arenaSpotlightQuizHeadline,
        subtitle: l10n.arenaSpotlightQuizSubtitle,
        ctaLabel: l10n.arenaSpotlightQuizCta,
      );
    }

    // 3) Fallback — sempre disponível, mesmo pra quem nunca jogou nada.
    return (
      headline: l10n.arenaSpotlightFallbackHeadline,
      subtitle: l10n.arenaSpotlightFallbackSubtitle,
      ctaLabel: l10n.arenaSpotlightFallbackCta,
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
  });

  final String eyebrow;
  final String headline;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
            ],
          ),
        ),
      ),
    );
  }
}
