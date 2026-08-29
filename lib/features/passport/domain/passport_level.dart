/// Nível do Passaporte Esmeraldino — progressão puramente visual, baseada
/// no total de jogos vividos (`PassportSummary.totalMatches`). Nenhuma
/// regra de negócio depende disso; é só o que decide a moldura/selo do
/// card (ver `passport_level_style.dart`) — por isso mora no domain sem
/// nenhuma dependência de Flutter/l10n, e o motivo de existir centralizado
/// aqui é não espalhar limiares de nível pelos widgets.
enum PassportLevel {
  primeirosPassos,
  torcedorPresente,
  esmeraldinoDeArquibancada,
  verdaoRaiz,
  lendaEsmeraldina,
}

PassportLevel passportLevelForMatches(int totalMatches) {
  if (totalMatches >= 100) return PassportLevel.lendaEsmeraldina;
  if (totalMatches >= 50) return PassportLevel.verdaoRaiz;
  if (totalMatches >= 25) return PassportLevel.esmeraldinoDeArquibancada;
  if (totalMatches >= 10) return PassportLevel.torcedorPresente;
  return PassportLevel.primeirosPassos;
}
