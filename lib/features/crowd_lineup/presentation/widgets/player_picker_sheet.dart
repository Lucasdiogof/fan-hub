import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/position_compatibility.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/player_avatar.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';

const _compatibility = PositionCompatibilityService();

/// Abre o seletor de jogadores pra um slot. Mostra só quem tem algum
/// encaixe com a [position] (exato ou adaptação natural, via
/// `PositionCompatibilityService`) — quem é incompatível nem aparece.
/// `playersForPosition` já devolve em ordem de melhor encaixe; aqui só
/// agrupamos visualmente em "melhor encaixe" (posição exata, primária ou
/// secundária) vs. "também pode atuar" (adaptação). Quem já está escalado
/// em outro slot aparece desabilitado. Retorna o id escolhido, ou null se
/// fechar.
Future<String?> showPlayerPicker(
  BuildContext context, {
  required PlayerPosition position,
  required Set<String> pickedIds,
  String? currentPlayerId,
}) {
  final eligible = playersForPosition(position);
  final bestFit = [
    for (final player in eligible)
      if (_compatibility.fitFor(player, position) != PositionFit.natural)
        player,
  ];
  final adapted = [
    for (final player in eligible)
      if (_compatibility.fitFor(player, position) == PositionFit.natural)
        player,
  ];
  return AppModalSheet.show<String>(
    context,
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                position.full(sheetContext),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              Text(
                context.l10n.crowdPickPlayer,
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final player in bestFit)
                      _PlayerRow(
                        player: player,
                        natural: false,
                        disabled:
                            pickedIds.contains(player.id) &&
                            player.id != currentPlayerId,
                        selected: player.id == currentPlayerId,
                        onTap:
                            pickedIds.contains(player.id) &&
                                player.id != currentPlayerId
                            ? null
                            : () => Navigator.of(sheetContext).pop(player.id),
                      ),
                    if (adapted.isNotEmpty) ...[
                      if (bestFit.isNotEmpty)
                        Divider(height: 1, color: colors.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          context.l10n.crowdAlsoCanPlaySection,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: colors.textHint,
                          ),
                        ),
                      ),
                      for (final player in adapted)
                        _PlayerRow(
                          player: player,
                          natural: true,
                          disabled:
                              pickedIds.contains(player.id) &&
                              player.id != currentPlayerId,
                          selected: player.id == currentPlayerId,
                          onTap:
                              pickedIds.contains(player.id) &&
                                  player.id != currentPlayerId
                              ? null
                              : () => Navigator.of(sheetContext).pop(player.id),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.natural,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  final SquadPlayer player;

  /// true = encaixe por adaptação natural ("Pode atuar"); false = posição
  /// primária ou secundária exata do jogador ("Posição natural").
  final bool natural;
  final bool disabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              PlayerAvatar(player: player, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.allowedPositions
                                .map((p) => p.short(context))
                                .join(' · '),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        if (natural) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.l10n.crowdCanAlsoPlayBadge,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.success,
                  size: 22,
                )
              else if (disabled)
                Text(
                  context.l10n.crowdSelectedPlayer,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textHint,
                  ),
                )
              else
                Text(
                  '#${player.shirtNumber ?? '–'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: colors.textHint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
