import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Um atalho do grid de Acesso Rápido — ícone + label curta, sempre
/// reaproveitando uma rota/fluxo que já existe em outro lugar do app.
class QuickAccessItem {
  const QuickAccessItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Atalhos da Home — complementa a bottom nav (navegação estrutural) dando
/// acesso direto a funcionalidades que ainda não têm um card próprio na
/// Home (Clube, Arena e Loja já têm o deles — por isso não entram aqui de
/// novo). [items] já vem pronta e ordenada por quem monta a Home: esta
/// seção só desenha a fileira, sem nenhuma lógica de priorização própria.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({
    required this.title,
    required this.items,
    super.key,
  });

  final String title;
  final List<QuickAccessItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colors.textHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: _QuickAccessTile(item: items[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 22, color: colors.primary),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
