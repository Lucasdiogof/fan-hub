import 'package:goias_app/features/match/data/dto/knockout_tie_dto.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';

class KnockoutRoundDto {
  const KnockoutRoundDto({
    required this.id,
    required this.name,
    required this.order,
    required this.status,
    required this.isCurrent,
    required this.ties,
  });

  final String id;
  final String name;
  final int order;
  final String status;
  final bool isCurrent;
  final List<KnockoutTieDto> ties;

  factory KnockoutRoundDto.fromJson(Map<String, dynamic> json) =>
      KnockoutRoundDto(
        id: json['id'] as String,
        name: json['name'] as String,
        order: json['order'] as int? ?? 0,
        status: json['status'] as String? ?? 'ACTIVE',
        isCurrent: json['isCurrent'] as bool? ?? false,
        ties: ((json['ties'] as List?) ?? const [])
            .map((t) => KnockoutTieDto.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  KnockoutRound toEntity() => KnockoutRound(
    id: id,
    name: name,
    order: order,
    status: switch (status) {
      'UPCOMING' => StageStatus.upcoming,
      'COMPLETED' => StageStatus.completed,
      _ => StageStatus.active,
    },
    isCurrent: isCurrent,
    ties: ties.map((t) => t.toEntity()).toList(),
  );
}
