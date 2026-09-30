/// Como o programa realmente cobra o sócio — não é sobre COMO o preço é
/// exibido (`/mês` aparece nos dois casos), é sobre o CONTRATO por trás:
/// - [monthlyRecurring]: assinatura mensal recorrente de verdade, com opção
///   de pré-pagar o ano com desconto (`MembershipPlanPrice.annualPrice` é
///   essa alternativa). Caso do Sócio Esmeralda (Goiás) e Massa Bruta
///   (Bragantino).
/// - [annualContract]: adesão é SEMPRE anual — não existe opção de
///   assinatura mensal recorrente. O valor "/mês" exibido nos planos é só o
///   equivalente de uma parcela (o programa parcela a cobrança anual, ex.
///   em 11x), nunca uma cobrança mensal independente. Caso do Sócio Tigrão
///   (Vila Nova), confirmado na API pública do provedor de adesão
///   (`benefits-plan`): todo plano só tem registros de pagamento com
///   `period=ANUAL`, nenhum com `period=MENSAL`, mesmo quando o campo de
///   configuração do plano lista "MENSAL" como periodicidade disponível.
enum MembershipCommitmentPeriod { monthlyRecurring, annualContract }
