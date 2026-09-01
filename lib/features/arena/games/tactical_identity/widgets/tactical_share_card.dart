import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/widgets/tactical_map.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Card compartilhável — conteúdo fixo (marca + jogo + perfil + análise +
/// mapa tático + percentuais + referência principal, o resultado inteiro,
/// não um resumo), sempre no MESMO layout independente do tema atual do
/// app (é uma imagem que sai do app, não uma tela nele — por isso cores
/// fixas, não `context.colors`). Nunca renderizado visível na tela; só
/// existe pra ser capturado por `shareFieldImage` (ver
/// `TacticalIdentityResultPage`).
class TacticalShareCard extends StatelessWidget {
  const TacticalShareCard({
    required this.result,
    required this.ranked,
    super.key,
  });

  final TacticalIdentityResult result;
  final List<CoachAffinity> ranked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = result.closestCoaches.isEmpty ? null : result.closestCoaches.first;
    return Container(
      width: 380,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GOIÁS ESPORTE CLUBE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tacticalIdentityGameTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.tacticalResultYourProfile,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.archetype.displayName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.archetype.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TacticalMap(
              userX: result.x,
              userY: result.y,
              coaches: ranked,
              onCoachTap: (_) {},
            ),
          ),
          const SizedBox(height: 24),
          _ShareBar(
            leftLabel: l10n.tacticalAxisPossession,
            leftPercent: result.possession,
            rightLabel: l10n.tacticalAxisVertical,
            rightPercent: result.vertical,
          ),
          const SizedBox(height: 14),
          _ShareBar(
            leftLabel: l10n.tacticalAxisDogmatic,
            leftPercent: result.dogmatic,
            rightLabel: l10n.tacticalAxisPragmatic,
            rightPercent: result.pragmatic,
          ),
          if (top != null) ...[
            const SizedBox(height: 24),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
            const SizedBox(height: 20),
            Text(
              l10n.tacticalResultMainReference,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              top.coach.coach.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'GOIÁS • ${top.coach.period}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.tacticalIdentityAffinityLabel(top.affinity).toUpperCase(),
              style: const TextStyle(
                color: ArenaColors.goiasKeeper,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Versão simplificada da barra bipolar pro card compartilhável — cores
/// sempre brancas/fixas (nunca `context.colors`, ver comentário da classe).
class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.leftLabel,
    required this.leftPercent,
    required this.rightLabel,
    required this.rightPercent,
  });

  final String leftLabel;
  final int leftPercent;
  final String rightLabel;
  final int rightPercent;

  @override
  Widget build(BuildContext context) {
    final fraction = (rightPercent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$leftLabel $leftPercent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '$rightLabel $rightPercent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Positioned(
                  left: (fraction * width - 5).clamp(0.0, width - 10),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: ArenaColors.goiasKeeper,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
