import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/goias_players.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

/// Uma linha do dropdown do Career Path. `label` é só texto de exibição —
/// nunca a identidade. `personId` é a identidade canônica paralela
/// (nullable, quando ainda não sabemos quem é), nunca usada no gameplay:
/// o acerto continua sendo checado contra `CareerPlayer.acceptedAnswers`
/// via [acceptedText], nunca por `personId`.
class CareerAutocompleteSuggestion {
  const CareerAutocompleteSuggestion({
    required this.label,
    required this.normalizedLabel,
    required this.acceptedText,
    this.personId,
  });

  final String label;
  final String normalizedLabel;
  final String acceptedText;
  final String? personId;
}

/// Classificação SEMÂNTICA de uma colisão de texto (2 entradas com o
/// mesmo `normalizedLabel`) — nunca inferida por igualdade de texto
/// sozinha. `personId == null` de um lado NUNCA vira "mesma pessoa" só
/// porque o texto bate — isso seria voltar à inferência por nome que a
/// F6 existe pra eliminar.
enum CareerCollisionType {
  /// Os 2 `personId` são não-nulos e IGUAIS — mesma pessoa comprovada,
  /// seguro tratar como corroboração/ampliação de texto.
  samePerson,

  /// Os 2 `personId` são não-nulos e DIFERENTES — 2 pessoas reais
  /// disputando o mesmo texto. Nunca escondido.
  crossPerson,

  /// Pelo menos um lado tem `personId == null` — não dá pra provar se é
  /// a mesma pessoa ou não. Nunca classificado como [samePerson] só por
  /// causa do texto normalizado bater.
  unknownIdentity,
}

/// Uma colisão de texto entre 2 entradas com o mesmo `normalizedLabel`.
/// [type] é a classificação de IDENTIDADE (nunca decidida por prioridade
/// de fonte). [displayedLabel]/[displayedPersonId] é qual das 2 entradas
/// VENCE A EXIBIÇÃO no dropdown — isso é DISPLAY_PRIORITY, uma decisão
/// editorial (career_players > goias_players) completamente separada de
/// [type]: mesmo quando [type] é [CareerCollisionType.unknownIdentity]
/// ou [CareerCollisionType.crossPerson], ainda escolhemos 1 texto pra
/// mostrar (pra não duplicar visualmente o dropdown) — isso NUNCA prova
/// nem afirma que as 2 entradas são a mesma pessoa.
class CareerNameTextCollision {
  const CareerNameTextCollision({
    required this.normalizedText,
    required this.type,
    required this.displayedLabel,
    required this.displayedPersonId,
    required this.otherLabel,
    required this.otherPersonId,
  });

  final String normalizedText;
  final CareerCollisionType type;
  final String displayedLabel;
  final String? displayedPersonId;
  final String otherLabel;
  final String? otherPersonId;
}

class CareerAutocompleteIndex {
  const CareerAutocompleteIndex({
    required this.suggestions,
    required this.resolveMap,
    required this.collisions,
  });

  /// Linhas visíveis no dropdown — 1 por jogador (`career_players.answer`
  /// ou `goiasPlayers.name`), nunca alias/acceptedAnswers extras — mesmo
  /// comportamento visual de antes da F6 (não amplia o catálogo exibido).
  final List<CareerAutocompleteSuggestion> suggestions;

  /// Texto normalizado digitado -> texto a enviar pro `guess()`. Inclui
  /// aliases/acceptedAnswers (não viram sugestão própria, mas continuam
  /// aceitos ao digitar, igual antes da F6).
  final Map<String, String> resolveMap;

  /// TODA colisão de texto detectada, com [CareerNameTextCollision.type]
  /// explícito — inclui [CareerCollisionType.samePerson] (informativo,
  /// seguro) além de [CareerCollisionType.crossPerson]/
  /// [CareerCollisionType.unknownIdentity] (nunca escondidos).
  final List<CareerNameTextCollision> collisions;

