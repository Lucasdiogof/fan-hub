import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Entrada compacta de "próximo jogo" no topo da Loja — mesmos 6 estados de
/// [FeaturedEventCard] (venda aberta/fechada/esgotada, ingresso já
/// comprado, check-in fechado/aberto/confirmado), só que resumida em uma
/// linha de status + um CTA em vez da tela cheia. Tocar sempre leva pra
/// `/tickets`, que já resolve o fluxo completo — este card nunca duplica
/// lógica de compra/check-in, só decide o que mostrar.
class MatchdayEntryCard extends StatelessWidget {
  const MatchdayEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TicketsCubit>(),
      child: const _MatchdayEntryCardView(),
    );
  }
}

class _MatchdayEntryCardView extends StatelessWidget {
  const _MatchdayEntryCardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        final event = state.event;
        // Sem próximo jogo, ou ainda carregando/erro: nenhum card — não
        // vale a pena ocupar o topo da Loja com um estado vazio.
        if (state.status != LoadStatus.success || event == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(context.l10n.storeMatchdaySectionTitle),
              const SizedBox(height: AppSpacing.sm),
              _MatchdayCard(event: event, isMember: state.isMember),
            ],
          ),
        );
      },
    );
  }
}

class _MatchdayCard extends StatelessWidget {
  const _MatchdayCard({required this.event, required this.isMember});

  final TicketEvent event;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final match = event.match;
    final locale = Localizations.localeOf(context).toString();
    final status = _statusFor(context, event, isMember);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tickets'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            // Superfície de serviço/matchday — nunca a mesma cor de um
            // card de produto, pra deixar claro que é outro contexto.
            color: colors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClubBadge(team: match.homeTeam, size: 28),
                        const SizedBox(width: 6),
                        Text(
                          'x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ClubBadge(team: match.awayTeam, size: 28),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${shortTeamName(match.homeTeam.name)} x ${shortTeamName(match.awayTeam.name)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.kickoff == null
                          ? context.l10n.matchDateToBeConfirmed
                          : '${shortDateLabel(match.kickoff!, locale)} · ${timeLabel(match.kickoff!)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: status.enabled
                            ? colors.primary
                            : colors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: () => context.push('/tickets'),
                style: matchCtaFilledStyle(context, minHeight: 40).merge(
                  FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                child: Text(status.cta),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mesmos 6 estados/textos de `FeaturedEventCard` (`ticketsCheckin*`/
  /// `ticketsSale*`/`ticketsHasOwnTicket*`), resumidos numa linha só — nunca
  /// decide regra nova aqui, só escolhe qual texto já existente mostrar.
  ({String label, String cta, bool enabled}) _statusFor(
    BuildContext context,
    TicketEvent event,
    bool isMember,
  ) {
    final l10n = context.l10n;
    if (isMember) {
      return switch (event.checkInStatus) {
        CheckInStatus.unavailable => (
          label: l10n.ticketsCheckinUnavailableLabel,
          cta: l10n.ticketsCheckinUnavailableButton,
          enabled: false,
        ),
        CheckInStatus.available => (
          label: l10n.ticketsCheckinAvailableLabel,
          cta: l10n.ticketsCheckInButton,
          enabled: true,
        ),
        CheckInStatus.declined => (
          label: l10n.ticketsDeclinedLabel,
          cta: l10n.ticketsChangedMindButton,
          enabled: true,
        ),
        CheckInStatus.confirmed => (
          label: l10n.ticketsCheckinConfirmedLabel,
          cta: l10n.ticketsViewTicketButton,
          enabled: true,
        ),
        CheckInStatus.cancelled || CheckInStatus.closed => (
          label: l10n.ticketsCheckinClosedLabel,
          cta: l10n.ticketsCheckinClosedButton,
          enabled: false,
        ),
      };
    }
    if (event.myTicketForSelf != null) {
      return (
        label: l10n.ticketsHasOwnTicketLabel,
        cta: l10n.ticketsViewTicketButton,
        enabled: true,
      );
    }
    return switch (event.saleStatus) {
      TicketSaleStatus.upcoming => (
        label: l10n.ticketsSaleUpcomingLabel,
        cta: l10n.ticketsSaleUpcomingButton,
        enabled: false,
      ),
      TicketSaleStatus.open => (
        label: l10n.ticketsSaleOpenLabel,
        cta: l10n.ticketsBuyTicketButton,
        enabled: true,
      ),
      TicketSaleStatus.soldOut => (
        label: l10n.ticketsSoldOutLabel,
        cta: l10n.ticketsSoldOutButton,
        enabled: false,
      ),
      TicketSaleStatus.closed => (
        label: l10n.ticketsSaleClosedLabel,
        cta: l10n.ticketsSaleClosedButton,
        enabled: false,
      ),
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: colors.textHint,
        ),
      ),
    );
  }
}
