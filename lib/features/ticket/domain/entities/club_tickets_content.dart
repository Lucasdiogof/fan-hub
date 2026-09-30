import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';

/// Conteúdo de ingressos DESTE clube — setores/preços/portões e o texto
/// estruturado de "Informações da partida". Nenhum clube herda o conteúdo
/// de outro: sem isto (`null` em `ClubConfig.ticketsContent`), a feature
/// fica indisponível pra esse clube (ver `MockTicketRepository`), nunca cai
/// pro fixture de um clube diferente. `hasTickets: true` sem isto
/// preenchido é um erro de configuração, não um fallback válido.
class ClubTicketsContent extends Equatable {
  const ClubTicketsContent({
    required this.sectors,
    required this.salesInfoSections,
  });

  final List<TicketSector> sectors;
  final List<MatchInfoSection> salesInfoSections;

  @override
  List<Object?> get props => [sectors, salesInfoSections];
}
