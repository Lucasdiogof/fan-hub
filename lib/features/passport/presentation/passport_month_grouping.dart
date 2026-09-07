import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:intl/intl.dart';

/// Um mês da linha do tempo do Passaporte, já rotulado no idioma do app.
class PassportMonthGroup {
  const PassportMonthGroup({required this.label, required this.matches});

  final String label;
  final List<PassportMatch> matches;
}

/// Agrupa as partidas por mês, **do mais recente pro mais antigo**.
///
/// A RPC devolve em ordem cronológica, o que fazia a temporada abrir em
/// janeiro: num ano em andamento a pessoa precisava rolar meses inteiros até
/// chegar no jogo de ontem, que é justamente o que ela veio marcar. Dentro do
/// mês a ordem também é decrescente, pra lista inteira ler do mais novo pro
/// mais velho sem inverter no meio.
///
/// Ordena aqui em vez de confiar na ordem que veio do banco — assim mudar a
/// RPC não muda silenciosamente a tela.
///
/// Vive fora das pastas `v1`/`v2` de propósito: as duas variantes são só
/// camada visual, e divergir na ordem faria o comportamento mudar só por
/// trocar o `PassportUiConfig.current`.
List<PassportMonthGroup> groupMatchesByMonth(
  List<PassportMatch> matches,
  String locale,
) {
  final ordered = [...matches]
    ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

  final formatter = DateFormat.yMMMM(locale);
  final groups = <String, List<PassportMatch>>{};
  for (final match in ordered) {
    (groups[formatter.format(match.matchDate)] ??= []).add(match);
  }

  return [
    for (final entry in groups.entries)
      PassportMonthGroup(
        label: entry.key.isEmpty
            ? entry.key
            : entry.key[0].toUpperCase() + entry.key.substring(1),
        matches: entry.value,
      ),
  ];
}
