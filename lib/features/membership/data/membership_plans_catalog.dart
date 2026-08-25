import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';

/// Catálogo oficial dos planos do Sócio Esmeralda — fonte única. Nenhum outro
/// lugar do app deve declarar nome/preço/benefício de plano; carrossel,
/// página de detalhes e resumo da associação leem todos daqui.
class MembershipPlansCatalog {
  const MembershipPlansCatalog._();

  static const plans = <MembershipPlan>[
    MembershipPlan(
      id: 'nossa-gente',
      name: 'NOSSA GENTE',
      tagline: 'Torça em qualquer lugar, com vantagens fora do estádio.',
      includesStadiumAccess: false,
      benefits: [
        'Cashback mensal no Zé Delivery',
        '5% de desconto na Goiás Store',
        'Benefícios na Rede de Parceiros e promoções',
      ],
      prices: [
        MembershipPlanPrice(label: '', monthlyPrice: 9.99, annualPrice: 119.88),
      ],
    ),
    MembershipPlan(
      id: 'nossa-historia',
      name: 'NOSSA HISTÓRIA',
      tagline: 'Seu lugar garantido nas Cadeiras, partida após partida.',
      includesStadiumAccess: true,
      stadiumSector: 'Cadeiras',
      benefits: [
        'Acesso livre no setor Cadeiras',
        'Cashback mensal no Zé Delivery',
        '5% de desconto na Goiás Store',
        'Benefícios na rede de parceiros, promoções e experiências exclusivas',
        'Plano destinado às condições especiais descritas atualmente pelo programa',
        '50% de desconto na inclusão de dependentes',
      ],
      prices: [
        MembershipPlanPrice(
          label: '',
          monthlyPrice: 39.99,
          annualPrice: 479.88,
        ),
      ],
    ),
    MembershipPlan(
      id: 'nossa-garra',
      name: 'NOSSA GARRA',
      tagline: 'Vibre no Tobogã com o Verdão, sempre por perto.',
      includesStadiumAccess: true,
      stadiumSector: 'Tobogã',
      highlight: true,
      benefits: [
        'Acesso livre no setor Tobogã',
        'Cashback mensal no Zé Delivery',
        '10% de desconto na Goiás Store',
        'Benefícios na rede de parceiros, promoções e experiências exclusivas',
        '50% de desconto na inclusão de dependentes',
      ],
      prices: [
        MembershipPlanPrice(
          label: '',
          monthlyPrice: 59.90,
          annualPrice: 718.80,
        ),
      ],
    ),
    MembershipPlan(
      id: 'nossa-gloria',
      name: 'NOSSA GLÓRIA',
      tagline: 'Conforto e tradição nas Cadeiras, com ainda mais vantagens.',
      includesStadiumAccess: true,
      stadiumSector: 'Cadeiras',
      benefits: [
        'Acesso livre no setor Cadeiras',
        'Cashback mensal no Zé Delivery',
        '10% de desconto na Goiás Store',
        'Benefícios na rede de parceiros, promoções e experiências exclusivas',
        '50% de desconto na inclusão de dependentes',
      ],
      prices: [
        MembershipPlanPrice(
          label: '',
          monthlyPrice: 119.90,
          annualPrice: 1438.80,
        ),
      ],
    ),
    MembershipPlan(
      id: 'nossa-familia',
      name: 'NOSSA FAMÍLIA',
      tagline: 'O Goiás em família, no espaço reservado pra vocês.',
      includesStadiumAccess: true,
      stadiumSector: 'Espaço Família',
      benefits: [
        'Acesso livre no setor Espaço Família',
        'Cashback mensal no Zé Delivery',
        '10% de desconto na Goiás Store',
        'Benefícios na rede de parceiros, promoções e experiências exclusivas',
        'Dependentes diretos',
        'Adição de R\$ 20,00 por filho adicional de até 17 anos',
      ],
      prices: [
        MembershipPlanPrice(
          label: 'Casal',
          monthlyPrice: 99.90,
          annualPrice: 1198.80,
        ),
        MembershipPlanPrice(
          label: 'Casal + 1 Filho',
          monthlyPrice: 119.90,
          annualPrice: 1438.80,
        ),
      ],
    ),
    MembershipPlan(
      id: 'plano-vip',
      name: 'PLANO VIP',
      tagline: 'A experiência mais completa do Sócio Esmeralda.',
      includesStadiumAccess: true,
      stadiumSector: 'Espaço VIP',
      benefits: [
        'Acesso livre no Espaço VIP',
        'Cashback mensal no Zé Delivery',
        '10% de desconto na Goiás Store',
        'Benefícios na rede de parceiros, promoções e experiências exclusivas',
        'Prioridade 1 no check-in',
        'Limitado a 100 pessoas',
      ],
      prices: [
        MembershipPlanPrice(
          label: '',
          monthlyPrice: 199.90,
          annualPrice: 2398.80,
        ),
      ],
    ),
  ];
}
