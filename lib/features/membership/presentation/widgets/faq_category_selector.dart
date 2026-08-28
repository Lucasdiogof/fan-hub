import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';

/// Labels curtos só pra caber no chip — o conteúdo/model continua com o
/// título original completo (usado nos cabeçalhos de grupo da lista).
String? _chipLabel(BuildContext context, String categoryId) {
  final l10n = context.l10n;
  return switch (categoryId) {
    'duvidas-gerais' => l10n.membershipFaqChipGeneral,
    'pagamento' => l10n.membershipFaqChipPayment,
    'atendimento' => l10n.membershipFaqChipSupport,
    'acoes' => l10n.membershipFaqChipActions,
    'setores-do-estadio' => l10n.membershipFaqChipStadium,
    'beneficios' => l10n.membershipFaqChipBenefits,
    'planos-e-cancelamento' => l10n.membershipFaqChipPlans,
    'reconhecimento-facial' => l10n.membershipFaqChipFacial,
    'rating' => l10n.membershipFaqChipRating,
    'no-show' => l10n.membershipFaqChipNoShow,
    _ => null,
  };
}

class FaqCategorySelector extends StatelessWidget {
  const FaqCategorySelector({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    super.key,
  });

  final List<FaqCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: context.l10n.membershipFaqAll,
            selected: selectedCategoryId == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: AppSpacing.sm),
            _CategoryChip(
              label: _chipLabel(context, category.id) ?? category.title,
              selected: selectedCategoryId == category.id,
              onTap: () => onSelected(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? colors.onPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
