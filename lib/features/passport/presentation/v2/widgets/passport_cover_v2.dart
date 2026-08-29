import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_level_style.dart';

/// Capa do passaporte — inspirada num cartão de identidade do torcedor, não
/// num dashboard. `deepGreen` é fixo (não muda entre light/dark, ver
/// `AppColors`), então a capa fica idêntica nos dois temas de propósito —
/// é a mesma identidade visual sóbria já usada em hero/banner no resto do
/// app. De propósito bem enxuta (só eyebrow + selo de nível + headline) —
/// "Desde {ano}" e o progresso da temporada saíram daqui por pedido
/// explícito, pra não repetir o que a tela já mostra logo abaixo.
///
/// A moldura (borda) e o selo de nível vêm de [passportLevelStyleFor] —
/// única fonte da progressão visual por nível, pra este widget nunca
/// precisar de `if`s de nível no meio do layout.
class PassportCoverV2 extends StatelessWidget {
  const PassportCoverV2({required this.summary, super.key});

  final PassportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = passportLevelForMatches(summary.totalMatches);
    final levelStyle = passportLevelStyleFor(level);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(
          color: levelStyle.borderColor,
          width: levelStyle.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: ColoredBox(
          color: AppColors.light.deepGreen,
          child: Stack(
            children: [
              // Textura de fundo — pequena, quase toda cortada pelo canto,
              // opacidade muito baixa: sugere identidade/segurança de
              // documento oficial sem virar "o círculo grande no fundo".
              Positioned(
                right: -46,
                bottom: -46,
                child: Opacity(
                  opacity: 0.05,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      AppAssets.goiasCrestBadge,
                      width: 150,
                      height: 150,
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
                        Expanded(
                          child: Text(
                            l10n.passportCoverEyebrow,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                        _LevelBadge(
                          label: passportLevelLabel(l10n, level),
                          style: levelStyle,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.style});

  final String label;
  final PassportLevelStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: style.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: style.badgeForeground,
        ),
      ),
    );
  }
}
