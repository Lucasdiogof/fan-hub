import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/features/passport/presentation/passport_copy_extension.dart';
import 'package:goias_app/features/passport/presentation/passport_discard_dialog.dart';
import 'package:goias_app/features/passport/presentation/passport_month_grouping.dart';
import 'package:goias_app/features/passport/presentation/v1/widgets/passport_filter_bar_v1.dart';
import 'package:goias_app/features/passport/presentation/v1/widgets/passport_match_row_v1.dart';
import 'package:goias_app/features/passport/presentation/v1/widgets/passport_save_bar_v1.dart';
import 'package:goias_app/features/passport/presentation/v1/widgets/passport_summary_card_v1.dart';
import 'package:goias_app/features/passport/presentation/v1/widgets/passport_year_selector_v1.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Tela principal do Passaporte Esmeraldino — inspirada no Futbology, mas
/// com identidade própria: ano selecionado, filtros, lista agrupada por
/// mês, seleção múltipla local e um salvamento em lote só.
class PassportPageV1 extends StatelessWidget {
  const PassportPageV1({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PassportCubit>()..loadInitial(),
      child: const _PassportView(),
    );
  }
}

class _PassportView extends StatelessWidget {
  const _PassportView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !context.select((PassportCubit c) => c.state.hasUnsavedChanges),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmDiscardPassportChanges(context)) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: BlocConsumer<PassportCubit, PassportState>(
          listenWhen: (previous, current) =>
              previous.saveStatus != current.saveStatus,
          listener: (context, state) {
            if (state.saveStatus == LoadStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.passportSaveSuccess)),
              );
            } else if (state.saveStatus == LoadStatus.error &&
                state.saveErrorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.saveErrorMessage!)));
            }
          },
          builder: (context, state) {
            final title = context.passportCopy.title;
            return Column(
              children: [
                Expanded(
                  child: DetailPageHeader(
                    title: title,
                    onBack: () async {
                      final hasChanges = context
                          .read<PassportCubit>()
                          .state
                          .hasUnsavedChanges;
                      if (!hasChanges) {
                        context.pop();
                        return;
                      }
                      if (await confirmDiscardPassportChanges(context) &&
                          context.mounted) {
                        context.pop();
                      }
                    },
                    actions: [
                      Semantics(
                        button: true,
                        label: context.l10n.passportRankingCta,
                        child: InkWell(
                          onTap: () => context.push('/arena/passport/ranking'),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.leaderboard_outlined,
                              size: 18,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    heroTitle: Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: _Body(state: state),
                    ),
                  ),
                ),
                PassportSaveBarV1(
                  state: state,
                  onSave: () => context.read<PassportCubit>().save(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    if (state.seasonsStatus == LoadStatus.loading ||
        state.seasonsStatus == LoadStatus.initial) {
      return const SizedBox(
        height: 320,
        child: Center(child: GoiasLoadingIndicator()),
      );
    }
    if (state.seasonsStatus == LoadStatus.error) {
      return SizedBox(
        height: 320,
        child: Center(
          child: StateMessage(
            icon: Icons.wifi_off_rounded,
            title: context.l10n.passportLoadErrorTitle,
            message: state.matchesErrorMessage,
            actionLabel: context.l10n.commonRetry,
            onAction: () => context.read<PassportCubit>().loadInitial(),
          ),
        ),
      );
    }
    if (state.seasons.isEmpty) {
      return SizedBox(
        height: 320,
        child: Center(
          child: StateMessage(
            icon: Icons.confirmation_number_outlined,
            title: context.l10n.passportEmptyCatalogTitle,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PassportSummaryCardV1(summary: state.summary),
        const SizedBox(height: AppSpacing.lg),
        PassportYearSelectorV1(
          seasons: state.seasons,
          selectedYear: state.selectedYear,
          markedByYear: (_) => state.yearMarkedCount,
          onSelected: (year) => context.read<PassportCubit>().selectYear(year),
        ),
        const SizedBox(height: AppSpacing.md),
        PassportFilterBarV1(
          state: state,
          onFilterSelected: (f) => context.read<PassportCubit>().setFilter(f),
          onCompetitionSelected: (c) =>
              context.read<PassportCubit>().setCompetitionFilter(c),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MatchList(state: state),
      ],
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    if (state.matchesStatus == LoadStatus.loading ||
        state.matchesStatus == LoadStatus.initial) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxxl),
        child: Center(child: GoiasLoadingIndicator()),
      );
    }
    if (state.matchesStatus == LoadStatus.error) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: Center(
          child: StateMessage(
            icon: Icons.wifi_off_rounded,
            title: context.l10n.passportLoadErrorTitle,
            message: state.matchesErrorMessage,
            actionLabel: context.l10n.commonRetry,
            onAction: () => context.read<PassportCubit>().retryLoadYear(),
          ),
        ),
      );
    }

    final matches = state.filteredMatches;
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: Center(
          child: StateMessage(
            icon: Icons.event_busy_outlined,
            title: context.l10n.passportNoMatchesForFilter,
          ),
        ),
      );
    }

    final entries = groupMatchesByMonth(
      matches,
      Localizations.localeOf(context).toLanguageTag(),
    );

    final cubit = context.read<PassportCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: AppSpacing.md),
            child: Text(
              entry.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: context.colors.textHint,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < entry.matches.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.border),
                  PassportMatchRowV1(
                    match: entry.matches[i],
                    attended: state.effectiveAttended(entry.matches[i]),
                    onToggle: () => cubit.toggleAttendance(entry.matches[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
