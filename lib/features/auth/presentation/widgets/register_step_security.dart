import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_primary_button.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';

/// Passo 3 de 3 — Segurança. É o único passo que de fato chama o `signUp`
/// — os dois anteriores só validam e navegam entre eles.
class RegisterStepSecurity extends StatefulWidget {
  const RegisterStepSecurity({super.key});

  @override
  State<RegisterStepSecurity> createState() => _RegisterStepSecurityState();
}

class _RegisterStepSecurityState extends State<RegisterStepSecurity> {
  final _passwordTouch = FieldTouch();
  final _confirmTouch = FieldTouch();
  bool _submitted = false;
  bool _termsError = false;

  bool _isValid(RegisterState state) =>
      state.password.length >= AppValidators.minPasswordLength &&
      state.password == state.confirmPassword &&
      state.acceptedTerms;

  Future<void> _submit(BuildContext context, RegisterCubit cubit) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _termsError = !cubit.state.acceptedTerms;
    });
    if (!_isValid(cubit.state)) return;
    final result = await cubit.submit();
    if (!context.mounted) return;
    if (result is Success<bool>) {
      context.go('/check-email', extra: cubit.state.email);
    }
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
                    label: l10n.commonPasswordLabel,
                    isRequired: true,
                    value: state.password,
                    hintText: l10n.authPasswordMinHint(
                      AppValidators.minPasswordLength,
                    ),
                    textCapitalization: TextCapitalization.none,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: true,
                    errorText: _passwordTouch.errorFor(
                      state.password,
                      submitted: _submitted,
                      format: (v) => v.length >= AppValidators.minPasswordLength
                          ? null
                          : l10n.validatorPasswordMinLength(
                              AppValidators.minPasswordLength,
                            ),
                      requiredMessage: l10n.validatorPasswordCreate,
                    ),
                    onChanged: (value) {
                      _passwordTouch.touched = true;
                      cubit.updatePassword(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PasswordRequirement(
                    met: state.password.length >= AppValidators.minPasswordLength,
                    label: l10n.authPasswordRequirementLength(
                      AppValidators.minPasswordLength,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RegistrationTextField(
                    label: l10n.authConfirmPasswordLabel,
                    isRequired: true,
                    value: state.confirmPassword,
                    hintText: l10n.authConfirmPasswordHint,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: true,
                    errorText: _confirmTouch.errorFor(
                      state.confirmPassword,
                      submitted: _submitted,
                      format: (v) => v == state.password
                          ? null
                          : l10n.validatorPasswordsDoNotMatch,
                      requiredMessage: l10n.validatorConfirmRequired,
                    ),
                    onChanged: (value) {
                      _confirmTouch.touched = true;
                      cubit.updateConfirmPassword(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TermsCheckbox(
                    value: state.acceptedTerms,
                    hasError: _termsError,
                    onChanged: (value) {
                      cubit.updateAcceptedTerms(value);
                      if (value) setState(() => _termsError = false);
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
                label: l10n.authRegisterButton,
                loading: state.submitting,
                onPressed: !state.submitting && valid
                    ? () => _submit(context, cubit)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = met ? colors.primary : colors.textHint;
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final bool value;
  final bool hasError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final linkStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: colors.primary,
    );
    final baseStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: colors.textSecondary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasError
                    ? colors.error
                    : (value ? colors.primary : colors.border),
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 15, color: colors.onPrimary)
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                TextSpan(text: l10n.authTermsPrefix),
                TextSpan(
                  text: l10n.authTermsLink,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/profile/terms'),
                ),
                TextSpan(text: l10n.authTermsConnector),
                TextSpan(
                  text: l10n.authPrivacyLink,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/profile/privacy'),
                ),
                TextSpan(text: l10n.authTermsSuffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
