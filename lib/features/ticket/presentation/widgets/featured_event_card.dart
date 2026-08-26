import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Card dinâmico "PRÓXIMO EVENTO" da tela de Ingressos — toda a regra de
/// sócio/não-sócio/venda/check-in mora aqui (montada a partir de
/// `TicketEvent`+`isMember`, nunca decidida de novo na página que usa este
/// widget).
class FeaturedEventCard extends StatelessWidget {
  const FeaturedEventCard({
    required this.event,
    required this.isMember,
    required this.onCheckIn,
    required this.onBuyTicket,
    required this.onViewTicket,
    required this.onUndoCheckIn,
    super.key,
  });

  final TicketEvent event;
  final bool isMember;
  final VoidCallback onCheckIn;
  final VoidCallback onBuyTicket;
  final void Function(Ticket ticket) onViewTicket;
  final VoidCallback onUndoCheckIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final match = event.match;
    final locale = Localizations.localeOf(context).toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.competition,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: colors.primary,
                  ),
                ),
              ),
              if (match.round.isNotEmpty)
                Text(
                  match.round.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: _TeamColumn(team: match.homeTeam)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'X',
                  style: TextStyle(
                    color: colors.textHint,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: _TeamColumn(team: match.awayTeam)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: 4,
            children: [
              if (match.kickoff != null) ...[
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: shortDateLabel(match.kickoff!, locale),
                ),
                _InfoItem(
                  icon: Icons.access_time_rounded,
                  label: timeLabel(match.kickoff!),
                ),
              ] else
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: context.l10n.matchDateToBeConfirmed,
                ),
              if (match.stadium.isNotEmpty)
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: match.stadium,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(height: 1, color: colors.border),
          const SizedBox(height: AppSpacing.lg),
          isMember ? _memberSection(context) : _nonMemberSection(context),
        ],
      ),
    );
  }

  Widget _memberSection(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return switch (event.checkInStatus) {
      CheckInStatus.unavailable => _StatusBlock(
        label: l10n.ticketsCheckinUnavailableLabel,
        buttonLabel: l10n.ticketsCheckinUnavailableButton,
        onTap: null,
        subtitle: l10n.ticketsCheckinAvailableFrom(
          fullDateLabel(event.info.checkInOpensAt),
          timeLabel(event.info.checkInOpensAt),
        ),
      ),
      CheckInStatus.available => _StatusBlock(
        label: l10n.ticketsCheckinAvailableLabel,
        buttonLabel: l10n.ticketsCheckInButton,
        onTap: onCheckIn,
        labelColor: colors.primary,
      ),
      CheckInStatus.declined => _StatusBlock(
        label: l10n.ticketsDeclinedLabel,
        buttonLabel: l10n.ticketsChangedMindButton,
        onTap: onCheckIn,
      ),
      CheckInStatus.confirmed => _ConfirmedBlock(
        sectorName: event.confirmedSectorName ?? '',
        onViewTicket: event.checkInTicket == null
            ? null
            : () => onViewTicket(event.checkInTicket!),
        onUndo: event.info.canCancelCheckIn ? onUndoCheckIn : null,
      ),
      CheckInStatus.cancelled || CheckInStatus.closed => _StatusBlock(
        label: l10n.ticketsCheckinClosedLabel,
        buttonLabel: l10n.ticketsCheckinClosedButton,
        onTap: null,
      ),
    };
  }

  Widget _nonMemberSection(BuildContext context) {
    final l10n = context.l10n;
    final myTicket = event.myTicketForSelf;
    if (myTicket != null) {
      return _StatusBlock(
        label: l10n.ticketsHasOwnTicketLabel,
        buttonLabel: l10n.ticketsViewTicketButton,
        onTap: () => onViewTicket(myTicket),
      );
    }
    return switch (event.saleStatus) {
      TicketSaleStatus.upcoming => _StatusBlock(
        label: l10n.ticketsSaleUpcomingLabel,
        buttonLabel: l10n.ticketsSaleUpcomingButton,
        onTap: null,
        subtitle: l10n.ticketsSaleStartsAt(
          fullDateLabel(event.info.saleOpensAt),
          timeLabel(event.info.saleOpensAt),
        ),
      ),
      TicketSaleStatus.open => _StatusBlock(
        label: l10n.ticketsSaleOpenLabel,
        buttonLabel: l10n.ticketsBuyTicketButton,
        onTap: onBuyTicket,
        labelColor: context.colors.primary,
      ),
      TicketSaleStatus.soldOut => _StatusBlock(
        label: l10n.ticketsSoldOutLabel,
        buttonLabel: l10n.ticketsSoldOutButton,
        onTap: null,
      ),
      TicketSaleStatus.closed => _StatusBlock(
        label: l10n.ticketsSaleClosedLabel,
        buttonLabel: l10n.ticketsSaleClosedButton,
        onTap: null,
      ),
    };
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClubBadge(team: team, size: 52),
        const SizedBox(height: AppSpacing.sm),
        Text(
          shortTeamName(team.name).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.label,
    required this.buttonLabel,
    required this.onTap,
    this.subtitle,
    this.labelColor,
  });

  final String label;
  final String buttonLabel;
  final VoidCallback? onTap;
  final String? subtitle;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: labelColor ?? colors.textSecondary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: colors.textHint),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: colors.ctaGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.secondary,
              disabledForegroundColor: colors.textHint,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class _ConfirmedBlock extends StatelessWidget {
  const _ConfirmedBlock({
    required this.sectorName,
    required this.onViewTicket,
    required this.onUndo,
  });

  final String sectorName;
  final VoidCallback? onViewTicket;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              context.l10n.ticketsCheckinConfirmedLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ],
        ),
        if (sectorName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            sectorName,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: onViewTicket,
            style: FilledButton.styleFrom(
              backgroundColor: colors.ctaGreen,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            child: Text(context.l10n.ticketsViewTicketButton),
          ),
        ),
        if (onUndo != null) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onUndo,
            style: TextButton.styleFrom(foregroundColor: colors.textHint),
            child: Text(
              context.l10n.ticketsUndoCheckInButton,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}
