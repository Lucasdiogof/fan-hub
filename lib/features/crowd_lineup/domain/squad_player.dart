import 'package:goias_app/shared/domain/player_position.dart';

class SquadPlayer {
  const SquadPlayer({
    required this.id,
    required this.personId,
    required this.name,
    required this.shirtNumber,
    required this.allowedPositions,
    this.imageUrl,
  });

  /// Chave estável da feature (slug) — é o que fica salvo em
  /// `match_lineup_votes.slots` e circula por toda a gameplay/persistência
  /// já em produção (`playerIdBySlot`, `pickedIds`, `squadById`). Nunca
  /// substituir por [personId] em nenhum desses usos.
  final String id;

  /// Identidade canônica real da pessoa (`people.id`), a mesma resolvida
  /// pra `squad_members.person_id` na Etapa F4. Existe só pra permitir
  /// cruzar este roster hardcoded com o resto da fundação multiclube —
  /// nunca usado pra persistência/gameplay desta feature.
  final String personId;
  final String name;
  final int? shirtNumber;

  /// Ordem importa: o primeiro valor é a posição natural do atleta
  /// (`primaryPosition`), os demais são adaptações reais dele
  /// (`secondaryPositions`) — não uma lista sem hierarquia. É o próprio
  /// `goiasSquad` que já é escrito nessa ordem; ver
  /// `PositionCompatibilityService` pra como isso vira pontuação de encaixe
  /// num slot da formação.
  final List<PlayerPosition> allowedPositions;
  final String? imageUrl;

  PlayerPosition get primaryPosition => allowedPositions.first;
  List<PlayerPosition> get secondaryPositions =>
      allowedPositions.skip(1).toList(growable: false);
}
