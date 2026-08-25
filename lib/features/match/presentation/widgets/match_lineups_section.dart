import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';

/// Escalações titulares — só aparece quando o OneFootball já confirmou a
/// lista pra essa partida (nem toda partida tem, ex.: futuras/muito
/// antigas). Só titulares: a fonte não traz banco nem técnico.
class MatchLineupsSection extends StatelessWidget {
  const MatchLineupsSection({required this.lineups, super.key});

  final MatchLineups? lineups;

  @override
  Widget build(BuildContext context) {
    final data = lineups;
    if (data == null) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'ESCALAÇÕES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TeamLineupCard(team: data.home),
        const SizedBox(height: AppSpacing.lg),
        _TeamLineupCard(team: data.away),
      ],
    );
  }
}

class _TeamLineupCard extends StatelessWidget {
  const _TeamLineupCard({required this.team});

  final TeamLineup team;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.teamName.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < team.rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final player in team.rows[i])
                  Expanded(child: _LineupPlayerTile(player: player)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LineupPlayerTile extends StatelessWidget {
  const _LineupPlayerTile({required this.player});

  final LineupPlayer player;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = _NumberCircle(number: player.jerseyNumber, colors: colors);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (player.photo.isEmpty)
              fallback
            else
              ClipOval(
                child: Image.network(
                  player.photo,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => fallback,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : fallback,
                ),
              ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: Text(
                  '${player.jerseyNumber}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          player.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _NumberCircle extends StatelessWidget {
  const _NumberCircle({required this.number, required this.colors});

  final int number;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.secondary,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
