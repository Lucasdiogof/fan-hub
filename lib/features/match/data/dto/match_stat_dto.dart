import 'package:goias_app/features/match/domain/entities/match_stat.dart';

class MatchStatDto {
  const MatchStatDto({
    required this.title,
    required this.unit,
    this.home,
    this.away,
  });

  final String title;
  final String unit;
  final num? home;
  final num? away;

  factory MatchStatDto.fromJson(Map<String, dynamic> json) {
    return MatchStatDto(
      title: json['title'] as String? ?? '',
      unit: json['unit'] as String? ?? 'count',
      home: json['home'] as num?,
      away: json['away'] as num?,
    );
  }

  MatchStat toEntity() {
    return MatchStat(
      title: title,
      unit: unit == 'percent' ? MatchStatUnit.percent : MatchStatUnit.count,
      home: home,
      away: away,
    );
  }
}
