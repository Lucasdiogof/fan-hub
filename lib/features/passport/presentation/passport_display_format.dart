// Formatação de exibição pro Passaporte — pura apresentação, nunca dado
// novo: só traduz códigos que já vêm do catálogo histórico (`round`) ou
// corta o que o Postgres manda a mais (`match_time` como "16:00:00") pra
// texto legível. Compartilhado entre V1 e V2 de propósito — não é regra
// de negócio, é formatação, então não faz sentido duplicar por variante.

/// `match_time` chega do Supabase como "HH:MM:SS" (coluna `time`). O app
/// nunca mostra segundos.
String? shortMatchTime(String? rawTime) {
  if (rawTime == null || rawTime.length < 5) return rawTime;
  return rawTime.substring(0, 5);
}

/// Os códigos abaixo são os que realmente aparecem no catálogo histórico
/// fornecido (`round` no JSON de origem) — nunca um valor inventado. Só
/// traduz o que dá pra ter certeza (abreviação padrão de futebol ou o
/// mesmo padrão já escrito por extenso em outro registro do próprio
/// dataset); qualquer código fora dessa lista volta cru, nunca chuta.
final _knownRounds = <String, String>{
  'SF': 'Semifinal',
  'QF': 'Quartas de final',
  'F': 'Final',
  'RQ': 'Repescagem',
  '1F': '1ª fase',
  '2F': '2ª fase',
  '3F': '3ª fase',
  '4F': '4ª fase',
  '5F': '5ª fase',
  '1/8': 'Oitavas de final',
};

final _bareRoundNumber = RegExp(r'^R(\d+)$');
final _singleGroupLetter = RegExp(r'^[A-Z]$');

/// `round` já vem por extenso em boa parte do catálogo (ex.: "1ª fase ·
/// R3", "Quartas") — nesse caso só normaliza o separador. O resto é
/// abreviação de fonte oficial de resultados (R12, SF, QF, F, 1F, letra de
/// grupo) — mapeada aqui.
String? humanizeRound(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();

  if (value.contains('·') || value.contains(' fase') || value.contains('Fase')) {
    return value.replaceAll('·', '—');
  }

  final known = _knownRounds[value];
  if (known != null) return known;

  final bareRound = _bareRoundNumber.firstMatch(value);
  if (bareRound != null) return 'Rodada ${bareRound.group(1)}';

  if (_singleGroupLetter.hasMatch(value)) return 'Grupo $value';

  return value;
}
