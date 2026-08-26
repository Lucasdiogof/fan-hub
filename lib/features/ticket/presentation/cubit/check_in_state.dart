import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';

class CheckInState extends Equatable {
  const CheckInState({
    required this.event,
    this.selectedSectorId,
    this.saving = false,
    this.justConfirmed = false,
    this.confirmedTicket,
    this.justDeclined = false,
    this.errorMessage,
  });

  final TicketEvent event;
  final String? selectedSectorId;
  final bool saving;
  final bool justConfirmed;
  final Ticket? confirmedTicket;
  final bool justDeclined;
  final String? errorMessage;

  CheckInState copyWith({
    TicketEvent? event,
    String? selectedSectorId,
    bool? saving,
    bool? justConfirmed,
    Ticket? confirmedTicket,
    bool? justDeclined,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckInState(
      event: event ?? this.event,
      selectedSectorId: selectedSectorId ?? this.selectedSectorId,
      saving: saving ?? this.saving,
      justConfirmed: justConfirmed ?? this.justConfirmed,
      confirmedTicket: confirmedTicket ?? this.confirmedTicket,
      justDeclined: justDeclined ?? this.justDeclined,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    event,
    selectedSectorId,
    saving,
    justConfirmed,
    confirmedTicket,
    justDeclined,
    errorMessage,
  ];
}
