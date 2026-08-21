import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/shared/state/load_status.dart';

class TicketsState extends Equatable {
  const TicketsState({this.status = LoadStatus.initial, this.featuredEvent, this.errorMessage});

  final LoadStatus status;
  final TicketEvent? featuredEvent;
  final String? errorMessage;

  TicketsState copyWith({
    LoadStatus? status,
    TicketEvent? featuredEvent,
    bool clearEvent = false,
    String? errorMessage,
  }) {
    return TicketsState(
      status: status ?? this.status,
      featuredEvent: clearEvent ? null : (featuredEvent ?? this.featuredEvent),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, featuredEvent, errorMessage];
}
