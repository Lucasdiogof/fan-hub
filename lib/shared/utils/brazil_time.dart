import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _brazilTimeZoneName = 'America/Sao_Paulo';

/// Chamar uma vez no bootstrap do app (antes do primeiro uso de [toBrazilTime]).
void initializeBrazilTimeZone() => tz_data.initializeTimeZones();

/// Converte um instante absoluto pro horário de Brasília, independente do
/// fuso do dispositivo — importante pro Web/PWA, onde o usuário pode estar
/// em qualquer lugar do mundo. Nunca usar `DateTime.toLocal()` para exibir
/// horário de partida: isso reflete o fuso do dispositivo, não o do Brasil.
DateTime toBrazilTime(DateTime instant) {
  final location = tz.getLocation(_brazilTimeZoneName);
  return tz.TZDateTime.from(instant, location);
}

/// `Z`/offset explícito no final da string (nunca confunde com os traços
/// da própria data, que nunca ficam colados no fim).
final _hasExplicitTimeZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// Parseia um horário de partida garantindo o INSTANTE ABSOLUTO correto,
/// nunca dependente do fuso do aparelho (correção 2026-09-12: a contagem
/// regressiva da Home variava com o fuso configurado no celular).
///
/// - Se [raw] já vem com offset/`Z` explícito (ex.: as pernas de mata-mata,
///   que a OneFootball manda em UTC real), respeita esse valor — nunca
///   aplica `-03:00` de novo por cima.
/// - Se vem "nu" (sem timezone — convenção histórica do Worker pra
///   `/current-round`/`/team`/`/fixtures`, que manda hora de parede do
///   Brasil sem marcar o fuso, ver `utcToNaiveBrazilLocal` no Worker),
///   interpreta como America/Sao_Paulo. Brasil não tem mais horário de
///   verão desde 2019 — offset fixo `-03:00`, sem precisar do banco de
///   fusos completo só pra isto.
///
/// Sempre devolve um instante em UTC (`.toUtc()`) — comparações com
/// `DateTime.now()` (`.difference()`, `.isBefore()`, `.compareTo()`) saem
/// certas em QUALQUER fuso de dispositivo; pra EXIBIR a data/hora, sempre
/// passar o resultado por [toBrazilTime] antes (nunca `.toLocal()`).
DateTime? parseKickoffInstant(String? raw) {
  if (raw == null) return null;
  final withTimeZone = _hasExplicitTimeZone.hasMatch(raw) ? raw : '$raw-03:00';
  return DateTime.parse(withTimeZone).toUtc();
}
