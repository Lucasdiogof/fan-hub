// Auditoria 2026-09-05 — decisão de produto: Loja/Ingressos/Sócio
// continuam DEMO (nenhum gateway/bilheteria/API oficial existe ainda).
// `hasMembership`/`hasStore`/`hasTickets` ficaram desligados nos dois
// clubes de 2026-09-14 até 2026-09-24 pro envio às lojas; religados nessa
// data quando o projeto deixou de mirar App Store/Play Store (demo
// comercial pros clubes agora — ver comentário em goias_club_config.dart).
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
      'hasMembership/hasStore/hasTickets religados (2026-09-24, checkout ainda mockado)',
      () {
        final capabilities = goiasClubConfig.capabilities;
        expect(capabilities.hasMembership, isTrue);
        expect(capabilities.hasStore, isTrue);
        expect(capabilities.hasTickets, isTrue);
      },
    );
  });

  group('CommerceMode — Bragantino', () {
    test(
      'hasMembership/hasStore religados (2026-09-24, checkout ainda mockado); hasTickets desligado (2026-09-30, sem ticketsContent próprio) — sempre em demo, nenhum gateway real',
      () {
        final capabilities = bragantinoClubConfig.capabilities;
        expect(capabilities.hasMembership, isTrue);
        expect(capabilities.hasStore, isTrue);
        // CORREÇÃO 2026-09-30: estava ligado sem `ticketsContent` próprio —
        // mostrava o fixture hardcoded do Goiás (Serra Dourada, "Goiás
        // E.C.") pro torcedor do Bragantino. Ver `bragantino_club_config.dart`.
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
