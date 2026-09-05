import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_primary_button.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';

/// Passo 2 de 3 — Contato.
class RegisterStepContact extends StatefulWidget {
  const RegisterStepContact({super.key});

  @override
  State<RegisterStepContact> createState() => _RegisterStepContactState();
}

class _RegisterStepContactState extends State<RegisterStepContact> {
  final _emailTouch = FieldTouch();
  final _phoneTouch = FieldTouch();
  bool _submitted = false;

  bool _isValid(RegisterState state) =>
      AppValidators.isValidEmailShape(state.email) &&
      AppValidators.isValidMobilePhone(state.phone);

  void _continue(RegisterCubit cubit) {
    setState(() => _submitted = true);
    if (!_isValid(cubit.state)) return;
    cubit.continueFromContact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RegisterCubit>();
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final valid = _isValid(state);
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
                    label: l10n.commonEmailLabel,
                    isRequired: true,
                    value: state.email,
                    hintText: l10n.commonEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    errorText: _emailTouch.errorFor(
                      state.email,
                      submitted: _submitted,
                      format: (v) => AppValidators.isValidEmailShape(v)
                          ? null
                          : l10n.validatorEmailInvalid,
                      requiredMessage: l10n.validatorEmailRequired,
                    ),
                    onChanged: (value) {
                      _emailTouch.touched = true;
                      cubit.updateEmail(AppValidators.normalizeEmail(value));
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RegistrationTextField(
                    label: l10n.personalFieldPhone,
                    isRequired: true,
                    value: state.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneInputFormatter()],
                    autofillHints: const [AutofillHints.telephoneNumber],
                    errorText: _phoneTouch.errorFor(
                      state.phone,
                      submitted: _submitted,
                      format: (v) => AppValidators.isValidMobilePhone(v)
                          ? null
                          : l10n.storeValPhoneInvalid,
                      requiredMessage: l10n.membershipValPhoneRequired,
                    ),
                    onChanged: (value) {
                      _phoneTouch.touched = true;
                      cubit.updatePhone(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MarketingOptInCheckbox(
                    value: state.marketingOptIn,
                    onChanged: cubit.updateMarketingOptIn,
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
                onPressed: valid ? () => _continue(cubit) : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MarketingOptInCheckbox extends StatelessWidget {
  const _MarketingOptInCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 15, color: colors.onPrimary)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.authMarketingOptIn(sl<ClubConfig>().identity.shortName),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
