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
  final List<PlayerPosition> allowedPositions;
  final String? imageUrl;

  bool canPlay(PlayerPosition position) => allowedPositions.contains(position);
}
