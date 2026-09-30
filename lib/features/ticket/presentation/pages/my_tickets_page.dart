import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_state.dart';
import 'package:goias_app/features/ticket/presentation/ticket_l10n.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/demo_tag.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/viewport_centered.dart';

bool get _ticketsAreDemo =>
    sl<ClubConfig>().capabilities.ticketCommerceMode == CommerceMode.demo;

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyTicketsCubit>(),
      child: const _MyTicketsView(),
    );
  }
}

class _MyTicketsView extends StatefulWidget {
  const _MyTicketsView();

  @override
  State<_MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<_MyTicketsView>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _undoCheckIn(BuildContext context, Ticket ticket) async {
    final l10n = context.l10n;
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.event_busy_outlined,
      title: l10n.ticketsUndoCheckInConfirmTitle,
      description: l10n.ticketsUndoCheckInConfirmMessage,
      confirmLabel: l10n.ticketsKeepCheckInButton,
      cancelLabel: l10n.ticketsUndoCheckInButton,
    );
    if (confirmed != false || !context.mounted) return;
    await GlobalLoading.run(
      context,
      () => sl<TicketRepository>().undoCheckIn(ticket.matchId),
    );
    if (context.mounted) await context.read<MyTicketsCubit>().load();
  }

  Future<void> _requestRefund(BuildContext context, Ticket ticket) async {
    final l10n = context.l10n;
    final cubit = context.read<MyTicketsCubit>();
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.assignment_return_outlined,
      title: l10n.ticketsRefundConfirmTitle,
      description: _ticketsAreDemo
          ? '${l10n.ticketsRefundConfirmMessage}\n\n${l10n.ticketsRefundDemoNotice}'
          : l10n.ticketsRefundConfirmMessage,
      content: _MatchSummaryBlock(ticket: ticket),
      confirmLabel: l10n.ticketsRefundConfirmButton,
      cancelLabel: l10n.ticketsRefundCancelButton,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await GlobalLoading.run(context, () => cubit.requestRefund(ticket.id));
  }

  Future<void> _showRefundDetails(BuildContext context, Ticket ticket) {
    final l10n = context.l10n;
    final requestedAt = ticket.refundedAt;
    return AppBottomSheet.show(
      context,
      icon: Icons.assignment_return_outlined,
      title: l10n.ticketsRefundDetailsTitle,
      confirmLabel: l10n.commonClose,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(
            label: l10n.ticketsRefundDetailsStatusLabel,
            value: ticketStatusLabel(l10n, ticket.status),
          ),
          _DetailRow(
            label: l10n.ticketsRefundDetailsMatchLabel,
            value:
                '${shortTeamName(ticket.homeTeam.name)} x ${shortTeamName(ticket.awayTeam.name)}',
          ),
          _DetailRow(
            label: l10n.ticketsRefundDetailsTicketLabel,
            value: '${ticket.sectorName} · ${ticket.gate}',
          ),
          if (requestedAt != null)
            _DetailRow(
              label: l10n.ticketsRefundDetailsRequestedAtLabel,
              value:
                  '${fullDateLabel(requestedAt)} · ${timeLabel(requestedAt)}',
            ),
          if (_ticketsAreDemo) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.ticketsRefundDemoConcludedNote,
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: context.colors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
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
                  PageTitle(context.l10n.ticketsMyTicketsTitle),
                  const SizedBox(height: AppSpacing.lg),
                  TabBar(
                    controller: _tabController,
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textSecondary,
                    indicatorColor: colors.primary,
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    tabs: [
                      Tab(text: context.l10n.ticketsTabUpcoming),
                      Tab(text: context.l10n.ticketsTabHistory),
                    ],
                  ),
                  Expanded(
                    child: BlocConsumer<MyTicketsCubit, MyTicketsState>(
                      listenWhen: (previous, current) =>
                          previous.refundErrorMessage == null &&
                          current.refundErrorMessage != null,
                      listener: (context, state) {
                        final l10n = context.l10n;
                        AppBottomSheet.show(
                          context,
                          icon: Icons.error_outline_rounded,
                          title: l10n.ticketsRefundErrorTitle,
                          description: l10n.ticketsRefundErrorMessage,
                          confirmLabel: l10n.commonClose,
                        );
                      },
                      builder: (context, state) {
                        return switch (state.status) {
                          LoadStatus.initial || LoadStatus.loading => _centered(
                            const GoiasLoadingIndicator(),
                          ),
                          LoadStatus.error => _centered(
                            StateMessage(
                              icon: Icons.wifi_off_rounded,
                              title: context.l10n.ticketsMyTicketsLoadError,
                              message: state.errorMessage,
                            ),
                          ),
                          LoadStatus.empty => _centered(
                            StateMessage(
                              icon: Icons.confirmation_number_outlined,
                              title: context.l10n.ticketsMyTicketsEmpty,
                              message: context.l10n
                                  .ticketsMyTicketsEmptyMessage(
                                    sl<ClubConfig>().identity.shortName,
                                  ),
                            ),
                          ),
                          LoadStatus.success => TabBarView(
                            controller: _tabController,
                            children: [
                              _TicketList(
                                tickets: state.upcoming,
                                onUndoCheckIn: (ticket) =>
                                    _undoCheckIn(context, ticket),
                                onRequestRefund: (ticket) =>
                                    _requestRefund(context, ticket),
                                onViewDetails: (ticket) =>
                                    _showRefundDetails(context, ticket),
                              ),
                              _TicketList(
                                tickets: state.history,
                                onUndoCheckIn: (ticket) =>
                                    _undoCheckIn(context, ticket),
                                onRequestRefund: (ticket) =>
                                    _requestRefund(context, ticket),
                                onViewDetails: (ticket) =>
                                    _showRefundDetails(context, ticket),
                              ),
                            ],
                          ),
                        };
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

Widget _centered(Widget child) => viewportCentered(child);

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.tickets,
    required this.onUndoCheckIn,
    required this.onRequestRefund,
    required this.onViewDetails,
  });

  final List<Ticket> tickets;
  final void Function(Ticket ticket) onUndoCheckIn;
  final void Function(Ticket ticket) onRequestRefund;
  final void Function(Ticket ticket) onViewDetails;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return _centered(
        StateMessage(
          icon: Icons.confirmation_number_outlined,
          title: context.l10n.ticketsMyTicketsEmpty,
          message: context.l10n.ticketsMyTicketsEmptyMessage(
            sl<ClubConfig>().identity.shortName,
          ),
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxxl,
      ),
      itemCount: tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _TicketCard(
        ticket: tickets[index],
        onUndoCheckIn: () => onUndoCheckIn(tickets[index]),
        onRequestRefund: () => onRequestRefund(tickets[index]),
        onViewDetails: () => onViewDetails(tickets[index]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onUndoCheckIn,
    required this.onRequestRefund,
    required this.onViewDetails,
  });

  final Ticket ticket;
  final VoidCallback onUndoCheckIn;
  final VoidCallback onRequestRefund;
  final VoidCallback onViewDetails;

  // `TicketFixture.infoFor` sempre monta `canCancelCheckIn: true` (nenhum
  // clube configura isso diferente hoje) — inline em vez de instanciar um
  // `MatchTicketInfo` só pra ler uma constante, e em vez de esta Widget
  // precisar de `ClubTicketsContent` só pra isso.
  bool get _canUndo =>
      ticket.origin == TicketOrigin.membershipCheckIn &&
      ticket.status == TicketStatus.active;

  bool get _isRefunded => ticket.status == TicketStatus.refunded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kickoff = ticket.kickoff;
    final canRefund = canRequestRefund(ticket);
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
                  '${shortTeamName(ticket.homeTeam.name)} x ${shortTeamName(ticket.awayTeam.name)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: ticket.status),
            ],
          ),
          if (_ticketsAreDemo) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: DemoTag(label: context.l10n.ticketsDemoTag),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (kickoff != null)
            _MetaRow(
              icon: Icons.calendar_today_rounded,
              text: '${fullDateLabel(kickoff)} · ${timeLabel(kickoff)}',
            ),
          _MetaRow(
            icon: Icons.event_seat_outlined,
            text: '${ticket.sectorName} · ${ticket.gate}',
          ),
          _MetaRow(icon: Icons.person_outline_rounded, text: ticket.holderName),
          _MetaRow(
            icon: Icons.confirmation_number_outlined,
            text: ticket.origin == TicketOrigin.membershipCheckIn
                ? context.l10n.ticketsOriginCheckIn
                : context.l10n.ticketsOriginPurchase,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _isRefunded
                      ? onViewDetails()
                      : context.push('/tickets/view', extra: ticket),
                  child: Text(
                    _isRefunded
                        ? context.l10n.ticketsViewDetailsButton
                        : context.l10n.ticketsViewTicketButton,
                  ),
                ),
              ),
              if (_canUndo) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onUndoCheckIn,
                  style: TextButton.styleFrom(foregroundColor: colors.textHint),
                  child: Text(context.l10n.ticketsUndoCheckInButton),
                ),
              ],
            ],
          ),
          if (canRefund) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onRequestRefund,
                style: TextButton.styleFrom(foregroundColor: colors.textHint),
                child: Text(context.l10n.ticketsRequestRefundButton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ticketStatusLabel(context.l10n, status).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumo compacto da partida — mostrado dentro da bottom sheet de
/// confirmação de reembolso, mesmos dados já visíveis no card, só num
/// formato mais enxuto (sem título/status/titular).
class _MatchSummaryBlock extends StatelessWidget {
  const _MatchSummaryBlock({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kickoff = ticket.kickoff;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Column(
        children: [
          Text(
            '${shortTeamName(ticket.homeTeam.name)} x ${shortTeamName(ticket.awayTeam.name)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          if (kickoff != null)
            Text(
              '${fullDateLabel(kickoff)} · ${timeLabel(kickoff)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          Text(
            '${ticket.sectorName} · ${ticket.gate}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Linha label/valor — usada no detalhe do reembolso.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
