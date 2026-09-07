import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Identidade 100% do clube — sem nome/marca do app. É a primeira coisa
/// que a área "O Clube" mostra.
class ClubHeader extends StatelessWidget {
  const ClubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final identity = sl<ClubConfig>().identity;
    final tagline =
        identity.headerTagline[Localizations.localeOf(context).languageCode];
    return Column(
      children: [
        const ClubBadge.activeClub(size: 76),
        const SizedBox(height: AppSpacing.lg),
        Text(
          identity.displayName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: colors.textPrimary,
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 4),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: colors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
