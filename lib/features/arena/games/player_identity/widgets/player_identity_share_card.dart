import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_dimension_labels.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Card compartilhável — leva o resultado inteiro (perfil + análise + as
/// seis barras + as três referências), nunca um resumo cortado (mesma
/// lição aplicada em `TacticalShareCard`: um card compartilhável que deixa
/// de fora a análise/a visualização principal do resultado é sempre
/// insuficiente). Conteúdo fixo, sempre no MESMO layout independente do
/// tema atual do app — é uma imagem que sai do app, não uma tela nele, por
/// isso cores fixas, não `context.colors`. Nunca renderizado visível na
/// tela; só existe pra ser capturado por `shareFieldImage`.
class PlayerIdentityShareCard extends StatelessWidget {
  const PlayerIdentityShareCard({required this.result, super.key});

  final PlayerIdentityResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = result.closestReferences.isEmpty
        ? null
        : result.closestReferences.first;
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
            l10n.playerIdentityGameTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.playerResultYourProfile,
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
          for (final d in PlayerIdentityDimension.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShareAttributeRow(
                label: d.label,
                value: result.attributes[d],
                highlighted: result.topTraits.contains(d),
              ),
            ),
          if (top != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
            const SizedBox(height: 20),
            Text(
              l10n.playerResultReferencesTitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            for (final affinity in result.closestReferences)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${affinity.reference.name} • ${affinity.reference.period}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      l10n.playerIdentityAffinityLabel(
                        affinity.affinity.toStringAsFixed(1),
                      ),
                      style: const TextStyle(
                        color: ArenaColors.goiasKeeper,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShareAttributeRow extends StatelessWidget {
  const _ShareAttributeRow({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final int value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? ArenaColors.goiasKeeper : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
