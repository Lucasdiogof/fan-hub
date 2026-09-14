// Auditoria 2026-09-05 — decisão de produto: Loja/Ingressos/Sócio
// continuam DEMO por enquanto (nenhum gateway/bilheteria/API oficial
// existe ainda). Desde 2026-09-14, `hasMembership`/`hasStore`/`hasTickets`
// ficam temporariamente desligados nos dois clubes pro envio às lojas —
// reativar exige um release novo (build + review), nunca um flag remoto
// pós-aprovação (ver comentário em goias_club_config.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  group('CommerceMode — Goiás', () {
    test('Loja/Ingressos/Sócio estão em demo hoje', () {
      final capabilities = goiasClubConfig.capabilities;
      expect(capabilities.storeCommerceMode, CommerceMode.demo);
      expect(capabilities.ticketCommerceMode, CommerceMode.demo);
      expect(capabilities.membershipCommerceMode, CommerceMode.demo);
    });

    test(
      'hasMembership/hasStore/hasTickets escondidos pro envio às lojas (checkout ainda mockado)',
      () {
        final capabilities = goiasClubConfig.capabilities;
        expect(capabilities.hasMembership, isFalse);
        expect(capabilities.hasStore, isFalse);
        expect(capabilities.hasTickets, isFalse);
      },
    );
  });

  group('CommerceMode — Bragantino', () {
    test(
      'hasMembership/hasStore/hasTickets escondidos pro envio às lojas (checkout ainda mockado) — sempre em demo, nenhum gateway real',
      () {
        final capabilities = bragantinoClubConfig.capabilities;
        expect(capabilities.hasMembership, isFalse);
        expect(capabilities.hasStore, isFalse);
        expect(capabilities.hasTickets, isFalse);
        // O valor em si (demo) é só o default seguro — Tickets por ainda
        // não ter feature nenhuma ligada, Loja/Sócio por decisão de produto
        // explícita (nunca checkout/gateway real).
        expect(capabilities.storeCommerceMode, CommerceMode.demo);
        expect(capabilities.ticketCommerceMode, CommerceMode.demo);
        expect(capabilities.membershipCommerceMode, CommerceMode.demo);
      },
    );
  });
}
