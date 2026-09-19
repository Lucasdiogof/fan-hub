/// Nomes de produto/feature específicos do clube — `PRODUCT_NAME_CLUB_
/// SPECIFIC` na classificação da auditoria (nunca `GENERIC_FEATURE_NAME`:
/// "Arena Esmeraldina" é este nome, não um rótulo genérico de menu).
/// Hoje esses textos moram espalhados em ~16 chaves l10n (`app_pt.arb`
/// etc.) — isto documenta o CONCEITO, não migra l10n. Nenhum consumidor
/// real lê isto ainda.
class ClubProductNaming {
  const ClubProductNaming({
    required this.arenaName,
    required this.passportName,
    required this.storeName,
    required this.membershipProgramName,
    this.appDisplayName,
  });

  /// `'Arena Esmeraldina'`.
  final String arenaName;

  /// `'Passaporte Esmeraldino'`.
  final String passportName;

  /// `'Goiás Store'`.
  final String storeName;

  /// `'Sócio Esmeralda'`.
  final String membershipProgramName;

  /// Nome do PRODUTO (não do clube) mostrado em metadata de nível de app
  /// — hoje só `MaterialApp.title`. `null` cai pra
  /// `identity.displayName` (comportamento de sempre, ex.: Bragantino).
  /// Existe pro Goiás desde a correção Guideline 4.1(a) da Apple: o app
  /// nunca deve se identificar (nome/metadata) como se fosse o produto
  /// oficial de um terceiro — `'Esmeraldino App'`, nunca `'Goiás
  /// Esporte Clube'`. Referências factuais ao clube dentro do conteúdo
  /// ("Goiás x Avaí") continuam de fora, isto é só o rótulo do app em si.
  final String? appDisplayName;
}
