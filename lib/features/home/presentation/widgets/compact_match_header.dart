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
import 'package:goias_app/shared/widgets/live_pulse_dot.dart';

/// Faixa compacta ("ticker" de partida) fixada no topo da Home enquanto o
/// hero grande (`NextMatchSection`) está fora da tela — mesma partida,
/// segunda representação visual. Puramente apresentacional: nunca busca
/// dado nem faz polling próprio, sempre recebe [match] já resolvido por
/// quem a monta (`home_page.dart`) — a mesma fonte de verdade do hero,
/// nunca uma segunda consulta independente.
class CompactMatchHeader extends StatelessWidget {
  const CompactMatchHeader({required this.match, this.onTap, super.key});

  final Match match;
  final VoidCallback? onTap;

  bool get _isLive =>
      match.status == MatchStatus.live || match.status == MatchStatus.halftime;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.brandDark,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaLine(match: match, isLive: _isLive),
              const SizedBox(height: 6),
              Row(
                children: [
                  ClubBadge(team: match.homeTeam, size: 26, onDark: true),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      shortTeamName(match.homeTeam.name).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  _CenterMarker(match: match, isLive: _isLive),
                  Expanded(
                    child: Text(
                      shortTeamName(match.awayTeam.name).toUpperCase(),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ClubBadge(team: match.awayTeam, size: 26, onDark: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.match, required this.isLive});

  final Match match;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    if (isLive) {
      final isReallyLive = match.status == MatchStatus.live;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReallyLive) ...[
            LivePulseDot(color: colors.cta, size: 6),
            const SizedBox(width: 6),
          ],
          Text(
            [
              matchStatusLabel(l10n, match.status).toUpperCase(),
              if (isReallyLive && match.minute != null) match.minute!,
            ].join(' • '),
            style: TextStyle(
              color: isReallyLive ? colors.cta : Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      );
    }

    if (match.status == MatchStatus.finished) {
      return _plainMeta(l10n.homeCompactMatchFinished.toUpperCase());
    }

    final kickoffRaw = match.kickoff;
    if (kickoffRaw == null) return _plainMeta(l10n.homeDateToBeConfirmed);

    // `toBrazilTime`, nunca `.toLocal()`: "hoje" é sempre hoje em
    // Brasília, igual ao horário exibido (spec 2026-09-12) — nunca varia
    // com o fuso do aparelho.
    final kickoff = toBrazilTime(kickoffRaw);
    final now = toBrazilTime(DateTime.now());
    final isToday =
        kickoff.year == now.year &&
        kickoff.month == now.month &&
        kickoff.day == now.day;
    final dateLabel = isToday
        ? l10n.homeCompactMatchToday
        : shortDateLabel(kickoff, Localizations.localeOf(context).toString());
    return _plainMeta('$dateLabel • ${timeLabel(kickoff)}');
  }

  Widget _plainMeta(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.75),
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

class _CenterMarker extends StatelessWidget {
  const _CenterMarker({required this.match, required this.isLive});

  final Match match;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final hasScore = match.homeScore != null && match.awayScore != null;
    final showScore =
        (isLive || match.status == MatchStatus.finished) && hasScore;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        showScore ? '${match.homeScore} - ${match.awayScore}' : 'X',
        style: TextStyle(
          color: showScore ? Colors.white : Colors.white.withValues(alpha: 0.5),
          fontSize: showScore ? 17 : 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
