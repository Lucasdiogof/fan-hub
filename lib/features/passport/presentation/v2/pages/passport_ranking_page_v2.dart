import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/presentation/widgets/ranking_avatar.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_ranking_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_ranking_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Mesma tela/Cubit/regra de pontuação da V1 — só o cabeçalho segue a
/// linguagem compacta da V2 (sem a barra verde + escudo do `PageTitle`).
class PassportRankingPageV2 extends StatelessWidget {
  const PassportRankingPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PassportRankingCubit>()..load(),
      child: const _PassportRankingViewV2(),
    );
  }
}

class _PassportRankingViewV2 extends StatelessWidget {
  const _PassportRankingViewV2();

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
                        context.l10n.passportRankingTitle,
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
                  child: BlocBuilder<PassportRankingCubit, PassportRankingState>(
                    builder: (context, state) {
                      // Carregando: fora do ListView — um `Center` dentro de
                      // um item de lista só centraliza no espaço daquele
                      // item (o escudo ficava colado embaixo do seletor de
                      // período, não no meio da tela).
                      if (state.status == LoadStatus.initial ||
                          state.status == LoadStatus.loading) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PeriodSelectorV2(state: state),
                              const Expanded(
                                child: Center(child: GoiasLoadingIndicator()),
                              ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<PassportRankingCubit>().refresh(),
                        color: colors.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xxxl,
                          ),
                          children: [
                            _PeriodSelectorV2(state: state),
                            const SizedBox(height: AppSpacing.lg),
                            switch (state.status) {
                              // Inatingível aqui — tratado no `if` acima,
                              // antes do ListView existir.
                              LoadStatus.initial ||
                              LoadStatus.loading => const SizedBox.shrink(),
                              LoadStatus.error => Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Center(
                                  child: StateMessage(
                                    icon: Icons.wifi_off_rounded,
                                    title: context.l10n.passportLoadErrorTitle,
                                    message: state.errorMessage,
                                    actionLabel: context.l10n.commonRetry,
                                    onAction: () => context
                                        .read<PassportRankingCubit>()
                                        .refresh(),
                                  ),
                                ),
                              ),
                              LoadStatus.empty => Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Center(
                                  child: StateMessage(
                                    icon: Icons.leaderboard_outlined,
                                    title:
                                        context.l10n.passportRankingEmptyTitle,
                                    message: context
                                        .l10n
                                        .passportRankingEmptyMessage,
                                  ),
                                ),
                              ),
                              LoadStatus.success => Column(
                                children: [
                                  for (final entry in state.entries)
                                    _RankingRowV2(entry: entry),
                                ],
                              ),
                            },
                          ],
                        ),
                      );
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

class _PeriodSelectorV2 extends StatelessWidget {
  const _PeriodSelectorV2({required this.state});

  final PassportRankingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear; y >= currentYear - 4; y--) y];
    final options = <(int?, String)>[
      (null, l10n.passportRankingPeriodOverall),
      for (final y in years) (y, '$y'),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (year, label) = options[index];
          final selected = state.year == year;
          final colors = context.colors;
          return Semantics(
            button: true,
            selected: selected,
            label: label,
            child: InkWell(
              onTap: () =>
                  context.read<PassportRankingCubit>().selectYear(year),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? colors.onPrimary : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RankingRowV2 extends StatelessWidget {
  const _RankingRowV2({required this.entry});

  final PassportRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: entry.isMe ? colors.secondary : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: entry.isMe
              ? colors.primary.withValues(alpha: 0.35)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RankingAvatar(name: entry.name, avatarUrl: entry.avatarUrl),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: entry.isMe ? colors.primary : colors.textPrimary,
                    ),
                  ),
                ),
                if (entry.isMember) ...[
                  const SizedBox(width: 6),
                  RankingMemberBadge(label: l10n.arenaRankingMemberBadge),
                ],
              ],
            ),
          ),
          Text(
            l10n.passportRankingMatchCount(entry.matchCount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
