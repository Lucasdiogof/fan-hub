import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';

enum _DotState { done, current, upcoming }

/// Mesmo padrão visual do `MembershipRegistrationStepper` (não reaproveitado
/// direto — está acoplado ao `RegistrationStep` da Sócio, um enum
/// diferente do nosso — mas a mesma linguagem: nunca o `Stepper` do
/// Material, pesado demais pra um formulário curto por etapa).
class RegisterStepper extends StatelessWidget {
  const RegisterStepper({required this.step, super.key});

  final RegisterStep step;

  int get _index => step.index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final labels = [
      l10n.authStepPersonal,
      l10n.authStepContact,
      l10n.authStepSecurity,
    ];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              _StepDot(
                number: i + 1,
                state: i < _index
                    ? _DotState.done
                    : (i == _index ? _DotState.current : _DotState.upcoming),
              ),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < _index ? colors.primary : colors.border,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : (i == 2 ? TextAlign.right : TextAlign.center),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i <= _index ? colors.textPrimary : colors.textHint,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.state});

  final int number;
  final _DotState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = state != _DotState.upcoming;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.primary : colors.surface,
        border: Border.all(
          color: filled ? colors.primary : colors.border,
          width: 1.5,
        ),
      ),
      child: state == _DotState.done
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : colors.textHint,
              ),
            ),
    );
  }
}
