import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Primitivo compartilhado por todo bottom sheet do app — no mobile/tablet
/// sobe do rodapé como sempre; em telas expandidas/largas (desktop), um
/// sheet colado na borda de baixo fica estranho, então vira um `Dialog`
/// centralizado com largura máxima. Qualquer tela que hoje chama
/// `showModalBottomSheet` direto deveria passar a chamar isto — é o mesmo
/// código de decisão que o `AppBottomSheet` (confirmação com botões) usa,
/// só que aceita qualquer conteúdo em vez de um layout fixo de
/// título/descrição/botão.
class AppModalSheet {
  const AppModalSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
    double dialogMaxWidth = 480,
  }) {
    final colors = context.colors;

    if (context.isAtLeastExpanded) {
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        builder: (dialogContext) => Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.hero),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogMaxWidth),
            child: builder(dialogContext),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.hero),
        ),
      ),
      builder: builder,
    );
  }
}
