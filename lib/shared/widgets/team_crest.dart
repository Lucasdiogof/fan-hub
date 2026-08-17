import 'package:flutter/material.dart';
import 'package:goias_app/features/match/domain/entities/team_info.dart';

class TeamCrest extends StatelessWidget {
  const TeamCrest({required this.team, this.size = 44, super.key});

  final TeamInfo team;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: team.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: team.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        team.shortName,
        style: TextStyle(
          color: team.color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}
