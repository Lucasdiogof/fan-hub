import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/network/api_client.dart';

import '../club/synthetic_club_config.dart';

/// `resolveApiBaseUrl` é o ponto de maior risco da mudança pra
/// `workerBaseUrl` (ver auditoria Matches/football) — se resolver errado,
/// o Goiás inteiro para de falar com QUALQUER backend. Cobre exatamente
/// isso, mais a regra absoluta: um clube sem `workerBaseUrl` NUNCA cai pro
/// Worker de outro clube (nem o do Goiás, nem qualquer host real).
void main() {
  test('Goiás: resolve pra workerBaseUrl real (sem --dart-define)', () {
    expect(
      resolveApiBaseUrl(goiasClubConfig),
      'https://goias-app.lucasdiogo1234.workers.dev',
    );
    expect(
      resolveApiBaseUrl(goiasClubConfig),
      goiasClubConfig.integrations.workerBaseUrl,
    );
  });

  test(
    'clube sintético (Bragantino-like, workerBaseUrl=null): NUNCA resolve pro host do Goiás',
    () {
      final resolved = resolveApiBaseUrl(syntheticClubBConfig);
      expect(resolved, isNot(goiasClubConfig.integrations.workerBaseUrl));
      expect(resolved, isNot(contains('goias')));
    },
  );

  test(
    'clube sintético: resolve pra um host reservado (.invalid), nunca um host real',
    () {
      expect(resolveApiBaseUrl(syntheticClubBConfig), contains('.invalid'));
    },
  );
}
