import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 18, color: colors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message!,
                      style: TextStyle(fontSize: 13, color: colors.error, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
