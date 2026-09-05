/// Existe distinção real entre "a pesquisa chamou essa pessoa de ídolo,
/// literalmente" e "nome historicamente forte, mas a fonte recuperada não
/// necessariamente usou essa palavra" — nunca promover o segundo caso pro
/// texto do primeiro (ver `ClubIdol.description`, que já vem redigida
/// com a formulação certa pra cada caso).
class ClubIdol {
  const ClubIdol({
    required this.name,
    required this.tier,
    required this.evidenceExplicitIdol,
    required this.description,
  });

  final String name;

  /// 1 = nome forte/confirmado; 2 = pool editorial; 3 = candidato a
  /// revisar. Nunca exibir tier 2/3 com o mesmo peso visual do tier 1 sem
  /// checagem adicional.
  final int tier;

  /// `true` só quando a fonte pesquisada chamou a pessoa de "ídolo" (ou
  /// equivalente) explicitamente — controla que TEXTO usar (ver
  /// `description`), nunca inferido pelo tier.
  final bool evidenceExplicitIdol;

  /// Já redigida com a formulação segura pro nível de evidência — nunca
  /// "um dos maiores ídolos" pra quem tem `evidenceExplicitIdol=false`.
  final String description;
}
