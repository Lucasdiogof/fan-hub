import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_state.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_review_page.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_registration_stepper.dart';
import 'package:goias_app/features/membership/presentation/widgets/selected_plan_banner.dart';
import 'package:goias_app/features/membership/presentation/widgets/steps/access_data_step.dart';
import 'package:goias_app/features/membership/presentation/widgets/steps/address_step.dart';
import 'package:goias_app/features/membership/presentation/widgets/steps/personal_data_step.dart';
import 'package:goias_app/features/profile/domain/entities/app_user.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';

typedef MembershipRegistrationArgs = ({MembershipPlan plan, MembershipPlanPrice price});

/// Hospeda o cubit único do fluxo (3 etapas + revisão) — voltar uma etapa
/// não recria o cubit, então nada digitado se perde. Retorna `true` via
/// `context.pop` quando a associação é enviada, pra quem empurrou esta rota
/// saber que precisa recarregar o estado de sócio.
class MembershipRegistrationPage extends StatelessWidget {
  const MembershipRegistrationPage({required this.plan, required this.price, super.key});

  final MembershipPlan plan;
  final MembershipPlanPrice price;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<AppUser>>(
      future: sl<UserRepository>().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Center(child: CircularProgressIndicator(color: context.colors.primary)),
          );
        }
        final user = switch (snapshot.data) {
          Success(:final data) => data,
          _ => null,
        };
        return BlocProvider(
          create: (_) => MembershipRegistrationCubit(sl<MembershipRepository>(), plan: plan, price: price, prefill: user),
          child: const _MembershipRegistrationView(),
        );
      },
    );
  }
}

class _MembershipRegistrationView extends StatelessWidget {
  const _MembershipRegistrationView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: BlocBuilder<MembershipRegistrationCubit, MembershipRegistrationState>(
                builder: (context, state) {
                  if (state.submitStatus == LoadStatus.success) {
                    return _SubmittedConfirmation(onDone: () => context.pop(true));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      SelectedPlanBanner(plan: state.plan, price: state.price, onChangePlan: () => context.pop()),
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
                                    RegistrationStep.access => const AccessDataStep(),
                                    RegistrationStep.personal => const PersonalDataStep(),
                                    RegistrationStep.address => const AddressStep(),
                                  },
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _NavButtons(state: state),
                    ],
                  );
                },
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
          Expanded(child: _outlinedButton(colors, 'VOLTAR', loading ? null : cubit.back)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canConfirm ? cubit.submit : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                    )
                  : const Text('CONFIRMAR ASSOCIAÇÃO'),
            ),
          ),
        ],
      );
    }

    final isFirst = state.step == RegistrationStep.access;
    final isLast = state.step == RegistrationStep.address;
    final VoidCallback continueAction = switch (state.step) {
      RegistrationStep.access => cubit.continueFromAccess,
      RegistrationStep.personal => cubit.continueFromPersonal,
      RegistrationStep.address => cubit.continueToReview,
    };

    return Row(
      children: [
        if (!isFirst) ...[
          Expanded(child: _outlinedButton(colors, 'VOLTAR', cubit.back)),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          flex: isFirst ? 1 : 2,
          child: ElevatedButton(
            onPressed: continueAction,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
            child: Text(isLast ? 'REVISAR DADOS' : 'CONTINUAR'),
          ),
        ),
      ],
    );
  }

  Widget _outlinedButton(AppColors colors, String label, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
      child: Text(label),
    );
  }
}

class _SubmittedConfirmation extends StatelessWidget {
  const _SubmittedConfirmation({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
              child: Icon(Icons.hourglass_top_rounded, color: colors.primary, size: 32),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Solicitação preparada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A integração definitiva com o Sócio Esmeralda será adicionada posteriormente. Assim que estiver disponível, sua adesão será confirmada oficialmente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
                child: const Text('VOLTAR AO SÓCIO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
