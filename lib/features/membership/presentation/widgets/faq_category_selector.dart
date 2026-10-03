import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';

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
    // Índice 0 = "Todas" (id nulo); os demais seguem a ordem de [categories].
    final ids = <String?>[null, for (final category in categories) category.id];
    return FanHubTabBar(
      labels: [
        context.l10n.membershipFaqAll,
        for (final category in categories)
          _chipLabel(context, category.id) ?? category.title,
      ],
      selectedIndex: ids.indexOf(selectedCategoryId),
      onChanged: (index) => onSelected(ids[index]),
    );
  }
}
