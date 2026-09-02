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
  });

  /// `'Arena Esmeraldina'`.
  final String arenaName;

  /// `'Passaporte Esmeraldino'`.
  final String passportName;

  /// `'Goiás Store'`.
  final String storeName;

  /// `'Sócio Esmeralda'`.
  final String membershipProgramName;
}
