import 'package:goias_app/features/match/domain/entities/match_event.dart';

class MatchEventDto {
  const MatchEventDto({
    required this.minute,
    required this.side,
    required this.type,
    this.player,
    this.detail,
    this.playerInId,
    this.playerOutId,
  });

  final String minute;
  final String side;
  final String type;
  final String? player;
  final String? detail;
  final int? playerInId;
  final int? playerOutId;

  factory MatchEventDto.fromJson(Map<String, dynamic> json) {
    return MatchEventDto(
      minute: json['minute'] as String? ?? '',
      side: json['side'] as String? ?? 'home',
      type: json['type'] as String? ?? 'other',
      player: json['player'] as String?,
      detail: json['detail'] as String?,
      playerInId: (json['playerInId'] as num?)?.toInt(),
      playerOutId: (json['playerOutId'] as num?)?.toInt(),
    );
  }

  MatchEvent toEntity() {
    return MatchEvent(
      minute: minute,
      side: side == 'away' ? MatchEventSide.away : MatchEventSide.home,
      type: switch (type) {
        'goal' => MatchEventType.goal,
        'yellow_card' => MatchEventType.yellowCard,
        'red_card' => MatchEventType.redCard,
        'substitution' => MatchEventType.substitution,
        _ => MatchEventType.other,
      },
      player: player,
      detail: detail,
      playerInId: playerInId,
      playerOutId: playerOutId,
    );
  }
}
