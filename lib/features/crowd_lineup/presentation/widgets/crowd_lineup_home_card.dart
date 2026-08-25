import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

/// Card da Home que leva pra "Escalação da Torcida" — só aparece quando há
/// próximo jogo (ver `HomePage`, que já só renderiza isto dentro de um
/// `if (state.nextMatch != null)`). Fica logo abaixo do hero do próximo
/// jogo, propositalmente "claro" (fundo `colors.surface`) pra não competir
/// com aquele card escuro — parecido em estrutura com o `MembershipBanner`
/// logo abaixo dele na Home.
class CrowdLineupHomeCard extends StatelessWidget {
  const CrowdLineupHomeCard({
    required this.match,
    required this.onTap,
    super.key,
  });

  final Match match;
  final VoidCallback onTap;

  Team get _opponent {
    final home = match.homeTeam.name.toLowerCase();
    return home.contains('goi') ? match.awayTeam : match.homeTeam;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kickoff = match.kickoff;
    final whenLabel = kickoff != null
        ? '${shortDateLabel(kickoff)} · ${weekdayShortLabel(kickoff)} · ${timeLabel(kickoff)}'
        : 'Data a confirmar';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.banner),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.banner),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    ),
                    child: Icon(
                      Icons.groups_2_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Monte a escalação da torcida',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Escale o Goiás para o próximo jogo e veja o time mais votado pela torcida.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_soccer_rounded,
                      size: 15,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'vs ${_opponent.name} · $whenLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                match.competition,
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  child: const Text('ESCALAR AGORA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
