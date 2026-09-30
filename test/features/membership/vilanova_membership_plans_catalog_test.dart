import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/membership/data/vilanova_membership_plans_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/membership_commitment_period.dart';

/// Confirma os 4 planos reais do Sócio Tigrão (2026-09-30, fonte: API
/// pública do provedor de adesão) e o comportamento de periodicidade
/// anual-só — ver `MembershipCommitmentPeriod`/`vilanova_membership_plans_catalog.dart`.
void main() {
  group('VilaNovaMembershipPlansCatalog — 4 planos reais', () {
    test('exatamente 4 planos: TIME DO POVO, PRATA, OURO, RUBI', () {
      final names = VilaNovaMembershipPlansCatalog.plans
          .map((p) => p.name)
          .toList();
      expect(names, ['TIME DO POVO', 'PRATA', 'OURO', 'RUBI']);
    });

    test('todos os planos são de adesão ANUAL, nunca mensal recorrente', () {
      for (final plan in VilaNovaMembershipPlansCatalog.plans) {
        expect(
          plan.commitmentPeriod,
          MembershipCommitmentPeriod.annualContract,
          reason: plan.name,
        );
      }
    });

    test('valores "/mês" exibidos batem com o checkout oficial', () {
      final byName = {
        for (final p in VilaNovaMembershipPlansCatalog.plans) p.name: p,
      };
      expect(byName['RUBI']!.defaultPrice.monthlyPrice, 250.00);
      expect(byName['OURO']!.defaultPrice.monthlyPrice, 115.00);
      expect(byName['PRATA']!.defaultPrice.monthlyPrice, 55.00);
      expect(byName['TIME DO POVO']!.defaultPrice.monthlyPrice, 20.00);
    });

    test(
      'annualPrice é o total REAL da API (nunca monthlyPrice * 12 calculado)',
      () {
        final byName = {
          for (final p in VilaNovaMembershipPlansCatalog.plans) p.name: p,
        };
        // Nenhum destes é monthlyPrice * 12 (250*12=3000, 115*12=1380,
        // 55*12=660, 20*12=240) — são os totais reais que a API devolve,
        // com o desconto/ajuste próprio de cada plano.
        expect(byName['RUBI']!.defaultPrice.annualPrice, 2750.00);
        expect(byName['OURO']!.defaultPrice.annualPrice, 1265.05);
        expect(byName['PRATA']!.defaultPrice.annualPrice, 605.00);
        expect(byName['TIME DO POVO']!.defaultPrice.annualPrice, 220.00);
      },
    );

    test('TIME DO POVO não inclui acesso livre ao estádio (só desconto)', () {
      final timeDoPovo = VilaNovaMembershipPlansCatalog.plans.firstWhere(
        (p) => p.name == 'TIME DO POVO',
      );
      expect(timeDoPovo.includesStadiumAccess, isFalse);
      expect(timeDoPovo.sectorsLabel, isNull);
    });

    test('OURO/RUBI liberam setores A e B; PRATA só o B', () {
      final byName = {
        for (final p in VilaNovaMembershipPlansCatalog.plans) p.name: p,
      };
      expect(byName['OURO']!.sectorsLabel, 'A e B');
      expect(byName['RUBI']!.sectorsLabel, 'A e B');
      expect(byName['PRATA']!.sectorsLabel, 'B');
    });

    test('nenhum plano do Vila coincide com o do Goiás (isolamento)', () {
      final goiasIds = goiasClubConfig.membershipProgram.plans
          .map((p) => p.id)
          .toSet();
      final vilaIds = VilaNovaMembershipPlansCatalog.plans
          .map((p) => p.id)
          .toSet();
      expect(goiasIds.intersection(vilaIds), isEmpty);
    });
  });

  group('vilaNovaClubConfig.membershipProgram — F7', () {
    test('hasMembership ligado com os 4 planos reais', () {
      expect(vilaNovaClubConfig.capabilities.hasMembership, isTrue);
      expect(vilaNovaClubConfig.membershipProgram.plans, hasLength(4));
    });

    test(
      'sem regulamento real -> hasRegulationContent é false (nunca inventa regulamento)',
      () {
        expect(
          vilaNovaClubConfig.membershipProgram.hasRegulationContent,
          isFalse,
        );
      },
    );

    test('CTA aponta pro checkout oficial externo, não pro fluxo mockado', () {
      expect(
        vilaNovaClubConfig.membershipProgram.externalCheckoutUrl,
        'https://vilanova.ingressosa.com.br/selecionar-plano',
      );
    });

    test(
      'Goiás/Bragantino continuam sem externalCheckoutUrl (fluxo interno demo preservado)',
      () {
        expect(
          goiasClubConfig.membershipProgram.externalCheckoutUrl,
          isNull,
        );
      },
    );
  });
}
