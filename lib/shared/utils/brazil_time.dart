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
