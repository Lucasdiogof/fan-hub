import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/l10n/app_localizations.dart';

String ticketStatusLabel(AppLocalizations l10n, TicketStatus status) =>
    switch (status) {
      TicketStatus.active => l10n.ticketStatusValid,
      TicketStatus.used => l10n.ticketStatusUsed,
      TicketStatus.cancelled => l10n.ticketStatusCancelled,
      TicketStatus.expired => l10n.ticketStatusExpired,
      TicketStatus.refunded => l10n.ticketStatusRefunded,
    };

String ticketOrderStatusLabel(
  AppLocalizations l10n,
  TicketOrderStatus status,
) => switch (status) {
  TicketOrderStatus.confirmed => l10n.orderStatusConfirmed,
  TicketOrderStatus.pending => l10n.orderStatusPending,
  TicketOrderStatus.cancelled => l10n.orderStatusCancelled,
  TicketOrderStatus.refunded => l10n.orderStatusRefunded,
};
