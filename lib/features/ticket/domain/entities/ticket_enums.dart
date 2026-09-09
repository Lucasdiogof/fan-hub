/// Estado da venda de ingressos pro público geral (não-sócio) numa partida.
/// `awayGame` cobre jogos em que o clube ativo não é o mandante — só quem
/// manda o jogo controla a própria bilheteria, mesmo quando o adversário
/// joga na mesma cidade (outros estádios existem).
enum TicketSaleStatus { upcoming, open, soldOut, closed, awayGame }

/// Estado do check-in do sócio pra uma partida específica — combina janela
/// de tempo (unavailable/available/closed) com a decisão do usuário
/// (declined/confirmed/cancelled, guardada no repositório). `awayGame`
/// segue a mesma regra de `TicketSaleStatus.awayGame`: check-in de sócio só
/// existe no estádio do mandante.
enum CheckInStatus {
  unavailable,
  available,
  declined,
  confirmed,
  cancelled,
  closed,
  awayGame,
}

enum TicketStatus { active, cancelled, used, expired, refunded }

enum TicketOrigin { purchase, membershipCheckIn }

/// Tipo de meia-entrada de um ingresso — obrigatório escolher quando a
/// categoria do ingresso é meia-entrada (`TicketPriceCategory.isHalfPrice`).
/// `law` exige comprovante (Lei Federal 12.933/2013); `promotional` é uma
/// promoção do clube, sem exigência de documento.
enum HalfPriceType { law, promotional }
