import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_state.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_review_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_success_page.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_registration_stepper.dart';
import 'package:goias_app/features/membership/presentation/widgets/selected_plan_banner.dart';
import 'package:goias_app/features/membership/presentation/widgets/steps/access_data_step.dart';
import 'package:goias_app/features/membership/presentation/widgets/steps/address_step.dart';
import 'package:goias_app/features/membership/presentation/widgets/steps/personal_data_step.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

typedef MembershipRegistrationArgs = ({
  MembershipPlan plan,
  MembershipPlanPrice price,
});

/// Hospeda o cubit único do fluxo (3 etapas + revisão) — voltar uma etapa
/// não recria o cubit, então nada digitado se perde. Depois que a
/// associação é concluída, quem empurrou esta rota recebe via `context.pop`
/// `'memberArea'` (CTA principal, ir pro Sócio) ou `'home'` (CTA
/// secundário/voltar do sistema), pra saber que precisa recarregar o
/// estado de sócio ou só voltar ao Início.
class MembershipRegistrationPage extends StatelessWidget {
  const MembershipRegistrationPage({
    required this.plan,
    required this.price,
    super.key,
  });

  final MembershipPlan plan;
  final MembershipPlanPrice price;

  @override
  Widget build(BuildContext context) {
    // Sem pré-preenchimento nenhum — o titular preenche os próprios dados
    // do zero, mesmo os que existem no cadastro do app (nome, e-mail).
    return BlocProvider(
      create: (_) => MembershipRegistrationCubit(
        sl<MembershipRepository>(),
        sl<AddressRepository>(),
        plan: plan,
        price: price,
      ),
      child: const _MembershipRegistrationView(),
    );
  }
}

class _MembershipRegistrationView extends StatelessWidget {
  const _MembershipRegistrationView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final isDone = state.submitStatus == LoadStatus.success;
    final canPop =
        !isDone && state.step == RegistrationStep.access && !state.showReview;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isDone) {
          // Contratação já terminou — back físico/gesture não deve voltar
          // pro formulário concluído, então se comporta como o CTA
          // secundário (Início).
          context.pop('home');
        } else {
          cubit.back();
        }
      },
      child: isDone
          ? MembershipSuccessPage(
              membership: state.membership!,
              holderName: state.data.fullName,
              holderCpf: state.data.cpf,
              onGoToMemberArea: () => context.pop('memberArea'),
              onGoHome: () => context.pop('home'),
            )
          : Scaffold(
              backgroundColor: colors.background,
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ContentWidth.form.maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BackButtonCircle(onTap: () => context.pop()),
                          const SizedBox(height: AppSpacing.lg),
                          SelectedPlanBanner(
                            plan: state.plan,
                            price: state.price,
                            onChangePlan: () => context.pop(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (!state.showReview) ...[
                            MembershipRegistrationStepper(step: state.step),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          Expanded(
                            child: state.showReview
                                ? const MembershipReviewPage()
                                : ListView(
                                    children: [
                                      switch (state.step) {
                                        RegistrationStep.access =>
                                          const AccessDataStep(),
                                        RegistrationStep.personal =>
                                          const PersonalDataStep(),
                                        RegistrationStep.address =>
                                          const AddressStep(),
                                      },
                                    ],
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _NavButtons(state: state),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.state});

  final MembershipRegistrationState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final colors = context.colors;

    if (state.showReview) {
      final loading = state.submitStatus == LoadStatus.loading;
      final canConfirm = state.regulationAccepted && !loading;
      return Row(
        children: [
          Expanded(
            child: _outlinedButton(
              colors,
              context.l10n.commonBack,
              loading ? null : cubit.back,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canConfirm ? cubit.submit : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(context.l10n.membershipConfirmAssociation),
            ),
          ),
        ],
      );
    }

    final isFirst = state.step == RegistrationStep.access;
    final VoidCallback continueAction = switch (state.step) {
      RegistrationStep.access => cubit.continueFromAccess,
      RegistrationStep.personal => cubit.continueFromPersonal,
      RegistrationStep.address => cubit.continueToReview,
    };

    return Row(
      children: [
        if (!isFirst) ...[
          Expanded(
            child: _outlinedButton(colors, context.l10n.commonBack, cubit.back),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: continueAction,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            child: Text(context.l10n.commonContinue),
          ),
        ),
      ],
    );
  }

  Widget _outlinedButton(
    AppColors colors,
    String label,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      child: Text(label),
    );
  }
}
