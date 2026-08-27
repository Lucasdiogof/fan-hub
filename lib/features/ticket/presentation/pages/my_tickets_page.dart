import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/data/mock_ticket_fixture.dart';
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
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

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
                    child: BlocBuilder<MyTicketsCubit, MyTicketsState>(
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
                              message:
                                  context.l10n.ticketsMyTicketsEmptyMessage,
                            ),
                          ),
                          LoadStatus.success => TabBarView(
                            controller: _tabController,
                            children: [
                              _TicketList(
                                tickets: state.upcoming,
                                onUndoCheckIn: (ticket) =>
                                    _undoCheckIn(context, ticket),
                              ),
                              _TicketList(
                                tickets: state.history,
                                onUndoCheckIn: (ticket) =>
                                    _undoCheckIn(context, ticket),
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

class _TicketList extends StatelessWidget {
  const _TicketList({required this.tickets, required this.onUndoCheckIn});

  final List<Ticket> tickets;
  final void Function(Ticket ticket) onUndoCheckIn;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return _centered(
        StateMessage(
          icon: Icons.confirmation_number_outlined,
          title: context.l10n.ticketsMyTicketsEmpty,
          message: context.l10n.ticketsMyTicketsEmptyMessage,
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
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onUndoCheckIn});

  final Ticket ticket;
  final VoidCallback onUndoCheckIn;

  bool get _canUndo =>
      ticket.origin == TicketOrigin.membershipCheckIn &&
      ticket.status == TicketStatus.active &&
      TicketFixture.infoFor(ticket.matchId).canCancelCheckIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kickoff = ticket.kickoff;
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
                  onPressed: () => context.push('/tickets/view', extra: ticket),
                  child: Text(context.l10n.ticketsViewTicketButton),
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
