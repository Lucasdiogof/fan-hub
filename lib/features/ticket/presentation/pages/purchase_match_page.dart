import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_state.dart';
import 'package:goias_app/features/ticket/presentation/pages/purchase_summary_page.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';

/// Tela de compra — recebe o `PurchaseCubit` já construído (mesmo padrão de
/// "cubit pronto antes de navegar" já usado na Arena, ver
/// `CareerPathPage`), porque o carrinho precisa sobreviver à navegação até
/// o resumo (`PurchaseSummaryPage`), que reaproveita o MESMO Cubit em vez
/// de recriar o estado.
class PurchaseMatchPage extends StatelessWidget {
  const PurchaseMatchPage({
    required this.cubit,
    required this.profile,
    super.key,
  });

  final PurchaseCubit cubit;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _PurchaseMatchView(profile: profile),
    );
  }
}

class _PurchaseMatchView extends StatelessWidget {
  const _PurchaseMatchView({required this.profile});

  final Profile profile;

  Future<void> _openMatchInfo(BuildContext context) async {
    final matchId = context
        .read<PurchaseCubit>()
        .state
        .event
        .match
        .id
        .toString();
    final result = await GlobalLoading.run(
      context,
      () => sl<TicketRepository>().getMatchSalesInfo(matchId),
    );
    if (!context.mounted) return;
    if (result case Success(:final data) when data != null) {
      unawaited(context.push('/tickets/purchase/info', extra: data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      builder: (context, state) {
        final match = state.event.match;
        final sectors = state.event.info.sectors;
        final goiasSectors = sectors.where((s) => !s.isVisitorSector).toList();
        final visitorSectors = sectors.where((s) => s.isVisitorSector).toList();

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
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
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => unawaited(_openMatchInfo(context)),
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.competition.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: colors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shortTeamName(match.homeTeam.name).toUpperCase()} x ${shortTeamName(match.awayTeam.name).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (match.kickoff != null)
                        Text(
                          '${shortDateLabel(match.kickoff!, Localizations.localeOf(context).toString()).toUpperCase()} · ${timeLabel(match.kickoff!)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        match.stadium,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      if (goiasSectors.isNotEmpty) ...[
                        _GroupLabel(context.l10n.ticketsHomeCrowdLabel),
                        for (final sector in goiasSectors) ...[
                          _SectorCard(sector: sector),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                      if (visitorSectors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _GroupLabel(context.l10n.ticketsAwayCrowdLabel),
                        for (final sector in visitorSectors) ...[
                          _SectorCard(sector: sector),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ],
                  ),
                ),
                _BottomBar(
                  total: state.total,
                  quantity: state.totalQuantity,
                  onContinue: state.canProceedToSummary
                      ? () => context.push(
                          '/tickets/purchase/summary',
                          extra: PurchaseSummaryArgs(
                            cubit: context.read<PurchaseCubit>(),
                            profile: profile,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: context.colors.textHint,
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({required this.sector});

  final TicketSector sector;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final soldOut = sector.soldOut;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sector.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (soldOut)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.ticketsSoldOutButton.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${sector.venueLabel} · ${sector.gate}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final category in sector.categories)
            _CategoryRow(sectorId: sector.id, category: category),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.sectorId, required this.category});

  final String sectorId;
  final TicketPriceCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (category.soldOut) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: TextStyle(fontSize: 13.5, color: colors.textHint),
              ),
            ),
            Text(
              context.l10n.ticketsSoldOutButton,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textHint,
              ),
            ),
          ],
        ),
      );
    }
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      buildWhen: (previous, current) =>
          previous.quantityFor(sectorId, category.id) !=
          current.quantityFor(sectorId, category.id),
      builder: (context, state) {
        final quantity = state.quantityFor(sectorId, category.id);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      formatBrl(category.price),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _QuantityStepper(
                quantity: quantity,
                onChanged: (value) => context.read<PurchaseCubit>().setQuantity(
                  sectorId,
                  category.id,
                  value,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          onTap: quantity > 0 ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          onTap: () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return Material(
      color: enabled ? colors.secondary : colors.background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 17,
            color: enabled ? colors.primary : colors.textHint,
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.total,
    required this.quantity,
    required this.onContinue,
  });

  final double total;
  final int quantity;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.ticketsTicketCount(quantity),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                Text(
                  formatBrl(total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.secondary,
              disabledForegroundColor: colors.textHint,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(context.l10n.ticketsContinueButton),
          ),
        ],
      ),
    );
  }
}
