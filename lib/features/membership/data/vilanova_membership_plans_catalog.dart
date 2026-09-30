import 'package:goias_app/features/membership/domain/entities/membership_commitment_period.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';

/// Catálogo oficial do Sócio Tigrão (Vila Nova) — fonte: API pública do
/// provedor de adesão (Ingressos SA, `vilanova.ingressosa.com.br`),
/// endpoint `public/api/v1/socio/benefits-plan`, consultada ao vivo em
/// 2026-09-30 (sem login, dado público do portal). Cruzada com o texto de
/// benefícios visto pelo usuário no fluxo de checkout do site oficial.
///
/// Achado importante: os 4 planos só têm registro de pagamento com
/// `period=ANUAL` na API — nenhum com `period=MENSAL`, mesmo o campo de
/// configuração do plano listando "MENSAL" como periodicidade cadastrada
/// pra OURO/PRATA (provavelmente uma opção nunca ativada no checkout). Por
/// isso `commitmentPeriod: annualContract` nos 4: o valor "/mês" é só a
/// parcela de 11x de uma cobrança anual única, nunca uma assinatura mensal
/// recorrente à parte (ver `MembershipCommitmentPeriod`).
///
/// `monthlyPrice` = valor "a partir de R$X/mês" mostrado no site — CONFERE
/// exatamente com `annualPrice / 11` pra cada plano (a API tem um registro
/// de pagamento com `qtdInstallments: 11` cujo valor por parcela bate com o
/// "/mês" divulgado, plano por plano). `annualPrice` = total anual real
/// (`amount` do registro com `qtyDependents: 0`, `period: ANUAL`) — não é
/// `monthlyPrice * 12` calculado, é o valor que a própria API devolve.
///
/// `includesStadiumAccess`/`allowedSectors` seguem o texto de benefício
/// (mais específico), não o campo genérico `stadiumAccess` da API (que
/// vem `true` até pro TIME DO POVO, cujo benefício real é só um DESCONTO
/// de 75% na compra do ingresso, não acesso livre).
class VilaNovaMembershipPlansCatalog {
  const VilaNovaMembershipPlansCatalog._();

  static const plans = <MembershipPlan>[
    MembershipPlan(
      id: 'vn_socio_time_do_povo',
      name: 'TIME DO POVO',
      tagline: '',
      includesStadiumAccess: false,
      commitmentPeriod: MembershipCommitmentPeriod.annualContract,
      benefits: [
        '20% de desconto no plano semestral/anual da Escolinha de Futebol Tigrinhos do Vila',
        '75% de desconto na compra de 1 ingresso para o Setor B nos jogos de mando do Vila Nova, com compra antecipada na Loja Oficial Nação Colorada em até 3 horas antes da partida (sujeito a disponibilidade)',
        '10% de desconto na Loja Oficial Nação Colorada',
        'Experiências e promoções exclusivas do Sócio Tigrão',
        '1 cupom de R\$ 10,00 por mês no Zé Delivery',
        'Acesso ao Tigrão de Vantagens',
      ],
      prices: [
        MembershipPlanPrice(label: '', monthlyPrice: 20.00, annualPrice: 220.00),
      ],
    ),
    MembershipPlan(
      id: 'vn_socio_prata',
      name: 'PRATA',
      tagline: '',
      includesStadiumAccess: true,
      allowedSectors: ['B'],
      commitmentPeriod: MembershipCommitmentPeriod.annualContract,
      benefits: [
        'Livre acesso ao setor B (mando de campo do Vila Nova F.C)',
        '20% de desconto no plano semestral/anual da Escolinha de Futebol Tigrinhos do Vila',
        '3 cupons de R\$ 10,00 por mês no Zé Delivery',
        'Pode acrescentar até 3 dependentes que sejam parentes de primeiro grau (R\$ 453,75 anual por dependente)',
        '10% de desconto na Loja Oficial Nação Colorada',
        'Experiências e promoções exclusivas do Sócio Tigrão',
        'Acesso ao Tigrão de Vantagens',
      ],
      prices: [
        MembershipPlanPrice(label: '', monthlyPrice: 55.00, annualPrice: 605.00),
      ],
    ),
    MembershipPlan(
      id: 'vn_socio_ouro',
      name: 'OURO',
      tagline: '',
      includesStadiumAccess: true,
      allowedSectors: ['A', 'B'],
      highlight: true,
      commitmentPeriod: MembershipCommitmentPeriod.annualContract,
      benefits: [
        '6 cupons de R\$ 10,00 por mês no Zé Delivery',
        'Livre acesso aos setores A e B (mando de campo Vila Nova F.C)',
        '15% de desconto na Loja Oficial Nação Colorada',
        '20% de desconto no plano semestral/anual da Escolinha de Futebol Tigrinhos do Vila',
        'Após 1 ano de adimplência, apto a votar na eleição da presidência executiva do clube, estando adimplente na data da convocação',
        'Experiências e promoções exclusivas do Sócio Tigrão',
        'Pode acrescentar até 3 dependentes que sejam parentes de primeiro grau, sendo o 1º dependente gratuito (R\$ 632,50 anual por dependente)',
        'Acesso ao Tigrão de Vantagens',
      ],
      prices: [
        MembershipPlanPrice(
          label: '',
          monthlyPrice: 115.00,
          annualPrice: 1265.05,
        ),
      ],
    ),
    MembershipPlan(
      id: 'vn_socio_rubi',
      name: 'RUBI',
      tagline: '',
      includesStadiumAccess: true,
      allowedSectors: ['A', 'B'],
      commitmentPeriod: MembershipCommitmentPeriod.annualContract,
      benefits: [
        'Livre acesso aos setores A e B (mando de campo Vila Nova F.C)',
        'Pode acrescentar 1 dependente sem nenhum custo adicional',
        '15% de desconto na Loja Oficial Nação Colorada',
        '20% de desconto no plano semestral/anual da Escolinha de Futebol Tigrinhos do Vila',
        '1 cortesia adicional por jogo em casa',
        'Após 1 ano de adimplência, apto a votar na eleição da presidência executiva do clube, estando adimplente na data da convocação',
        'Experiências e promoções exclusivas do Sócio Tigrão',
        'Kit exclusivo para o titular do plano: camisa oficial de jogo, boné e certificado de sócio rubi digital (enviado por e-mail)',
        '1 cortesia adicional por jogo fora de casa',
        'Grupo de Whatsapp exclusivo com conteúdo direcionado aos sócios',
        'Acesso ao Tigrão de Vantagens',
        '13 cupons de R\$ 10,00 por mês no Zé Delivery',
      ],
      prices: [
        MembershipPlanPrice(
          label: '',
          monthlyPrice: 250.00,
          annualPrice: 2750.00,
        ),
      ],
    ),
  ];
}
