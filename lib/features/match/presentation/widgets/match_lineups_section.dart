import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/widgets/match_tab_empty_state.dart';
import 'package:goias_app/shared/utils/image_proxy.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';

/// Aba ESCALAÇÕES: um seletor com o nome dos dois times (mandante e
/// visitante) e, embaixo, o time escolhido num campo — as linhas da formação
/// vêm da fonte (`rows`: ataque no topo, goleiro embaixo, nessa ordem), com
/// foto e número de cada titular.
///
/// A fonte só traz os titulares: nada de reservas, técnico, formação em texto,
/// posição nem goleiro marcado — nada disso é mostrado. Cada time é tratado
/// sozinho: se só um tem escalação, o outro mostra "ainda não divulgada".
class MatchLineupsSection extends StatefulWidget {
  const MatchLineupsSection({
    required this.match,
    required this.lineups,
    super.key,
  });

  final Match match;
  final MatchLineups? lineups;

  @override
  State<MatchLineupsSection> createState() => _MatchLineupsSectionState();
}

class _MatchLineupsSectionState extends State<MatchLineupsSection> {
  /// Escolha do usuário; enquanto não escolhe, abre no primeiro time que já
  /// tem escalação (mandante, se os dois tiverem).
  int? _picked;

  static bool _isEmpty(TeamLineup? lineup) =>
      lineup == null || lineup.rows.every((row) => row.isEmpty);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = widget.lineups?.home;
    final away = widget.lineups?.away;
    final homeEmpty = _isEmpty(home);
    final awayEmpty = _isEmpty(away);
    if (homeEmpty && awayEmpty) {
      return MatchTabEmptyState(
        icon: Icons.groups_outlined,
        message: l10n.matchLineupsEmpty,
      );
    }
    final selected = _picked ?? (homeEmpty && !awayEmpty ? 1 : 0);
    final lineup = selected == 0 ? home : away;
    final selectedEmpty = selected == 0 ? homeEmpty : awayEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FanHubTabBar(
          labels: [
            shortTeamName(widget.match.homeTeam.name),
            shortTeamName(widget.match.awayTeam.name),
          ],
          selectedIndex: selected,
          onChanged: (index) => setState(() => _picked = index),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (selectedEmpty)
          MatchTabEmptyState(
            icon: Icons.groups_outlined,
            message: l10n.matchLineupsEmpty,
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.matchLineupStarters,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          _Pitch(lineup: lineup!),
        ],
      ],
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({required this.lineup});

  final TeamLineup lineup;

  static const double _rowHeight = 92;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rows = lineup.rows.where((row) => row.isNotEmpty).toList();
    final grass = dark ? const Color(0xFF14502B) : const Color(0xFF1F6B3B);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final minHeight = rows.length * _rowHeight + 36;
        final height = minHeight > width * 1.25 ? minHeight : width * 1.25;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: height,
            child: CustomPaint(
              painter: _PitchPainter(grass: grass),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 18, 6, 18),
                child: Column(
                  children: [
                    for (final row in rows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final player in row)
                              Expanded(child: _PlayerSpot(player: player)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter({required this.grass});

  final Color grass;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = grass);
    // Faixas do gramado.
    final stripe = Paint()..color = Colors.black.withValues(alpha: 0.07);
    const stripes = 8;
    for (var i = 0; i < stripes; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          size.height / stripes * i,
          size.width,
          size.height / stripes,
        ),
        stripe,
      );
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const inset = 10.0;
    final field = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRect(field, line);
    // Meio-campo no topo (o ataque fica em cima).
    canvas.drawLine(field.topLeft, field.topRight, line);
    canvas.drawArc(
      Rect.fromCenter(
        center: field.topCenter,
        width: size.width * 0.28,
        height: size.width * 0.28,
      ),
      0,
      3.14159,
      false,
      line,
    );
    // Área grande e pequena embaixo (lado do goleiro).
    final boxWidth = field.width * 0.6;
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - boxWidth / 2,
        field.bottom - field.height * 0.17,
        boxWidth,
        field.height * 0.17,
      ),
      line,
    );
    final smallWidth = field.width * 0.3;
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - smallWidth / 2,
        field.bottom - field.height * 0.07,
        smallWidth,
        field.height * 0.07,
      ),
      line,
    );
  }

  @override
  bool shouldRepaint(_PitchPainter oldDelegate) => oldDelegate.grass != grass;
}

class _PlayerSpot extends StatelessWidget {
  const _PlayerSpot({required this.player});

  final LineupPlayer player;

  static const double _photo = 42;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasNumber = player.jerseyNumber > 0;
    final fallback = Container(
      width: _photo,
      height: _photo,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      ),
      child: Text(
        hasNumber ? '${player.jerseyNumber}' : '',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
    return Semantics(
      label: hasNumber ? '${player.jerseyNumber} ${player.name}' : player.name,
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (player.photo.isEmpty)
                fallback
              else
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      proxiedImageUrl(player.photo),
                      width: _photo,
                      height: _photo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) => fallback,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : fallback,
                    ),
                  ),
                ),
              if (hasNumber && player.photo.isNotEmpty)
                Positioned(
                  bottom: -3,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Text(
                      '${player.jerseyNumber}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          // Nome completo, até duas linhas; sem reticências.
          Text(
            player.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: Colors.white,
              shadows: [Shadow(color: Color(0xCC000000), blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}
