import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

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

class _MyTicketsView extends StatelessWidget {
  const _MyTicketsView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
                  const PageTitle('MEUS INGRESSOS'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: BlocBuilder<MyTicketsCubit, MyTicketsState>(
                      builder: (context, state) {
                        return RefreshIndicator(
                          onRefresh: () =>
                              context.read<MyTicketsCubit>().load(),
                          color: colors.primary,
                          child: switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading =>
                              _centered(const GoiasLoadingIndicator()),
                            LoadStatus.error => _centered(
                              StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title:
                                    'Não foi possível carregar seus ingressos',
                                message: state.errorMessage,
                              ),
                            ),
                            LoadStatus.empty => _centered(
                              const StateMessage(
                                icon: Icons.confirmation_number_outlined,
                                title: 'Você ainda não possui ingressos',
                                message:
                                    'Seus ingressos para partidas do Goiás aparecerão aqui.',
                              ),
                            ),
                            LoadStatus.success => ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxxl,
                              ),
                              itemCount: state.tickets.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) =>
                                  _TicketCard(ticket: state.tickets[index]),
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = ticket.eventDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final place = [
      ticket.sector,
      ticket.seat,
    ].where((value) => value != null && value.isNotEmpty).join(' · ');

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
          Text(
            ticket.eventName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaRow(icon: Icons.calendar_today_rounded, text: dateLabel),
          if (place.isNotEmpty) ...[
            const SizedBox(height: 4),
            _MetaRow(icon: Icons.event_seat_outlined, text: place),
          ],
        ],
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
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.textHint),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
      ],
    );
  }
}
