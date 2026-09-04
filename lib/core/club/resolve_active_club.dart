import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_registry.dart';

/// Valor de build — `--dart-define=APP_CLUB=<code>`. Ausente hoje só no build
/// não-flavored/dev; todo flavor real (`goias`, `bragantino`) passa isto
/// explícito (ver `tooling/multiclub/check_app_club_enforced.mjs`).
const appClubEnv = String.fromEnvironment('APP_CLUB');

/// Resolve o [ClubConfig] ativo pra este build.
///
/// Duas regras, nunca misturadas:
///   1. `APP_CLUB` AUSENTE (string vazia — default do `String.fromEnvironment`
///      quando a flag não é passada) -> Goiás, silenciosamente. É o
///      comportamento de HOJE pro build não-flavored/dev e precisa continuar
///      idêntico (garantia de compatibilidade da M1). Todo flavor NOVO passa
///      `APP_CLUB` explícito, nunca depende disto.
///   2. `APP_CLUB` PRESENTE -> resolve pelo [clubRegistry]; se o código não
///      existir (typo, clube não cadastrado) -> **fail-fast** (`StateError`).
///      Nunca cai pro Goiás por padrão quando um código EXPLÍCITO e inválido é
///      passado — um typo como `APP_CLUB=goiass` nunca publica silenciosamente
///      um build com dado do Goiás se a intenção era outro clube.
///
/// [envValue] é injetável só pra teste — em produção sempre resolve pra
/// [appClubEnv] (constante de compilação real).
ClubConfig resolveActiveClub([String envValue = appClubEnv]) {
  if (envValue.isEmpty) return clubRegistry['goias']!;
  final config = clubRegistry[envValue];
  if (config == null) {
    throw StateError(
      'APP_CLUB="$envValue" não corresponde a nenhum clube em clubRegistry '
      '(disponíveis: ${clubRegistry.keys.join(', ')}). Nunca resolvido pro '
      'Goiás por padrão quando um código EXPLÍCITO e inválido é passado — '
      'corrija o valor de --dart-define=APP_CLUB ou cadastre o clube em '
      'club_registry.dart antes de compilar.',
    );
  }
  return config;
}
