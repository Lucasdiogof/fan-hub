import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Botão primário padrão do app — usado em Auth, Perfil e minigames.
/// Preenche a largura que o pai der: a `Row` interna nunca usa
/// `mainAxisSize.min` com um `Text` sem `Flexible`, porque isso faz o botão
/// só caber em containers tão largos quanto o texto mais longo já usado
/// nele (ex.: "JOGAR NOVAMENTE" cabia em telas de auth, mas estourava
/// dentro do card mais estreito do resultado do pênalti).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.showArrow = false,
    this.color,
    this.borderColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool showArrow;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null && !loading;

    return Opacity(
      opacity: enabled || loading ? 1 : 0.55,
      child: Material(
        color: color ?? colors.primary,
        borderRadius: borderColor == null
            ? BorderRadius.circular(AppRadius.button)
            : null,
        shape: borderColor == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: BorderSide(color: borderColor!, width: 1.5),
              ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: SizedBox(
            height: 54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: loading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          ),
                          if (loadingLabel != null) ...[
                            const SizedBox(width: AppSpacing.md),
                            Flexible(
                              child: Text(
                                loadingLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                          if (showArrow) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                              color: colors.onPrimary,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
