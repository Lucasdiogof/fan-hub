import 'package:goias_app/features/squad/domain/club_history_entry.dart';

class SquadMember {
  const SquadMember({
    required this.id,
    required this.name,
    required this.position,
    required this.positionGroup,
    this.fullName,
    this.shirtNumber,
    this.birthDate,
    this.nationality,
    this.heightCm,
    this.foot,
    this.photoUrl,
    this.clubHistory = const [],
  });

  final String id;
  final String name;
  final String? fullName;
  final int? shirtNumber;
  final String position;
  final String positionGroup;
  final DateTime? birthDate;
  final String? nationality;
  final int? heightCm;
  final String? foot;
  final String? photoUrl;
  final List<ClubHistoryEntry> clubHistory;

  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    return years;
  }

  factory SquadMember.fromJson(Map<String, dynamic> json) {
    final history = json['club_history'] as List<dynamic>? ?? const [];
    return SquadMember(
      id: json['id'] as String,
      name: json['name'] as String,
      fullName: json['full_name'] as String?,
      shirtNumber: json['shirt_number'] as int?,
      position: json['position'] as String,
      positionGroup: json['position_group'] as String,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      nationality: json['nationality'] as String?,
      heightCm: json['height_cm'] as int?,
      foot: json['foot'] as String?,
      photoUrl: json['photo_url'] as String?,
      clubHistory: history
          .map((e) => ClubHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
