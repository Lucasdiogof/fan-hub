import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_tab_empty_state.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Aba ESCALAÇÕES: um time embaixo do outro (duas colunas deixariam os nomes
/// apertados em celular), cada um com escudo, nome e titulares (número +
/// nome). A fonte só traz os titulares — não há reservas, técnico, formação
/// em texto, posição nem goleiro, então nada disso é mostrado. Cada time é
/// tratado sozinho: se só um tem escalação, o outro mostra "ainda não
/// divulgada".
class MatchLineupsSection extends StatelessWidget {
  const MatchLineupsSection({
    required this.match,
    required this.lineups,
    super.key,
  });

  final Match match;
  final MatchLineups? lineups;

  @override
  Widget build(BuildContext context) {
    final data = lineups;
    final home = data?.home;
    final away = data?.away;
    final homeEmpty = home == null || _isEmpty(home);
    final awayEmpty = away == null || _isEmpty(away);
    if (homeEmpty && awayEmpty) {
      return MatchTabEmptyState(
        icon: Icons.groups_outlined,
        message: context.l10n.matchLineupsEmpty,
      );
    }
    return Column(
      children: [
        _TeamLineupCard(team: match.homeTeam, lineup: homeEmpty ? null : home),
        const SizedBox(height: AppSpacing.lg),
        _TeamLineupCard(team: match.awayTeam, lineup: awayEmpty ? null : away),
      ],
    );
  }

  static bool _isEmpty(TeamLineup lineup) =>
      lineup.rows.every((row) => row.isEmpty);
}

class _TeamLineupCard extends StatelessWidget {
  const _TeamLineupCard({required this.team, required this.lineup});

  final Team team;
  final TeamLineup? lineup;

  /// Número 0 é só o valor padrão do parser quando a fonte não traz camisa —
  /// nunca é mostrado como se fosse o número do jogador.
  static const double _numberWidth = 34;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final players = [
      for (final row in lineup?.rows ?? const <List<LineupPlayer>>[]) ...row,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: ClubBadge(team: team, size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  shortTeamName(team.name).toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (players.isEmpty)
            Text(
              l10n.matchLineupsEmpty,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.matchLineupStarters,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
            for (var i = 0; i < players.length; i++)
              _PlayerRow(player: players[i], showDivider: i > 0),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.showDivider});

  final LineupPlayer player;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasNumber = player.jerseyNumber > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _TeamLineupCard._numberWidth,
            child: hasNumber
                ? Container(
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${player.jerseyNumber}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.25,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
