import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Botão primário padrão do app — usado em Auth, Perfil e minigames.
/// Preenche a largura que o pai der: a `Row` interna nunca usa
/// `mainAxisSize.min` com um `Text` sem `Flexible`, porque isso faz o botão
/// só caber em containers tão largos quanto o texto mais longo já usado
/// nele (ex.: "JOGAR NOVAMENTE" cabia em telas de auth, mas estourava
/// dentro do card mais estreito do resultado do pênalti).
///
/// [color]/[borderColor] são escape hatches — na ausência deles o botão
/// decide sozinho pelo tema atual: preenchido com [AppColors.primary] no
/// light, e com [AppColors.ctaGreen] (verde vívido, sem borda) no dark.
/// Never `if (dark)` espalhado pelas telas — quem chama só passa
/// `label`/`onPressed` e recebe o padrão certo.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.showArrow = false,
    this.icon,
    this.color,
    this.borderColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool showArrow;

  /// Ícone opcional ANTES do texto — ex.: um check de sucesso depois de
  /// uma ação assíncrona concluir (ver `PassportSaveBarV2`). Não confundir
  /// com [showArrow] (depois do texto, indicando avanço/navegação).
  final IconData? icon;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null && !loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? colors.ctaGreen : colors.primary);
    final resolvedBorderColor = borderColor;

    return Opacity(
      // Com `icon` (ex.: check de sucesso), o botão fica desabilitado de
      // propósito (nada a fazer de novo por um instante) mas não deve
      // parecer "apagado" — é um anúncio de estado, não uma ação indisponível.
      opacity: enabled || loading || icon != null ? 1 : 0.55,
      child: Material(
        color: resolvedColor,
        borderRadius: resolvedBorderColor == null
            ? BorderRadius.circular(AppRadius.button)
            : null,
        shape: resolvedBorderColor == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: BorderSide(color: resolvedBorderColor, width: 1.5),
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
                          if (icon != null) ...[
                            Icon(icon, size: 19, color: colors.onPrimary),
                            const SizedBox(width: AppSpacing.sm),
                          ],
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
