import 'package:goias_app/shared/domain/player_position.dart';

class SquadPlayer {
  const SquadPlayer({
    required this.id,
    required this.name,
    required this.shirtNumber,
    required this.allowedPositions,
    this.imageUrl,
  });

  final String id;
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
