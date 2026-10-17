import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:intl/intl.dart';

/// Aviso de que o conteúdo exibido é a última consulta salva no aparelho
/// (sem rede / falha ao atualizar) e pode estar desatualizado — nunca
/// apresentar cache como dado fresco.
class SavedContentBanner extends StatelessWidget {
  const SavedContentBanner({required this.savedAt, super.key});

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMd(locale).add_Hm().format(savedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: colors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.commonSavedContentNotice(date),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
