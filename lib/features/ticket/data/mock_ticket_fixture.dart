import 'package:goias_app/features/ticket/domain/entities/club_tickets_content.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';

/// Motor genérico do módulo de venda/check-in — SEM nenhum dado de clube.
/// Setores, preços, portões e o texto de "Informações da partida" vêm de
/// `ClubConfig.ticketsContent` (ver `ClubTicketsContent`); esta classe só
/// aplica esse conteúdo à partida REAL que `FootballRepository` devolver
/// (ver `MockTicketRepository.getFeaturedEvent`). Nunca lido direto por uma
/// Widget: sempre através de `MatchTicketInfo`/`MatchSalesInfo`, que são o
/// formato que a API real preencheria depois.
class TicketFixture {
  const TicketFixture._();

  /// `opensAt` é sempre `kickoff - 48h` — a mesma regra que o backend de
  /// notificações usa pra disparar "check-in aberto"/"ingressos disponíveis"
  /// (ver `supabase/functions/notifications-sync-and-check-access`). Nunca
  /// mais uma data fixa independente: se um dia a regra de negócio mudar
  /// (ex.: 72h), muda só aqui e no Edge Function, nunca dessincronizados.
  /// `kickoff` desconhecido nunca bloqueia o usuário — trata como já aberto.
  static MatchTicketInfo infoFor(
    String matchId,
    DateTime? kickoff,
    ClubTicketsContent content,
  ) {
    final opensAt = kickoff == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : kickoff.subtract(const Duration(hours: 48));
    return MatchTicketInfo(
      matchId: matchId,
      saleOpensAt: opensAt,
      checkInOpensAt: opensAt,
      canCancelCheckIn: true,
      sectors: content.sectors,
    );
  }

  static MatchSalesInfo salesInfoFor(
    String matchId,
    ClubTicketsContent content,
  ) => MatchSalesInfo(matchId: matchId, sections: content.salesInfoSections);
}
