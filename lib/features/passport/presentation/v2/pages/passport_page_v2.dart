import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/features/passport/presentation/passport_copy_extension.dart';
import 'package:goias_app/features/passport/presentation/passport_discard_dialog.dart';
import 'package:goias_app/features/passport/presentation/passport_month_grouping.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_cover_v2.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_empty_v2.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_month_group_v2.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_save_bar_v2.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_season_selector_v2.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class PassportPageV2 extends StatelessWidget {
  const PassportPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PassportCubit>()..loadInitial()),
        // Só pro nome no card (ver `PassportCoverV2.holderName`) — o
        // singleton já vem aquecido desde a Home (`HomeShellPage`), aqui só
        // reaproveitamos e escutamos.
        BlocProvider.value(value: sl<ProfileCubit>()),
      ],
      child: const _PassportViewV2(),
    );
  }
}

class _PassportViewV2 extends StatefulWidget {
  const _PassportViewV2();

  @override
  State<_PassportViewV2> createState() => _PassportViewV2State();
}

class _PassportViewV2State extends State<_PassportViewV2> {
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
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
              child: Column(
                children: [
                  _AppBarV2(
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
                  ),
                  Expanded(
                    child: BlocConsumer<PassportCubit, PassportState>(
                      listenWhen: (previous, current) =>
                          previous.saveStatus != current.saveStatus,
                      listener: (context, state) {
                        // Sucesso mora no próprio botão (ver
                        // `PassportSaveBarV2`) — só erro de verdade ainda
                        // precisa de um aviso à parte.
                        if (state.saveStatus == LoadStatus.error &&
                            state.saveErrorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.saveErrorMessage!)),
                          );
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          children: [
                            Expanded(child: _BodyV2(state: state)),
                            PassportSaveBarV2(
                              state: state,
                              onSave: () =>
                                  context.read<PassportCubit>().save(),
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

class _AppBarV2 extends StatelessWidget {
  const _AppBarV2({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BackButtonCircle(onTap: onBack),
              const Spacer(),
              Semantics(
                button: true,
                label: context.l10n.passportRankingCta,
                child: InkWell(
                  onTap: () => context.push('/arena/passport/ranking'),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.leaderboard_outlined,
                      size: 17,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PageTitle(context.passportCopy.title.toUpperCase()),
        ],
      ),
    );
  }
}

class _BodyV2 extends StatelessWidget {
  const _BodyV2({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    if (state.seasonsStatus == LoadStatus.loading ||
        state.seasonsStatus == LoadStatus.initial) {
      return const Center(child: GoiasLoadingIndicator());
    }
    if (state.seasonsStatus == LoadStatus.error) {
      return Center(
        child: StateMessage(
          icon: Icons.wifi_off_rounded,
          title: context.l10n.passportLoadErrorTitle,
          message: state.matchesErrorMessage,
          actionLabel: context.l10n.commonRetry,
          onAction: () => context.read<PassportCubit>().loadInitial(),
        ),
      );
    }
    if (state.seasons.isEmpty) {
      return Center(
        child: StateMessage(
          icon: Icons.confirmation_number_outlined,
          title: context.l10n.passportEmptyCatalogTitle,
        ),
      );
    }

    // `fullName` só (nunca `displayName`, que cai pro e-mail quando o
    // usuário não preencheu o nome) — sem nome cadastrado, o card volta pro
    // rótulo genérico, nunca mostra e-mail.
    final holderName = context.watch<ProfileCubit>().state.profile?.fullName;
    final cover = PassportCoverV2(
      summary: state.summary,
      holderName: holderName,
      onTap: () => context.push('/arena/passport/trajectory'),
    );
    // Só o onboarding (zero jogos) ocupa esse espaço — com jogos marcados,
    // o card já mostra o essencial (jogos carimbados + nível) e a lista
    // abaixo mostra os jogos em si, então repetir números aqui (jogos
    // vividos / progresso da temporada) só duplicava informação.
    final personalSection = state.summary.totalMatches == 0
        ? const PassportEmptyV2()
        : null;

    final seasonAndList = _MainColumnV2(state: state);

    if (context.isAtLeastExpanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  cover,
                  if (personalSection != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    personalSection,
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(child: seasonAndList),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        cover,
        if (personalSection != null) ...[
          const SizedBox(height: AppSpacing.lg),
          personalSection,
        ],
        const SizedBox(height: AppSpacing.xl),
        _SeasonSelectorSectionV2(state: state),
        const SizedBox(height: AppSpacing.lg),
        _MatchTimelineV2(state: state),
      ],
    );
  }
}

/// Coluna principal no layout web (seletor + filtros + lista) — o próprio
/// `ListView` que rola independente da coluna lateral fixa.
class _MainColumnV2 extends StatelessWidget {
  const _MainColumnV2({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        _SeasonSelectorSectionV2(state: state),
        const SizedBox(height: AppSpacing.lg),
        _MatchTimelineV2(state: state),
      ],
    );
  }
}

class _SeasonSelectorSectionV2 extends StatelessWidget {
  const _SeasonSelectorSectionV2({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PassportCubit>();
    return PassportSeasonSelectorV2(
      seasons: state.seasons,
      selectedYear: state.selectedYear,
      markedCountsByYear: state.markedCountsByYear,
      onSelected: cubit.selectYear,
    );
  }
}

class _MatchTimelineV2 extends StatelessWidget {
  const _MatchTimelineV2({required this.state});

  final PassportState state;

  @override
  Widget build(BuildContext context) {
    if (state.matchesStatus == LoadStatus.loading ||
        state.matchesStatus == LoadStatus.initial) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxl),
        child: Center(child: GoiasLoadingIndicator()),
      );
    }
    if (state.matchesStatus == LoadStatus.error) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
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
        padding: const EdgeInsets.only(top: AppSpacing.xl),
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
      unknownDateLabel: context.l10n.matchDateToBeConfirmed,
    );
    final cubit = context.read<PassportCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++)
          PassportMonthGroupV2(
            label: entries[i].label,
            matches: entries[i].matches,
            effectiveAttended: state.effectiveAttended,
            onToggle: cubit.toggleAttendance,
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}
