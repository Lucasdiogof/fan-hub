/// Nível do Passaporte — progressão puramente visual, baseada
/// no total de jogos vividos (`PassportSummary.totalMatches`). Nenhuma
/// regra de negócio depende disso; é só o que decide a moldura/selo do
/// card (ver `passport_level_style.dart`) — por isso mora no domain sem
/// nenhuma dependência de Flutter/l10n, e o motivo de existir centralizado
/// aqui é não espalhar limiares de nível pelos widgets.
/// Os nomes aqui são as FAIXAS, não o rótulo mostrado: quem tem identidade
/// de clube é o rótulo, que vem de `ClubPassportContent`. Chamar a faixa de
/// `verdaoRaiz` daria um enum do Goiás renderizando "Braga Raiz" no
/// Bragantino — o tipo de incoerência que vira bug de leitura mais tarde.
enum PassportLevel { starter, present, bleacher, roots, legend }

PassportLevel passportLevelForMatches(int totalMatches) {
  if (totalMatches >= 100) return PassportLevel.legend;
  if (totalMatches >= 50) return PassportLevel.roots;
  if (totalMatches >= 25) return PassportLevel.bleacher;
  if (totalMatches >= 10) return PassportLevel.present;
  return PassportLevel.starter;
}
