import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/ticket/presentation/ticket_l10n.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyOrdersCubit>(),
      child: const _MyOrdersView(),
    );
  }
}

class _MyOrdersView extends StatelessWidget {
  const _MyOrdersView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PageTitle(context.l10n.ticketsMyOrdersTitle),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: BlocBuilder<MyOrdersCubit, MyOrdersState>(
                      builder: (context, state) {
                        return RefreshIndicator(
                          onRefresh: () => context.read<MyOrdersCubit>().load(),
                          color: colors.primary,
                          child: switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading =>
                              _centered(const GoiasLoadingIndicator()),
                            LoadStatus.error => _centered(
                              StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title: context.l10n.ticketsMyOrdersLoadError,
                                message: state.errorMessage,
                              ),
                            ),
                            LoadStatus.empty => _centered(
                              StateMessage(
                                icon: Icons.receipt_long_outlined,
                                title: context.l10n.ticketsMyOrdersEmpty,
                                message:
                                    context.l10n.ticketsMyOrdersEmptyMessage,
                              ),
                            ),
                            LoadStatus.success => ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxxl,
                              ),
                              itemCount: state.orders.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) =>
                                  _OrderCard(order: state.orders[index]),
                            ),
                          },
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

Widget _centered(Widget child) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Center(child: child),
      ),
    ],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final TicketOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
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
                    context.l10n.ticketsOrderNumber(order.number),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  formatBrl(order.total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${shortTeamName(order.homeTeam.name)} x ${shortTeamName(order.awayTeam.name)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            for (final item in order.items)
              Text(
                '${item.sectorName} · ${item.categoryLabel} · ${item.quantity}x',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
            const SizedBox(height: 4),
            Text(
              '${fullDateLabel(order.createdAt)} · ${ticketOrderStatusLabel(context.l10n, order.status).toUpperCase()}',
              style: TextStyle(fontSize: 12.5, color: colors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.hero),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.ticketsOrderNumber(order.number),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${shortTeamName(order.homeTeam.name)} x ${shortTeamName(order.awayTeam.name)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${fullDateLabel(order.createdAt)} · ${order.stadium}',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.sectorName} · ${item.gate} · ${item.categoryLabel} (${item.quantity}x)',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        formatBrl(item.subtotal),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(height: 1, color: colors.border),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.ticketsTotalLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    formatBrl(order.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/tickets/my');
                  },
                  child: Text(context.l10n.ticketsViewRelatedTicket),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
