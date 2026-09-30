import 'package:goias_app/l10n/app_localizations.dart';

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
Map<String, String> _knownRounds(AppLocalizations l10n) => {
  'SF': l10n.passportRoundSemifinal,
  'QF': l10n.passportRoundQuarterfinal,
  'F': l10n.passportRoundFinal,
  'RQ': l10n.passportRoundPlayoff,
  '1F': l10n.passportRoundPhase(1),
  '2F': l10n.passportRoundPhase(2),
  '3F': l10n.passportRoundPhase(3),
  '4F': l10n.passportRoundPhase(4),
  '5F': l10n.passportRoundPhase(5),
  '1/8': l10n.passportRoundOf16,
};

final _bareRoundNumber = RegExp(r'^R(\d+)$');
final _singleGroupLetter = RegExp(r'^[A-Z]$');
final _serieLetter = RegExp(r'Série [A-D]\b');

/// "Campeonato Brasileiro Série A/B/C/D" já deixa a divisão óbvia sem o
/// prefixo — o nome completo só sobra espaço no card e força truncamento
/// (ex.: "Campeonato Brasileiro Série B · Rodada 25" corta o adversário).
/// Só encurta quando o prefixo E a divisão aparecem juntos; outras
/// competições (Goiano, Copa do Brasil, Sub-20 etc.) voltam intactas.
String shortCompetitionLabel(String raw) {
  final value = raw.trim();
  if (!value.toLowerCase().contains('campeonato brasileiro')) return value;
  final match = _serieLetter.firstMatch(value);
  return match == null ? value : match.group(0)!;
}

/// `round` já vem por extenso em boa parte do catálogo (ex.: "1ª fase ·
/// R3", "Quartas") — nesse caso só normaliza o separador. O resto é
/// abreviação de fonte oficial de resultados (R12, SF, QF, F, 1F, letra de
/// grupo) — mapeada aqui.
String? humanizeRound(AppLocalizations l10n, String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();

  if (value.contains('·') ||
      value.contains(' fase') ||
      value.contains('Fase')) {
    return value.replaceAll('·', '—');
  }

  final known = _knownRounds(l10n)[value];
  if (known != null) return known;

  final bareRound = _bareRoundNumber.firstMatch(value);
  if (bareRound != null) {
    return l10n.passportRoundMatchday(int.parse(bareRound.group(1)!));
  }

  if (_singleGroupLetter.hasMatch(value)) {
    return l10n.passportRoundGroup(value);
  }

  return value;
}
