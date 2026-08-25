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
    this.goiasDebutYear,
    this.imageUrl,
    this.dataStatus = GuessPlayerDataStatus.incomplete,
  });

  /// Nunca usar o nome como chave — jogadores de gerações diferentes podem
  /// compartilhar nome/apelido (ver casos Hugo, Marcão no dataset).
  final String id;
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
  /// documentado, nunca inventado.
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
  final int? goiasDebutYear;

  final String? imageUrl;

  final GuessPlayerDataStatus dataStatus;

  /// Tem os 4 atributos preenchidos (POS/CAMISA/BASE/ESTREIA) — ou seja,
  /// todo palpite com esse jogador mostra TODAS as dicas, nenhuma coluna
  /// "—". Não exige foto nem status `verified` (a foto/status só importam
  /// pra ser sorteado como secreto).
  bool get hasFullHints =>
      position != null &&
      shirtNumber != null &&
      academyClub != null &&
      goiasDebutYear != null;

  /// Derivado, não guardado: evita uma segunda fonte de verdade que possa
  /// dessincronizar dos 5 campos + status.
  bool get eligibleAsSecret =>
      dataStatus == GuessPlayerDataStatus.verified &&
      hasFullHints &&
      imageUrl != null;
}
