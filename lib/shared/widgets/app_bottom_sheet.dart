import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';

class AppBottomSheet {
  const AppBottomSheet._();

  /// Confirmação com título/descrição/botão(ões) — sobe do rodapé no
  /// mobile/tablet, vira `Dialog` centralizado em telas expandidas/largas
  /// (ver `AppModalSheet`, que decide isso; o conteúdo é o mesmo nos dois
  /// casos).
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? description,
    required String confirmLabel,
    IconData? icon,
    Widget? content,
    VoidCallback? onConfirm,
    String? cancelLabel,
    VoidCallback? onCancel,
    bool destructive = false,
    bool isDismissible = true,
  }) {
    return AppModalSheet.show<bool>(
      context,
      isDismissible: isDismissible,
      dialogMaxWidth: 460,
      builder: (sheetContext) => _AppBottomSheetContent(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        icon: icon,
        content: content,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        destructive: destructive,
      ),
    );
  }
}

class _AppBottomSheetContent extends StatelessWidget {
  const _AppBottomSheetContent({
    required this.title,
    required this.description,
    required this.confirmLabel,
    this.icon,
    this.content,
    this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.destructive = false,
  });

  final String title;
  final String? description;
  final String confirmLabel;
  final IconData? icon;
  final Widget? content;
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cancel = cancelLabel;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: colors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: AppSpacing.xl),
              content!,
            ],
            const SizedBox(height: AppSpacing.xxl),
            _PrimaryButton(
              label: confirmLabel,
              // Mesma regra do `AppPrimaryButton`: destrutivo é âmbar
              // sólido nos dois temas; não-destrutivo é `colors.primary`.
              color: destructive ? colors.error : colors.primary,
              onTap: () {
                Navigator.of(context).pop(true);
                onConfirm?.call();
              },
            ),
            if (cancel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  cancel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: colors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
