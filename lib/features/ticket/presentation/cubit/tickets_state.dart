import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/shared/state/load_status.dart';

class TicketsState extends Equatable {
  const TicketsState({
    this.status = LoadStatus.initial,
    this.event,
    this.isMember = false,
    this.errorMessage,
  });

  final LoadStatus status;
  final TicketEvent? event;
  final bool isMember;
  final String? errorMessage;

  TicketsState copyWith({
    LoadStatus? status,
    TicketEvent? event,
    bool clearEvent = false,
    bool? isMember,
    String? errorMessage,
  }) {
    return TicketsState(
      status: status ?? this.status,
      event: clearEvent ? null : (event ?? this.event),
      isMember: isMember ?? this.isMember,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, event, isMember, errorMessage];
}
