import 'package:goias_app/shared/domain/player_position.dart';

/// Nível de confiança dos 4 atributos usados nesta arena (POS/CAMISA/BASE/
/// ESTREIA) — nunca inferido a partir do nome, só do que foi realmente
/// pesquisado/confirmado.
enum GuessPlayerDataStatus {
  /// Os 5 atributos estão suficientemente validados.
  verified,

  /// Existe ambiguidade editorial (ex.: camisa histórica ou identidade
  /// duvidosa) — não entra no sorteio até revisão manual.
  review,

  /// Falta pelo menos um dado essencial. Ainda aparece no autocomplete e
  /// pode ser usado como palpite se os campos necessários pra comparação
  /// existirem.
  incomplete,
}

class GuessPlayer {
  const GuessPlayer({
    required this.id,
    required this.name,
    required this.displayName,
    this.aliases = const [],
    this.position,
    this.shirtNumber,
    this.academyClub,
    this.academyHistory = const [],
    this.nationalityCode,
    this.nationalityName,
    this.clubDebutYear,
    this.imageUrl,
    this.dataStatus = GuessPlayerDataStatus.incomplete,
    this.personId,
  });

  /// Nunca usar o nome como chave — jogadores de gerações diferentes podem
  /// compartilhar nome/apelido (ver casos Hugo, Marcão no dataset).
  final String id;

  /// Identidade canônica (people.id, Etapa F3) — null quando a
  /// reconciliação ainda não fechou uma pessoa aprovada com segurança
  /// suficiente pra este jogador (ver guess_players_person_mapping.json).
  /// [id] continua sendo a chave do JOGO (progresso/ranking, nunca muda);
  /// [personId] é a identidade da PESSOA real, quando conhecida.
  final String? personId;
  final String name;
  final String displayName;
  final List<String> aliases;

  /// Posição principal canônica durante a passagem pelo Goiás — uma só,
  /// mesmo que o jogador tenha atuado em mais de uma (isso fica em outros
  /// cadastros do app, não aqui).
  final PlayerPosition? position;

  /// Número mais representativo da passagem pelo Goiás — não é
  /// necessariamente o último nem o atual. `null` se não há evidência.
  final int? shirtNumber;

  /// Clube formador (categoria de base) — exibido na pista. `null` se não
  /// há fonte explícita de base, nunca inventado; a pista mostra
  /// "Desconhecido" e não conta como acerto nem erro.
  final String? academyClub;
  final List<String> academyHistory;

  /// Nacionalidade esportiva/canônica (a da seleção representada, quando
  /// aplicável — ex. Rafael Tolói é Itália, não Brasil). Não faz mais parte
  /// da comparação/pistas do jogo (dado incompleto pra boa parte do
  /// catálogo histórico) — mantido aqui só como metadado, sem uso na arena
  /// por enquanto.
  final String? nationalityCode;
  final String? nationalityName;

  /// Primeiro ano em que o jogador entrou em campo oficialmente pelo
  /// Goiás — nunca ano de contratação/anúncio/retorno.
  final int? clubDebutYear;

  final String? imageUrl;

  final GuessPlayerDataStatus dataStatus;

  /// Tem as pistas que se pode exigir (POS/ESTREIA e a CAMISA quando
  /// [_shirtRequired]) — é o filtro de quem aparece no autocomplete. Não
  /// exige foto nem status `verified` (a foto/status só importam pra ser
  /// sorteado como secreto).
  ///
  /// Clube formador (BASE) não entra: decisão do usuário em 2026-10-02 —
  /// só se preenche com fonte explícita de base, e sem ela a pista aparece
  /// como "Desconhecido" em vez de tirar o jogador do jogo. A camisa segue
  /// a mesma regra de [eligibleAsSecret], senão um secreto pré-2008 sem
  /// camisa poderia ser sorteado sem nunca aparecer como opção de palpite.
  bool get hasFullHints =>
      position != null &&
      clubDebutYear != null &&
      (shirtNumber != null || !_shirtRequired);

  /// Ano a partir do qual existe registro confiável de camisa por temporada
  /// (antes disso as bases só trazem a escalação, sem número). Decisão do
  /// usuário em 2026-10-02: jogador que estreou antes disso pode ser
  /// sorteado com a camisa em branco — nunca um número inventado só para
  /// preencher a pista.
  static const shirtRecordsFromYear = 2008;

  /// Camisa só é obrigatória para quem estreou a partir de
  /// [shirtRecordsFromYear] (ou sem ano conhecido).
  bool get _shirtRequired =>
      clubDebutYear == null || clubDebutYear! >= shirtRecordsFromYear;

  /// Derivado, não guardado: evita uma segunda fonte de verdade que possa
  /// dessincronizar das pistas + foto + status. Quem é sorteável é sempre
  /// também opção de palpite (mesmo [hasFullHints]).
  bool get eligibleAsSecret =>
      dataStatus == GuessPlayerDataStatus.verified &&
      hasFullHints &&
      imageUrl != null;
}
