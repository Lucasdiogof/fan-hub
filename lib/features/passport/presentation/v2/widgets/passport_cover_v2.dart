import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';

/// Capa do passaporte — inspirada num passaporte esportivo, não num
/// dashboard. `deepGreen` é fixo (não muda entre light/dark, ver
/// `AppColors`), então a capa fica idêntica nos dois temas de propósito —
/// é a mesma identidade visual sóbria já usada em hero/banner no resto do
/// app. Nunca mostra "Desde {ano}" sem uma partida marcada de verdade.
class PassportCoverV2 extends StatelessWidget {
  const PassportCoverV2({
    required this.summary,
    required this.selectedYear,
    required this.yearFinishedCount,
    required this.yearMarkedCount,
    super.key,
  });

  final PassportSummary summary;
  final int? selectedYear;
  final int yearFinishedCount;
  final int yearMarkedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final since = summary.firstMarkedMatchDate?.year;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: ColoredBox(
        color: AppColors.light.deepGreen,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -22,
              child: Opacity(
                opacity: 0.07,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    AppAssets.goiasCrestBadge,
                    width: 190,
                    height: 190,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.passportCoverEyebrow,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.passportCoverMatchesLived(summary.totalMatches),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.18,
                    ),
                  ),
                  if (since != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.passportCoverSince(since),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                  if (selectedYear != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.passportCoverSeasonProgress(
                          selectedYear!,
                          yearMarkedCount,
                          yearFinishedCount,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
