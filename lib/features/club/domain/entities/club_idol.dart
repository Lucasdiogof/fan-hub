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
    this.position,
    this.period,
    this.photoAsset,
  });

  final String name;

  /// 1 = nome forte/confirmado; 2 = pool editorial; 3 = candidato a
  /// revisar. Nunca exibir tier 2/3 com o mesmo peso visual do tier 1 sem
  /// checagem adicional. É metadado EDITORIAL/de evidência — nunca
  /// aparece pro torcedor (ver [isPublishable]).
  final int tier;

  /// `true` só quando a fonte pesquisada chamou a pessoa de "ídolo" (ou
  /// equivalente) explicitamente — controla que TEXTO usar (ver
  /// `description`), nunca inferido pelo tier.
  final bool evidenceExplicitIdol;

  /// Já redigida com a formulação segura pro nível de evidência — nunca
  /// "um dos maiores ídolos" pra quem tem `evidenceExplicitIdol=false`.
  final String description;

  /// `null` enquanto a posição não tiver sido levantada com fonte — a UI
  /// simplesmente não mostra a linha, nunca preenche com um palpite pela
  /// época/nome.
  final String? position;

  /// Período no clube (ex.: "1988-1991"), `null` até existir fonte.
  final String? period;

  /// Foto REAL do jogador — asset local (histórico, `lib/assets/branding/
  /// idols/`) ou URL remota (CDN oficial, quando a pessoa segue no elenco
  /// atual — reaproveitar a mesma foto de lá é melhor que uma nova).
  /// `null` enquanto não existir foto de verdade — a UI cai pras iniciais,
  /// nunca numa imagem genérica fingindo ser a pessoa.
  final String? photoAsset;

  /// Só o que pode ir pro torcedor hoje. Tier 2 e 3 ficam de fora de
  /// propósito: as descrições deles dizem, literalmente, "revisão
  /// editorial pendente"/"ainda em revisão" — publicar isso como fato
  /// confirmado quebraria a regra de status de dado do projeto (nada
  /// PENDING/REVIEW chega ao usuário como definitivo). Quando um nome for
  /// promovido a tier 1 com fonte, ele aparece sem precisar mexer na UI.
  bool get isPublishable => tier == 1;
}
