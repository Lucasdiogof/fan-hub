import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';

/// Catálogo oficial dos planos do Massa Bruta (programa de sócio-torcedor
/// do Red Bull Bragantino) — fonte única pro Bragantino, mesmo papel que
/// `MembershipPlansCatalog` tem pro Goiás (ver `ClubConfig.membershipProgram`,
/// nunca lido direto por nenhuma tela).
///
/// FONTE: extraído manualmente de https://massabruta.com.br/Planos em
/// 11/09/2026 (ver `ClubConfig.membershipProgram.sourceLabel`/
/// `sourceUpdatedAt`). O site é uma aplicação ASP.NET renderizada no
/// servidor (Razor) — sem API JSON pública nem estado embutido no HTML
/// (`__NEXT_DATA__`/`window.__INITIAL_STATE__` etc., nenhum encontrado),
/// então não há como buscar isto ao vivo sem raspagem de HTML (frágil,
/// fora do escopo pedido — ver spec M4 §22). Valores conferidos ao vivo
/// contra a página pública, sem inventar nenhum número.
///
/// DATA_GAP conhecidos, INTENCIONALMENTE fora deste catálogo (nunca
/// inventados pra preencher a lacuna):
///   * "Próxima Geração" — plano dependente do titular, sem preço público
///     divulgado na página (`prices` ficaria vazio, e `defaultPrice`/a UI
///     de card assumem pelo menos 1 preço) — precisa de confirmação oficial
///     antes de entrar aqui.
///   * "Asas Diamante" — não aparece na página pública de planos; só existe
///     citado nos Termos e Condições (`/Home/Regulamento`), com regra de
///     no-show própria. Pode ser legado/sob consulta — precisa confirmação
///     do clube antes de virar plano vendável no app.
///   * Política de no-show — o Regulamento só documenta isso pro Asas
///     Diamante; não há confirmação pública de que as mesmas regras valem
///     pros 4 planos abaixo. Não implementado (nem modelado como dado, só
///     como possível próximo passo — ver relatório).
class BragantinoMembershipPlansCatalog {
  const BragantinoMembershipPlansCatalog._();

  static const plans = <MembershipPlan>[
    MembershipPlan(
      id: 'asas-bronze',
      name: 'ASAS BRONZE',
      tagline: 'Torça pelo Massa Bruta com vantagens em qualquer lugar.',
      includesStadiumAccess: false,
      benefits: [
        'Sem possibilidade de check-in nas arquibancadas',
        '20% de desconto em ingressos dos jogos do Red Bull Bragantino como mandante',
        '5% de desconto na Red Bull Shop BR',
        'Experiências exclusivas do programa',
        'Descontos na rede de parceiros',
      ],
      prices: [
        MembershipPlanPrice(
          label: 'Mensal',
          monthlyPrice: 20,
          annualPrice: 240,
        ),
        MembershipPlanPrice(label: 'Anual', monthlyPrice: 10, annualPrice: 120),
      ],
    ),
    MembershipPlan(
      id: 'asas-prata',
      name: 'ASAS PRATA',
      tagline: 'Check-in livre nas arquibancadas Leste e Oeste.',
      includesStadiumAccess: true,
      allowedSectors: ['Leste', 'Oeste'],
      benefits: [
        'Check-in livre nas arquibancadas Leste e Oeste',
        '10% de desconto na Red Bull Shop BR',
        'Experiências exclusivas do programa',
        'Descontos na rede de parceiros',
      ],
      prices: [
        MembershipPlanPrice(
          label: 'Mensal',
          monthlyPrice: 43,
          annualPrice: 516,
        ),
        MembershipPlanPrice(label: 'Anual', monthlyPrice: 33, annualPrice: 396),
      ],
    ),
    MembershipPlan(
      id: 'asas-ouro',
      name: 'ASAS OURO',
      tagline: 'Check-in livre nas arquibancadas Sul, Leste e Oeste.',
      includesStadiumAccess: true,
      allowedSectors: ['Sul', 'Leste', 'Oeste'],
      benefits: [
        'Check-in livre nas arquibancadas Sul, Leste e Oeste',
        '15% de desconto na Red Bull Shop BR',
        'Experiências exclusivas do programa',
        'Descontos na rede de parceiros',
      ],
      prices: [
        MembershipPlanPrice(
          label: 'Mensal',
          monthlyPrice: 150,
          annualPrice: 1800,
        ),
        MembershipPlanPrice(
          label: 'Anual',
          monthlyPrice: 120,
          annualPrice: 1440,
        ),
      ],
    ),
    MembershipPlan(
      id: 'asas-platina',
      name: 'ASAS PLATINA',
      tagline: 'Check-in livre em todas as arquibancadas do Nabizão.',
      includesStadiumAccess: true,
      allowedSectors: ['Norte', 'Sul', 'Leste', 'Oeste'],
      benefits: [
        'Check-in livre nas arquibancadas Norte, Sul, Leste e Oeste',
        '20% de desconto na Red Bull Shop BR',
        'Experiências exclusivas do programa',
        'Descontos na rede de parceiros',
      ],
      prices: [
        MembershipPlanPrice(
          label: 'Mensal',
          monthlyPrice: 290,
          annualPrice: 3480,
        ),
        MembershipPlanPrice(
          label: 'Anual',
          monthlyPrice: 240,
          annualPrice: 2880,
        ),
      ],
    ),
  ];
}
