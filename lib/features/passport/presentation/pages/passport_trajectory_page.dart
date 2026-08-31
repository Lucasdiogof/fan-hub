import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_trajectory_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_trajectory_state.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_level_style.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_memorable_match_picker.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// "Minha trajetória" — resumo pessoal e estatístico das partidas marcadas
/// como "Eu fui" no Passaporte Esmeraldino. Substitui a antiga
/// `PassportStatsPageV2` (mesma origem de dados, agora com cabeçalho de
/// usuário, estádios e jogo memorável somados).
class PassportTrajectoryPage extends StatelessWidget {
  const PassportTrajectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PassportTrajectoryCubit>()..load()),
        BlocProvider.value(value: sl<ProfileCubit>()),
      ],
      child: const _PassportTrajectoryView(),
    );
  }
}

class _PassportTrajectoryView extends StatelessWidget {
  const _PassportTrajectoryView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.l10n.passportStatsTitle,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      BlocBuilder<
                        PassportTrajectoryCubit,
                        PassportTrajectoryState
                      >(
                        builder: (context, state) {
                          return switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading =>
                              const Center(child: GoiasLoadingIndicator()),
                            LoadStatus.error => Center(
                              child: StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title: context.l10n.passportLoadErrorTitle,
                                actionLabel: context.l10n.commonRetry,
                                onAction: () => context
                                    .read<PassportTrajectoryCubit>()
                                    .load(),
                              ),
                            ),
                            LoadStatus.empty => const SizedBox.shrink(),
                            LoadStatus.success =>
                              state.totalMatches == 0
                                  ? Center(
                                      child: StateMessage(
                                        icon:
                                            Icons.confirmation_number_outlined,
                                        title: context
                                            .l10n
                                            .passportStatsEmptyTitle,
                                        message: context
                                            .l10n
                                            .passportStatsEmptyMessage,
                                      ),
                                    )
                                  : _TrajectoryBody(state: state),
                          };
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrajectoryBody extends StatelessWidget {
  const _TrajectoryBody({required this.state});

  final PassportTrajectoryState state;

  Future<void> _pickMemorableMatch(BuildContext context) async {
    final cubit = context.read<PassportTrajectoryCubit>();
    final chosen = await showMemorableMatchPicker(
      context,
      matches: state.attendedMatches,
      selectedMatchId: state.memorableMatch?.id,
    );
    if (chosen != null) {
      await cubit.selectMemorableMatch(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final breakdown = state.breakdown;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        const _UserCard(),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.passportTrajectoryGames,
                value: state.totalMatches,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportTrajectoryStadiums,
                value: state.stadiumSummary.uniqueStadiums,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportTrajectorySeasons,
                value: state.seasonsCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsWins,
                value: breakdown.wins,
                color: context.colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsDraws,
                value: breakdown.draws,
                color: context.colors.textHint,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsLosses,
                value: breakdown.losses,
                color: context.colors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _HomeAwayCard(
          homeGames: breakdown.homeGames,
          awayGames: breakdown.awayGames,
        ),
        const SizedBox(height: AppSpacing.md),
        _GoalsCard(
          goalsFor: breakdown.goalsFor,
          goalsAgainst: breakdown.goalsAgainst,
          goalDifference: state.goalDifference,
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final vertical = constraints.maxWidth < 360;
            final memorableCard = _MemorableMatchCard(
              match: state.memorableMatch,
              saving: state.savingMemorableMatch,
              onTap: () => _pickMemorableMatch(context),
            );
            final stadiumCard = _StadiumCard(summary: state.stadiumSummary);
            if (vertical) {
              return Column(
                children: [
                  memorableCard,
                  const SizedBox(height: AppSpacing.sm),
                  stadiumCard,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: memorableCard),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: stadiumCard),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassportTrajectoryCubit, PassportTrajectoryState>(
      builder: (context, trajectoryState) {
        final level = passportLevelForMatches(trajectoryState.totalMatches);
        return BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            final profile = profileState.profile;
            final colors = context.colors;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.deepGreen, colors.darkGreen],
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  _Avatar(profile: profile),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            passportLevelLabel(context.l10n, level),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final Profile? profile;

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        image: hasAvatar
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: hasAvatar
          ? null
          : Text(
              _initials(profile?.displayName ?? ''),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color ?? colors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAwayCard extends StatelessWidget {
  const _HomeAwayCard({required this.homeGames, required this.awayGames});

  final int homeGames;
  final int awayGames;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _IconStat(
              icon: Icons.home_rounded,
              value: homeGames,
              label: l10n.passportStatsHomeGames,
            ),
          ),
          Container(width: 1, height: 40, color: colors.border),
          Expanded(
            child: _IconStat(
              icon: Icons.flight_takeoff_rounded,
              value: awayGames,
              label: l10n.passportStatsAwayGames,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
  });

  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final diffText = goalDifference > 0
        ? '+$goalDifference'
        : '$goalDifference';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GoalStat(
              value: '$goalsFor',
              label: l10n.passportStatsGoalsFor,
              color: colors.success,
            ),
          ),
          Container(width: 1, height: 36, color: colors.border),
          Expanded(
            child: _GoalStat(
              value: '$goalsAgainst',
              label: l10n.passportStatsGoalsAgainst,
              color: colors.gold,
            ),
          ),
          Container(width: 1, height: 36, color: colors.border),
          Expanded(
            child: _GoalStat(
              value: diffText,
              label: l10n.passportStatsGoalDifference,
              color: goalDifference >= 0 ? colors.success : colors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _MemorableMatchCard extends StatelessWidget {
  const _MemorableMatchCard({
    required this.match,
    required this.saving,
    required this.onTap,
  });

  final PassportMatch? match;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: saving ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.passportTrajectoryMemorableMatch.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: colors.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (match == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.passportTrajectoryMemorableEmpty,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _MemorableMatchDetail(match: match!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemorableMatchDetail extends StatelessWidget {
  const _MemorableMatchDetail({required this.match});

  final PassportMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = match.matchDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final hasScore = match.goiasScore != null && match.opponentScore != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goiás x ${match.opponent}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        if (hasScore) ...[
          const SizedBox(height: 4),
          Text(
            '${match.goiasScore} x ${match.opponentScore}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          dateLabel,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        Text(
          match.competition,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _StadiumCard extends StatelessWidget {
  const _StadiumCard({required this.summary});

  final PassportStadiumSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasData = summary.mostVisitedName != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.passportTrajectoryMostVisitedStadium.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Icon(Icons.stadium_outlined, size: 22, color: colors.primary),
          const SizedBox(height: AppSpacing.sm),
          if (hasData) ...[
            Text(
              summary.mostVisitedName!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.passportTrajectoryGamesCount(summary.mostVisitedCount ?? 0),
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ] else
            Text(
              l10n.passportTrajectoryStadiumUnavailable,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
