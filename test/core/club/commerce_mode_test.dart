// Auditoria 2026-09-05 — decisão de produto: Loja/Ingressos/Sócio
// continuam DEMO por enquanto. Trava 2 coisas: (1) o Goiás tem os 3 modos
// em demo hoje (nenhum gateway/bilheteria/API oficial existe ainda); (2)
// isso nunca esconde a feature — `hasMembership` continua `true`, demo é
// sobre COMO a feature se comporta, nunca SE ela existe.
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
      'demo nunca esconde a feature — hasMembership/hasStore/hasTickets continuam true',
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
      'Membership/Tickets continuam false; Loja ligou em 2026-09-09 (catálogo real, ver bragantino_store) — sempre em demo, nenhum gateway real',
      () {
        final capabilities = bragantinoClubConfig.capabilities;
        expect(capabilities.hasMembership, isFalse);
        expect(capabilities.hasStore, isTrue);
        expect(capabilities.hasTickets, isFalse);
        // O valor em si (demo) é só o default seguro — Membership/Tickets
        // por ainda não terem feature nenhuma ligada, Loja por decisão de
        // produto explícita (nunca checkout real com redbullshop.com.br).
        expect(capabilities.storeCommerceMode, CommerceMode.demo);
        expect(capabilities.ticketCommerceMode, CommerceMode.demo);
        expect(capabilities.membershipCommerceMode, CommerceMode.demo);
      },
    );
  });
}