  int get samePersonCollisions =>
      collisions.where((c) => c.type == CareerCollisionType.samePerson).length;
  int get crossPersonCollisions =>
      collisions.where((c) => c.type == CareerCollisionType.crossPerson).length;
  int get unknownIdentityCollisions => collisions
      .where((c) => c.type == CareerCollisionType.unknownIdentity)
      .length;
}

int _sourcePriority(String source) => source == 'career_players' ? 1 : 0;

typedef _Owner = ({
  String source,
  String label,
  String acceptedText,
  String? personId,
});

CareerCollisionType _classifyCollision(String? personIdA, String? personIdB) {
  if (personIdA == null || personIdB == null) {
    return CareerCollisionType.unknownIdentity;
  }
  return personIdA == personIdB
      ? CareerCollisionType.samePerson
      : CareerCollisionType.crossPerson;
}

/// Constrói o índice do autocomplete a partir das 2 fontes.
///
/// 2 decisões INDEPENDENTES quando 2 entradas colidem no mesmo texto
/// normalizado:
///   1. IDENTITY (nunca decidida por prioridade de fonte, só por
///      `personId`) — ver [CareerCollisionType].
///   2. DISPLAY_PRIORITY (`career_players` > `goias_players`, decidida
///      por regra explícita, nunca pela ordem em que os `for` abaixo
///      rodam — trocar a ordem não muda o resultado, testado) — só
///      decide QUAL texto aparece no dropdown, nunca afirma identidade.
CareerAutocompleteIndex buildCareerAutocompleteIndex({
  required List<CareerPlayer> careerPlayers,
  required List<GoiasPlayer> goiasPlayers,
}) {
  final owners = <String, _Owner>{};
  final collisions = <CareerNameTextCollision>[];

  void claim(
    String text,
    String source,
    String acceptedText,
    String? personId,
  ) {
    final key = normalizeName(text);
    final existing = owners[key];
    if (existing == null) {
      owners[key] = (
        source: source,
        label: text,
        acceptedText: acceptedText,
        personId: personId,
      );
      return;
    }
    final candidate = (
      source: source,
      label: text,
      acceptedText: acceptedText,
      personId: personId,
    );
    final type = _classifyCollision(existing.personId, personId);
    // DISPLAY_PRIORITY — só decide o texto exibido, independente de `type`.
    final candidateWinsDisplay =
        _sourcePriority(source) > _sourcePriority(existing.source);
    final displayed = candidateWinsDisplay ? candidate : existing;
    final other = candidateWinsDisplay ? existing : candidate;
    collisions.add(
      CareerNameTextCollision(
        normalizedText: key,
        type: type,
        displayedLabel: displayed.label,
        displayedPersonId: displayed.personId,
        otherLabel: other.label,
        otherPersonId: other.personId,
      ),
    );
    if (candidateWinsDisplay) owners[key] = candidate;
  }

  for (final entry in goiasPlayers) {
    claim(entry.name, 'goias_players', entry.name, entry.personId);
  }
  for (final player in careerPlayers) {
    claim(player.answer, 'career_players', player.answer, player.personId);
  }

  // resolveMap: mesma prioridade de exibição já resolvida acima em
  // `owners`, mais aliases/acceptedAnswers — nunca disputam prioridade de
  // texto principal, só ampliam o que é aceito ao digitar.
  final resolveMap = <String, String>{
    for (final entry in owners.entries) entry.key: entry.value.acceptedText,
  };
  for (final entry in goiasPlayers) {
    for (final alias in entry.aliases) {
      resolveMap.putIfAbsent(normalizeName(alias), () => entry.name);
    }
  }
  for (final player in careerPlayers) {
    for (final answer in player.acceptedAnswers) {
      resolveMap[normalizeName(answer)] = player.answer;
    }
  }

  final suggestions =
      owners.values
          .map(
            (o) => CareerAutocompleteSuggestion(
              label: o.label,
              normalizedLabel: normalizeName(o.label),
              acceptedText: o.acceptedText,
              personId: o.personId,
            ),
          )
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));

  return CareerAutocompleteIndex(
    suggestions: suggestions,
    resolveMap: resolveMap,
    collisions: collisions,
  );
}
