import 'package:flutter/material.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

/// Paleta de fallback pra times sem cor própria conhecida (a API-Football não
/// fornece cor de clube) — determinística por `id`, então o mesmo time
/// sempre cai na mesma cor entre sessões.
const _fallbackPalette = [
  Color(0xFF2E5AA8),
  Color(0xFFB0392B),
  Color(0xFF6E6E6E),
  Color(0xFFAA6C1E),
  Color(0xFF5A3E85),
  Color(0xFF3A7CA5),
  Color(0xFFB0115A),
  Color(0xFF4A5A3E),
];

class TeamDto {
  const TeamDto({required this.id, required this.name, this.logo});

  final int id;
  final String name;
  final String? logo;

  factory TeamDto.fromJson(Map<String, dynamic> json) => TeamDto(
    id: json['id'] as int,
    name: json['name'] as String,
    logo: json['logo'] as String?,
  );

  Team toEntity() => Team(
    id: id,
    name: name,
    shortName: _shortNameFrom(name),
    color: _fallbackPalette[id % _fallbackPalette.length],
    logoUrl: logo,
  );
}

String _shortNameFrom(String name) {
  final trimmed = name.trim();
  final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length == 1) {
    return trimmed.substring(0, trimmed.length.clamp(0, 3)).toUpperCase();
  }
  return words.take(3).map((w) => w[0]).join().toUpperCase();
}
