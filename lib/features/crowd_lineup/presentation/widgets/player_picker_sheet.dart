import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/player_avatar.dart';

/// Abre o seletor de jogadores pra um slot. Mostra só quem é compatível com
/// a [position] (via `allowedPositions`); quem já está escalado em outro
/// slot aparece desabilitado. Retorna o id escolhido, ou null se fechar.
Future<String?> showPlayerPicker(
  BuildContext context, {
  required PlayerPosition position,
  required Set<String> pickedIds,
  String? currentPlayerId,
}) {
  final colors = context.colors;
  final eligible = playersForPosition(position);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
    ),
    builder: (sheetContext) {
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
                position.full,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              Text(
                'Escolha o jogador para esta posição',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: eligible.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.border),
                  itemBuilder: (context, index) {
                    final player = eligible[index];
                    final used =
                        pickedIds.contains(player.id) &&
                        player.id != currentPlayerId;
                    final selected = player.id == currentPlayerId;
                    return _PlayerRow(
                      player: player,
                      disabled: used,
                      selected: selected,
                      onTap: used
                          ? null
                          : () => Navigator.of(sheetContext).pop(player.id),
                    );
                  },
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
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  final SquadPlayer player;
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
                    Text(
                      player.allowedPositions.map((p) => p.short).join(' · '),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
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
                  'Escalado',
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
