import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class MembershipOption {
  const MembershipOption({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Card de linhas com ícone + label + chevron — reaproveitado em Sócio,
/// Sócio (Ajuda) e Minha Associação.
class MembershipOptionsCard extends StatelessWidget {
  const MembershipOptionsCard({required this.options, super.key});

  final List<MembershipOption> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            InkWell(
              onTap: options[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(options[i].icon, size: 20, color: colors.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        options[i].label,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: colors.textHint),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
