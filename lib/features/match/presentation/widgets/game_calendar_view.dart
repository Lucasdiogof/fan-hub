import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/calendar_competition_filter.dart';
import 'package:goias_app/features/match/domain/calendar_month_grid.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/cubit/game_calendar_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/game_calendar_state.dart';
import 'package:goias_app/features/match/presentation/widgets/calendar_day_cell.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:intl/intl.dart';

/// Corpo da aba "Calendário" dentro de Jogos — busca a temporada uma vez
/// (`GameCalendarCubit.load`) e depois só navega em memória. Só a lista de
/// temporadas é fixa em `[2026]` por enquanto — a fonte de dados hoje só
/// dá a agenda atual do time, nunca uma temporada passada à parte (ver
/// `FootballRepository.getSeasonFixtures`); o seletor já está pronto pra
/// quando isso existir.
class GameCalendarView extends StatelessWidget {
  const GameCalendarView({required this.onMatchTap, super.key});

  final ValueChanged<Match> onMatchTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCalendarCubit, GameCalendarState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SeasonAndFilterHeader(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _CalendarBody(state: state, onMatchTap: onMatchTap),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.state, required this.onMatchTap});

  final GameCalendarState state;
  final ValueChanged<Match> onMatchTap;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      LoadStatus.initial ||
      LoadStatus.loading => const Center(child: GoiasLoadingIndicator()),
      LoadStatus.error => Center(
        child: StateMessage(
          icon: Icons.wifi_off_rounded,
          title: context.l10n.matchLoadError,
          message: state.errorMessage,
          actionLabel: context.l10n.commonRetry,
          onAction: () => context.read<GameCalendarCubit>().load(),
        ),
      ),
      LoadStatus.empty => Center(
        child: StateMessage(
          icon: Icons.event_busy_rounded,
          title: context.l10n.matchNoMatches,
        ),
      ),
      LoadStatus.success => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          const _MonthNavigationHeader(),
          const SizedBox(height: AppSpacing.md),
          _MonthGrid(state: state, onMatchTap: onMatchTap),
        ],
      ),
    };
  }
}

class _SeasonAndFilterHeader extends StatelessWidget {
  const _SeasonAndFilterHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeasonBadge(),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<GameCalendarCubit, GameCalendarState>(
            builder: (context, state) => _CompetitionFilterRow(
              selected: state.competitionFilter,
              onChanged: context.read<GameCalendarCubit>().setCompetitionFilter,
            ),
          ),
        ],
      ),
    );
  }
}

/// "2026 ▾" — sem menu de verdade ainda (só existe uma temporada), mas já
/// no formato visual final. Vira um `DropdownButton`/`PopupMenuButton` real
/// assim que houver mais de uma temporada pra escolher.
class _SeasonBadge extends StatelessWidget {
  const _SeasonBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(
          '${DateTime.now().year}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.expand_more_rounded, size: 18, color: colors.textHint),
      ],
    );
  }
}

class _CompetitionFilterRow extends StatelessWidget {
  const _CompetitionFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final CalendarCompetitionFilter selected;
  final ValueChanged<CalendarCompetitionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = {
      CalendarCompetitionFilter.all: l10n.matchCalendarFilterAll,
      CalendarCompetitionFilter.brasileirao:
          l10n.matchCalendarFilterBrasileirao,
      CalendarCompetitionFilter.copaDoBrasil:
          l10n.matchCalendarFilterCopaDoBrasil,
      CalendarCompetitionFilter.goiano: l10n.matchCalendarFilterGoiano,
      CalendarCompetitionFilter.outros: l10n.matchCalendarFilterOutros,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in options.entries) ...[
            _FilterChip(
              label: entry.value,
              selected: selected == entry.key,
              onTap: () => onChanged(entry.key),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected ? colors.onPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavigationHeader extends StatelessWidget {
  const _MonthNavigationHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return BlocBuilder<GameCalendarCubit, GameCalendarState>(
      builder: (context, state) {
        final cubit = context.read<GameCalendarCubit>();
        final label = DateFormat(
          'MMMM yyyy',
          locale,
        ).format(state.selectedMonth).toUpperCase();
        return Row(
          children: [
            IconButton(
              onPressed: cubit.previousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              color: colors.textPrimary,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: cubit.nextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              color: colors.textPrimary,
            ),
          ],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.state, required this.onMatchTap});

  final GameCalendarState state;
  final ValueChanged<Match> onMatchTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    // Semana começa domingo (mesma convenção de `monthGridDays`) — pega os 7
    // dias de uma semana de referência só pra formatar o rótulo estreito de
    // cada dia (D/S/T/Q/Q/S/S), nunca datas reais.
    final referenceSunday = DateTime(2023, 1, 1); // domingo confirmado
    final weekdayLabels = [
      for (var i = 0; i < 7; i++)
        DateFormat(
          'EEEEE',
          locale,
        ).format(referenceSunday.add(Duration(days: i))),
    ];

    final days = monthGridDays(state.selectedMonth);
    final matchesByDay = state.matchesByDayInSelectedMonth;
    final now = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textHint,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Baixo de propósito: a célula com partida empilha número + escudo
          // + pill CASA/FORA (~80px de conteúdo) — um aspect ratio maior
          // (célula mais "quadrada") estourava layout nessa altura real.
          childAspectRatio: 0.56,
          children: [
            for (final date in days)
              CalendarDayCell(
                date: date,
                matches: date == null
                    ? const []
                    : matchesByDay[date.day] ?? const [],
                isToday:
                    date != null &&
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day,
                onMatchTap: onMatchTap,
              ),
          ],
        ),
      ],
    );
  }
}
