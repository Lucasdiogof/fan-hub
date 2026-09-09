import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';

/// "Retirar na loja" é club-aware por DADO (`ClubIntegrations.pickupAddress`
/// nullable), nunca por `if (club == 'bragantino')`. `checkout_page.dart`
/// usa exatamente `sl<ClubConfig>().integrations.pickupAddress != null` pra
/// decidir se mostra a opção — os testes aqui verificam essa mesma condição
/// e o guard de `PickupInformation.forActiveClub()`, nunca um placeholder
/// tipo "Loja (indisponível)"/"—".
void main() {
  Future<void> registerClub(ClubConfig config) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(config);
  }

  tearDown(() => sl.reset());

  group('Goiás — endereço real preservado, comportamento intacto', () {
    test('pickupAddress não é null e mantém os dados de sempre', () {
      final pickup = goiasClubConfig.integrations.pickupAddress;
      expect(pickup, isNotNull);
      expect(pickup!.storeName, isNot(contains('indisponível')));
      expect(pickup.street, isNot('—'));
      expect(pickup.city, isNot('—'));
    });

    test(
      'a condição que checkout_page.dart usa pra mostrar "Retirar na loja" é true',
      () async {
        await registerClub(goiasClubConfig);
        final hasPickup = sl<ClubConfig>().integrations.pickupAddress != null;
        expect(hasPickup, isTrue);
      },
    );

    test('PickupInformation.forActiveClub() funciona normalmente', () async {
      await registerClub(goiasClubConfig);
      final info = PickupInformation.forActiveClub();
      expect(info.storeName, isNotEmpty);
      expect(info.fullAddress, isNotEmpty);
    });
  });

  group(
    'Bragantino — sem endereço real, opção some por completo (sem placeholder)',
    () {
      test('pickupAddress é null — nunca um objeto "indisponível"/"—"', () {
        expect(bragantinoClubConfig.integrations.pickupAddress, isNull);
      });

      test(
        'a condição que checkout_page.dart usa pra mostrar "Retirar na loja" é false',
        () async {
          await registerClub(bragantinoClubConfig);
          final hasPickup =
              sl<ClubConfig>().integrations.pickupAddress != null;
          expect(hasPickup, isFalse);
        },
      );

      test(
        'PickupInformation.forActiveClub() lança — nunca inventa endereço',
        () async {
          await registerClub(bragantinoClubConfig);
          expect(
            () => PickupInformation.forActiveClub(),
            throwsA(isA<StateError>()),
          );
        },
      );
    },
  );

  test(
    'nenhum clube tem string de placeholder ("indisponível"/"—") em pickupAddress',
    () {
      for (final config in [goiasClubConfig, bragantinoClubConfig]) {
        final pickup = config.integrations.pickupAddress;
        if (pickup == null) continue; // ausência real, não placeholder
        expect(pickup.storeName, isNot(contains('indisponível')));
        expect(pickup.street, isNot('—'));
        expect(pickup.neighborhood, isNot('—'));
        expect(pickup.city, isNot('—'));
        expect(pickup.state, isNot('—'));
        expect(pickup.zipCode, isNot('—'));
      }
    },
  );
}
