/// Estado da venda de ingressos pro público geral (não-sócio) numa partida.
enum TicketSaleStatus { upcoming, open, soldOut, closed }

/// Estado do check-in do sócio pra uma partida específica — combina janela
/// de tempo (unavailable/available/closed) com a decisão do usuário
/// (declined/confirmed/cancelled, guardada no repositório).
enum CheckInStatus {
  unavailable,
  available,
  declined,
  confirmed,
  cancelled,
  closed,
}

enum TicketStatus { active, cancelled, used, expired, refunded }

enum TicketOrigin { purchase, membershipCheckIn }
