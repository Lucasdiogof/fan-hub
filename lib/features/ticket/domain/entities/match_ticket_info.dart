import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';

/// Dados operacionais de venda/check-in de uma partida — janelas de tempo e
/// setores. Vem do fixture mock hoje (ver `TicketFixture`), mas é o formato
/// que uma API real de ingressos preencheria amanhã; nenhuma Widget lê data
/// nenhuma direto, sempre através daqui.
class MatchTicketInfo extends Equatable {
  const MatchTicketInfo({
    required this.matchId,
    required this.saleOpensAt,
    required this.checkInOpensAt,
    this.checkInClosesAt,
    required this.canCancelCheckIn,
    required this.sectors,
  });

  final String matchId;
  final DateTime saleOpensAt;
  final DateTime checkInOpensAt;

  /// `null` = check-in fica aberto até o apito inicial.
  final DateTime? checkInClosesAt;

  /// Regra de negócio, não constante fixa — futuramente a API pode bloquear
  /// cancelamento perto do horário da partida.
  final bool canCancelCheckIn;
  final List<TicketSector> sectors;

  List<TicketSector> get checkInSectors =>
      sectors.where((sector) => sector.availableForCheckIn).toList();

  @override
  List<Object?> get props => [
    matchId,
    saleOpensAt,
    checkInOpensAt,
    checkInClosesAt,
    canCancelCheckIn,
    sectors,
  ];
}

/// [kickoff] `null` é tratado como "ainda não encerrou" (mesma convenção já
/// usada pra `Match.kickoff` no resto do app).
TicketSaleStatus computeSaleStatus({
  required MatchTicketInfo info,
  required DateTime? kickoff,
  required DateTime now,
}) {
  if (kickoff != null && now.isAfter(kickoff)) return TicketSaleStatus.closed;
  if (now.isBefore(info.saleOpensAt)) return TicketSaleStatus.upcoming;
  if (info.sectors.isNotEmpty && info.sectors.every((s) => s.soldOut)) {
    return TicketSaleStatus.soldOut;
  }
  return TicketSaleStatus.open;
}

CheckInStatus computeCheckInWindowStatus({
  required MatchTicketInfo info,
  required DateTime? kickoff,
  required DateTime now,
}) {
  if (kickoff != null && now.isAfter(kickoff)) return CheckInStatus.closed;
  if (info.checkInClosesAt != null && now.isAfter(info.checkInClosesAt!)) {
    return CheckInStatus.closed;
  }
  if (now.isBefore(info.checkInOpensAt)) return CheckInStatus.unavailable;
  return CheckInStatus.available;
}
