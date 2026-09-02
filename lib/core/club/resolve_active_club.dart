import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_registry.dart';

/// Valor de build — `--dart-define=APP_CLUB=<code>`. Ausente hoje em todo
/// build real (nenhum flavor define isso ainda), o que é esperado nesta
/// fase — ver [resolveActiveClub].
const appClubEnv = String.fromEnvironment('APP_CLUB');

/// Resolve o [ClubConfig] ativo pra este build.
///
/// Duas regras, nunca misturadas:
///   1. `APP_CLUB` AUSENTE (string vazia — o default do
///      `String.fromEnvironment` quando a flag não é passada) -> Goiás,
///      silenciosamente. É o comportamento de HOJE (nenhum build passa
///      `APP_CLUB`) e precisa continuar idêntico enquanto não existir
///      flavor nenhum — essa é a garantia de compatibilidade da M1.
///   2. `APP_CLUB` PRESENTE mas não cadastrado em [clubRegistry] (typo,
///      código de clube que não existe) -> **fail-fast**, `StateError`.
///      Nunca cai pro Goiás por padrão — um typo como `APP_CLUB=goiass`
///      nunca pode publicar silenciosamente um build com dado do Goiás
///      se a intenção era outro clube.
///
/// [envValue] é injetável só pra teste — em produção sempre resolve pro
/// [appClubEnv] real (constante de compilação).
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
