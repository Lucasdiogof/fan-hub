import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_step_contact.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_step_personal.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_step_security.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_stepper.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Cadastro em 3 passos — mesma estrutura do
/// `MembershipRegistrationPage`/`MembershipRegistrationCubit`: um único
/// `RegisterCubit` hospeda os dados dos 3 passos, então voltar uma etapa
/// nunca perde o que já foi digitado (os valores vivem no cubit, não no
/// widget do passo). Cada passo é reconstruído ao trocar (um `switch`, não
/// `IndexedStack`) — o único efeito colateral disso é o "campo tocado" de
/// cada `FieldTouch` resetar ao revisitar um passo (o valor em si nunca
/// some). Cada passo próprio faz `Expanded(ListView) + botão fixo`, então
/// só os campos rolam — cabeçalho/stepper (aqui) e o CTA (dentro do passo)
/// ficam sempre visíveis, mesmo com o teclado aberto.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(context.read<AuthCubit>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<RegisterCubit>();
    final step = context.select((RegisterCubit c) => c.state.step);

    return PopScope(
      canPop: step == RegisterStep.personal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cubit.back();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BackButtonCircle(
                          onTap: () {
                            if (!cubit.back()) context.pop();
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          context.l10n.authRegisterTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RegisterStepper(step: step),
                      ],
                    ),
                  ),
                  Expanded(
                    child: switch (step) {
                      RegisterStep.personal => const RegisterStepPersonal(),
                      RegisterStep.contact => const RegisterStepContact(),
                      RegisterStep.security => const RegisterStepSecurity(),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
