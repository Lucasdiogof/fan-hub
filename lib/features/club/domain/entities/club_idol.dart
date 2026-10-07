import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';

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
    this.fullName,
    this.story,
    this.matches,
    this.goals,
    this.statsAsOf,
    this.statsScope,
    this.tracking,
    this.titles = const [],
    this.highlights = const [],
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

  // ---- Campos da tela de detalhe — todos opcionais. Cada um só existe com
  // fonte; sem fonte fica `null`/vazio e a tela simplesmente não mostra a
  // seção (nunca um traço, um zero ou um palpite no lugar).

  /// Nome de registro, quando confirmado (ex.: "Fernando Lúcio da Costa").
  final String? fullName;

  /// Texto mais longo de trajetória no clube. [description] continua sendo
  /// o resumo curto do card da lista.
  final String? story;

  /// Jogos/gols PELO CLUBE de quem NÃO joga mais — números finais e
  /// auditados. Número só entra com fonte que feche; quando as fontes
  /// divergem, fica `null` (ver o comentário no dataset do clube). Quem ainda
  /// está no elenco NÃO usa estes dois campos: usa [tracking], porque um
  /// número fixo envelhece a cada partida.
  final int? matches;
  final int? goals;

  /// Data de referência (ISO `yyyy-MM-dd`) de [matches]/[goals]. Obrigatória
  /// para quem segue em atividade — número de jogador ativo sem data
  /// envelhece calado.
  final String? statsAsOf;

  /// Quando os números não são o total no clube (ex.: "Primeira passagem,
  /// 2012-2013") — aparece junto dos números.
  final String? statsScope;

  /// Só para ídolo que AINDA joga pelo clube: baseline auditado + vínculo
  /// com o jogador real nas partidas. Os números exibidos passam a ser
  /// baseline + partidas posteriores (ver `ActiveIdolStatsRepository`);
  /// [matches]/[goals]/[statsAsOf] ficam vazios nesses casos.
  final ActiveIdolTracking? tracking;

  /// Títulos conquistados pelo clube com o jogador, já redigidos.
  final List<String> titles;

  /// Campanhas e momentos marcantes, já redigidos.
  final List<String> highlights;

  /// Só abre detalhe quem tem algo além do que o card da lista já mostra —
  /// assim um clube cujo dataset não usa estes campos (Bragantino, Vila
  /// Nova) continua exatamente como era, sem tela vazia atrás do toque.
  bool get hasDetail =>
      fullName != null ||
      story != null ||
      matches != null ||
      goals != null ||
      tracking != null ||
      titles.isNotEmpty ||
      highlights.isNotEmpty;

  /// Só o que pode ir pro torcedor hoje. Tier 2 e 3 ficam de fora de
  /// propósito: as descrições deles dizem, literalmente, "revisão
  /// editorial pendente"/"ainda em revisão" — publicar isso como fato
  /// confirmado quebraria a regra de status de dado do projeto (nada
  /// PENDING/REVIEW chega ao usuário como definitivo). Quando um nome for
  /// promovido a tier 1 com fonte, ele aparece sem precisar mexer na UI.
  bool get isPublishable => tier == 1;
}
