import 'package:goias_app/core/club/club_config.dart';

/// M3.3 — namespaça uma chave de `SharedPreferences` (ou storage local
/// equivalente) pelo clube ativo: `<clubCode>:<legacyKey>`. Sem isso, um
/// futuro club-b instalado no MESMO storage do Goiás (ex.: trocar
/// `APP_CLUB` sem reinstalar, num ambiente de dev/teste) herdaria carrinho/
/// progresso/recorde do Goiás — nunca aconteceu em produção até hoje (cada
/// flavor tem seu próprio storage isolado pelo SO), mas o app não deveria
/// depender disso silenciosamente pra estar correto.
///
/// `LEGACY_LOCAL_STATE_IS_GOIAS_ONLY`: uma chave antiga, sem namespace,
/// SEMPRE pertence ao Goiás (nunca foi escrita por outro clube, porque
/// nenhum outro existiu ainda) — `migrateLegacyGoiasValue` é o único ponto
/// que lê essa chave antiga, e só quando `clubConfig.identity.code ==
/// 'goias'`. `NO_CROSS_CLUB_LOCAL_STORAGE`: um clube sintético (`club-b`)
/// NUNCA lê a chave legacy, mesmo que exista no mesmo storage.
class ClubScopedStorageKey {
  const ClubScopedStorageKey(this._clubConfig);

  final ClubConfig _clubConfig;

  /// `<clubCode>:<legacyKey>` — usar pra TODA leitura/escrita nova.
  String scoped(String legacyKey) => '${_clubConfig.identity.code}:$legacyKey';

  /// Prefixo pra `key.startsWith(...)` (ex.: limpeza em lote por padrão de
  /// chave, ver `local_game_cache.dart`).
  String scopedPrefix(String legacyPrefix) =>
      '${_clubConfig.identity.code}:$legacyPrefix';
}
