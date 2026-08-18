import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.showArrow = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null && !loading;

    return Opacity(
      opacity: enabled || loading ? 1 : 0.55,
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: SizedBox(
            height: 54,
            child: Center(
              child: loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                        ),
                        if (loadingLabel != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            loadingLabel!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.onPrimary,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: colors.onPrimary,
                          ),
                        ),
                        if (showArrow) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(Icons.arrow_forward_rounded, size: 19, color: colors.onPrimary),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
