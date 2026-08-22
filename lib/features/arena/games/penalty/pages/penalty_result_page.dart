import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Resultado real da partida de pênaltis — tela própria, não overlay sobre
/// o jogo. O jogo já foi encerrado (o `GameWidget` anterior foi substituído
/// nesta mesma posição da pilha) antes desta página abrir: nada de Flame
/// rodando escondido atrás.
class PenaltyResultPage extends StatelessWidget {
  const PenaltyResultPage({required this.data, super.key});

  final PenaltyEndData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final misses = data.shotResults.length - data.goals;
    final isPerfect = data.shotResults.isNotEmpty && misses == 0;

    return Scaffold(
      backgroundColor: ArenaColors.arenaBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
              child: FractionallySizedBox(
                widthFactor: 0.88,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RESULTADO FINAL',
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Você converteu ${data.goals} de ${data.shotResults.length} cobranças',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.35),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${data.goals} / ${data.shotResults.length}',
                          style: TextStyle(color: colors.textPrimary, fontSize: 46, fontWeight: FontWeight.w900, height: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PÊNALTIS',
                          style: TextStyle(color: colors.textHint, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                        if (isPerfect) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _Badge(label: 'Perfeito!', color: colors.success),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            for (var i = 0; i < data.shotResults.length; i++)
                              Expanded(child: _ShotChip(index: i, result: data.shotResults[i])),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          data.goals == 1 ? '1 Gol' : '${data.goals} Gols',
                          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Divider(height: 1, color: colors.border),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'PONTUAÇÃO',
                          style: TextStyle(color: colors.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.score} pts',
                          style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (data.isNewRecord)
                          _Badge(label: 'Novo recorde', color: colors.gold)
                        else
                          Text('Recorde: ${data.bestScore} pts', style: TextStyle(color: colors.textHint, fontSize: 12.5)),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          // Reabre o jogo do zero — mais simples e mais robusto que
                          // tentar "reviver" a mesma instância de PenaltyGame depois
                          // de ela já ter sido fechada.
                          child: AppPrimaryButton(
                            label: 'JOGAR NOVAMENTE',
                            onPressed: () => context.pushReplacement('/arena/penalty'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
                            ),
                            child: const Text('VOLTAR À ARENA'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShotChip extends StatelessWidget {
  const _ShotChip({required this.index, required this.result});

  final int index;
  final PenaltyResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = result.colorFor(colors);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${index + 1}º', style: TextStyle(color: colors.textHint, fontSize: 10.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(result.icon, size: 17, color: color),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
    );
  }
}
