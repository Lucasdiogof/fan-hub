import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_filter_bar.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_match_row.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_save_bar.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_summary_card.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_year_selector.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Tela principal do Passaporte Esmeraldino — inspirada no Futbology, mas
/// com identidade própria: ano selecionado, filtros, lista agrupada por
/// mês, seleção múltipla local e um salvamento em lote só.
class PassportPage extends StatelessWidget {
  const PassportPage({super.key});

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

  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = context.l10n;
    final colors = context.colors;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.passportDiscardChangesTitle),
        content: Text(l10n.passportDiscardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.passportDiscardChangesConfirm,
              style: TextStyle(color: colors.gold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !context.select((PassportCubit c) => c.state.hasUnsavedChanges),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard(context)) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        BackButtonCircle(
                          onTap: () async {
                            final hasChanges = context
                                .read<PassportCubit>()
                                .state
                                .hasUnsavedChanges;
                            if (!hasChanges) {
                              context.pop();
                              return;
                            }
                            if (await _confirmDiscard(context) &&
                                context.mounted) {
                              context.pop();
                            }
                          },
                        ),
                        const Spacer(),
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PageTitle(context.l10n.passportTitle),
                    ),
                  ),
                  Expanded(
                    child: BlocConsumer<PassportCubit, PassportState>(
                      listenWhen: (previous, current) =>
                          previous.saveStatus != current.saveStatus,
                      listener: (context, state) {
                        if (state.saveStatus == LoadStatus.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.passportSaveSuccess),
                            ),
                          );
                        } else if (state.saveStatus == LoadStatus.error &&
                            state.saveErrorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.saveErrorMessage!)),
                          );
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          children: [
                            Expanded(child: _Body(state: state)),
                            PassportSaveBar(
                              state: state,
                              onSave: () => context.read<PassportCubit>().save(),
                            ),
                          ],
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

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    if (state.seasonsStatus == LoadStatus.loading ||
        state.seasonsStatus == LoadStatus.initial) {
      return const Center(child: GoiasLoadingIndicator());
    }
    if (state.seasonsStatus == LoadStatus.error) {
      return _centered(
        StateMessage(
          icon: Icons.wifi_off_rounded,
          title: context.l10n.passportLoadErrorTitle,
          message: state.matchesErrorMessage,
          actionLabel: context.l10n.commonRetry,
          onAction: () => context.read<PassportCubit>().loadInitial(),
        ),
      );
    }
    if (state.seasons.isEmpty) {
      return _centered(
        StateMessage(
          icon: Icons.confirmation_number_outlined,
          title: context.l10n.passportEmptyCatalogTitle,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        PassportSummaryCard(summary: state.summary),
        const SizedBox(height: AppSpacing.lg),
        PassportYearSelector(
          seasons: state.seasons,
          selectedYear: state.selectedYear,
          markedByYear: (_) => state.yearMarkedCount,
          onSelected: (year) => context.read<PassportCubit>().selectYear(year),
        ),
        const SizedBox(height: AppSpacing.md),
        PassportFilterBar(
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

    final locale = Localizations.localeOf(context).toLanguageTag();
    final groups = <String, List<PassportMatch>>{};
    for (final match in matches) {
      final label = DateFormat.yMMMM(locale).format(match.matchDate);
      (groups[label] ??= []).add(match);
    }

    final cubit = context.read<PassportCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: AppSpacing.md),
            child: Text(
              entry.key[0].toUpperCase() + entry.key.substring(1),
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
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.border),
                  PassportMatchRow(
                    match: entry.value[i],
                    attended: state.effectiveAttended(entry.value[i]),
                    onToggle: () => cubit.toggleAttendance(entry.value[i]),
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

Widget _centered(Widget child) {
  return Center(child: child);
}
