import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Card de alternativa da Identidade Futebolística — mesma linguagem visual
/// do `_OptionTile` do Quiz (Material+InkWell, borda, padding), mas SEM
/// certo/errado: só "selecionada" ou não. Nunca verde de acerto, nunca
/// vermelho de erro, nunca ícone de check/X — só um destaque de seleção
/// (cor + borda mais grossa + ícone neutro de "escolhido").
class TacticalOptionTile extends StatelessWidget {
  const TacticalOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final TacticalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = selected
        ? colors.primary.withValues(alpha: 0.10)
        : colors.surface;
    final border = selected ? colors.primary : colors.border;
    final foreground = selected ? colors.primary : colors.textPrimary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: selected,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.radio_button_checked_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ] else ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.radio_button_off_rounded,
                    color: colors.textHint,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
