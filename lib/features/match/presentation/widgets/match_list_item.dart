import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/widgets/match_status_label.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class MatchListItem extends StatelessWidget {
  const MatchListItem({required this.match, this.onTap, super.key});

  final Match match;
  final VoidCallback? onTap;

  /// Mostra o placar sempre que ele existir — mesmo com o jogo ainda em
  /// andamento (placar parcial). Antes só mostrava quando `finished`, então
  /// a lista ficava mostrando o horário durante o jogo todo, só trocando
  /// pro placar quando o jogo já tinha acabado.
  bool get _hasScore => match.homeScore != null && match.awayScore != null;

  bool get _isInProgress =>
      match.status == MatchStatus.live || match.status == MatchStatus.halftime;

  // Card "contraste suave de superfícies": o destaque vem da diferença entre
  // o fundo da tela (`colors.background`) e a superfície do card
  // (`colors.surface`), com borda quase imperceptível e sem sombra.
  static const double _radius = 18;
  static const double _badgeSize = 28;

  /// Largura reservada ao placar/horário — a mesma em todo card, pra o
  /// centro ficar no mesmo eixo independente do tamanho dos nomes.
  static const double centerWidth = 72;

  static const _tabularFigures = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    // `toBrazilTime`, nunca `.toLocal()` (spec 2026-09-12).
    final kickoff = match.kickoff != null ? toBrazilTime(match.kickoff!) : null;
    final centerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      fontFeatures: _tabularFigures,
      color: colors.textPrimary,
    );
    final nameStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: colors.textPrimary,
    );
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kickoff != null
                          ? '${shortDateLabel(kickoff, locale)} • ${weekdayShortLabel(kickoff, locale)}'
                          : context.l10n.matchDateToBeConfirmed,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  if (_isInProgress) _LiveBadge(status: match.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ClubBadge(team: match.homeTeam, size: _badgeSize),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TeamName(
                            shortTeamName(match.homeTeam.name),
                            style: nameStyle,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: centerWidth,
                    child: Center(
                      child: _hasScore
                          ? Text(
                              '${match.homeScore} x ${match.awayScore}',
                              style: centerStyle,
                            )
                          : Text(
                              kickoff != null ? timeLabel(kickoff) : '--:--',
                              style: centerStyle,
                            ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _TeamName(
                            shortTeamName(match.awayTeam.name),
                            style: nameStyle,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClubBadge(team: match.awayTeam, size: _badgeSize),
                      ],
                    ),
                  ),
                ],
              ),
              if (match.stadium.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.stadium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nome do time em uma linha: tenta 13, depois 12 e 11 (nunca menos que isso)
/// quando não cabe no espaço entre o escudo e a área central; só se nem a 11
/// couber é que termina em reticências — nunca quebra linha.
class _TeamName extends StatelessWidget {
  const _TeamName(this.name, {required this.style, required this.alignment});

  static const _sizes = [13.0, 12.0, 11.0];

  final String name;
  final TextStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // Mede com o mesmo estilo que o Text vai herdar (família da fonte do tema).
    final base = DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        var chosen = _sizes.last;
        for (final size in _sizes) {
          final painter = TextPainter(
            text: TextSpan(
              text: name,
              style: base.merge(style.copyWith(fontSize: size)),
            ),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final fits = painter.width <= constraints.maxWidth;
          painter.dispose();
          if (fits) {
            chosen = size;
            break;
          }
        }
        return Align(
          alignment: alignment,
          child: Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: alignment == Alignment.centerRight
                ? TextAlign.right
                : TextAlign.left,
            style: style.copyWith(fontSize: chosen),
          ),
        );
      },
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            matchStatusLabel(context.l10n, status).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
