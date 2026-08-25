import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Card da Home que leva pra "Escalação da Torcida" — só aparece quando há
/// próximo jogo (ver `HomePage`, que já só renderiza isto dentro de um
/// `if (state.nextMatch != null)`). Fica logo abaixo do hero do próximo
/// jogo, propositalmente "claro" (fundo `colors.surface`) pra não competir
/// com aquele card escuro.
///
/// Não repete adversário/data/horário/campeonato — isso já está no card de
/// Próximo Jogo logo acima. O foco aqui é só a funcionalidade em si, com
/// dois estados conforme [hasVoted] (resolvido pelo `HomeCubit` por
/// `matchId`, nunca um booleano global — ver `home_cubit.dart`).
class CrowdLineupHomeCard extends StatelessWidget {
  const CrowdLineupHomeCard({
    required this.hasVoted,
    required this.onTap,
    super.key,
  });

  final bool hasVoted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = hasVoted
        ? 'Escalação da Torcida'
        : 'Monte a escalação da torcida';
    final description = hasVoted
        ? 'Veja como a torcida está escalando o Goiás para o próximo jogo.'
        : 'Escale o Goiás para o próximo jogo e veja o time mais escalado pela torcida.';
    final ctaLabel = hasVoted ? 'VER ESCALAÇÃO DA TORCIDA' : 'ESCALAR AGORA';

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
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _TacticsBoardIllustration(),
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
                  child: Text(ctaLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TacticsBoardIllustration extends StatelessWidget {
  const _TacticsBoardIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          AppAssets.tacticsBoardIllustration,
          height: 108,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
