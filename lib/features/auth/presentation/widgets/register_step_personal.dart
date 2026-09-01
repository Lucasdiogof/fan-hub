import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_primary_button.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';

/// Passo 1 de 3 — Seus dados. Os VALORES vivem no `RegisterCubit` (nunca se
/// perdem ao voltar); `FieldTouch`/`_submitted` são só estado local de UI,
/// que reseta se o usuário sair e voltar pra este passo — sem problema,
/// já que os campos continuam preenchidos com o valor válido anterior.
class RegisterStepPersonal extends StatefulWidget {
  const RegisterStepPersonal({super.key});

  @override
  State<RegisterStepPersonal> createState() => _RegisterStepPersonalState();
}

class _RegisterStepPersonalState extends State<RegisterStepPersonal> {
  final _nameTouch = FieldTouch();
  final _cpfTouch = FieldTouch();
  final _birthTouch = FieldTouch();
  bool _submitted = false;

  bool _isValid(RegisterState state, AppLocalizations l10n) =>
      AppValidators.isValidFullName(state.fullName) &&
      AppValidators.isValidCpf(onlyDigits(state.cpf)) &&
      AppValidators.birthDate(l10n, state.birthDate) == null;

  Future<void> _continue(
    BuildContext context,
    RegisterCubit cubit,
    AppLocalizations l10n,
  ) async {
    setState(() => _submitted = true);
    if (!_isValid(cubit.state, l10n)) return;
    await cubit.continueFromPersonal();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RegisterCubit>();
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final valid = _isValid(state, l10n);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  AuthErrorBanner(message: state.formError),
                  RegistrationTextField(
                    label: l10n.authFullNameLabel,
                    isRequired: true,
                    value: state.fullName,
                    hintText: l10n.authFullNameHint,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    errorText: _nameTouch.errorFor(
                      state.fullName,
                      submitted: _submitted,
                      format: (v) => AppValidators.isValidFullName(v)
                          ? null
                          : l10n.storeValFullNameIncomplete,
                      requiredMessage: l10n.validatorNameRequired,
                    ),
                    onChanged: (value) {
                      _nameTouch.touched = true;
                      cubit.updateFullName(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RegistrationTextField(
                    label: l10n.authCpfLabel,
                    isRequired: true,
                    value: state.cpf,
                    hintText: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    inputFormatters: [cpfInputFormatter()],
                    errorText: _cpfTouch.errorFor(
                      state.cpf,
                      submitted: _submitted,
                      format: (v) => AppValidators.isValidCpf(onlyDigits(v))
                          ? null
                          : l10n.personalCpfInvalid,
                      requiredMessage: l10n.membershipValCpfRequired,
                    ),
                    onChanged: (value) {
                      _cpfTouch.touched = true;
                      cubit.updateCpf(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RegistrationTextField(
                    label: l10n.personalFieldBirthDate,
                    isRequired: true,
                    value: state.birthDate,
                    hintText: l10n.authBirthDateHint,
                    keyboardType: TextInputType.number,
                    inputFormatters: [birthDateInputFormatter()],
                    errorText: _birthTouch.errorFor(
                      state.birthDate,
                      submitted: _submitted,
                      format: (v) => AppValidators.birthDate(l10n, v),
                      requiredMessage: l10n.membershipValBirthRequired,
                    ),
                    onChanged: (value) {
                      _birthTouch.touched = true;
                      cubit.updateBirthDate(value);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: RegisterPrimaryButton(
                label: l10n.commonContinue,
                loading: state.checkingCpf,
                onPressed: !state.checkingCpf && valid
                    ? () => _continue(context, cubit, l10n)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
