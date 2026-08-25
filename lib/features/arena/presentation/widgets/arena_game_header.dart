import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';

/// Cabeçalho padrão dos 4 jogos da Arena (Quiz, Adivinhe a Escalação,
/// Adivinhe o Jogador, Quem Vestiu o Manto) — antes cada um tinha o próprio
/// título com tamanho/cor/alinhamento diferentes (um sem título nenhum).
/// Um componente só: botão voltar + título verde (cor da marca, não
/// `textPrimary`, pra ler como título mesmo) + [subtitle] opcional embaixo
/// + [trailing] opcional (pílula de progresso, contador etc.) na ponta.
class ArenaGameHeader extends StatelessWidget {
  const ArenaGameHeader({
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        BackButtonCircle(onTap: onBack),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textHint,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
