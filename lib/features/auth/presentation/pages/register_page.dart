import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _formError;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final nameError = AuthValidators.fullName(l10n, _nameController.text);
    final emailError = AuthValidators.email(l10n, _emailController.text);
    final passwordError = AuthValidators.newPassword(l10n, _passwordController.text);
    final confirmError = AuthValidators.confirmPassword(l10n, _confirmController.text, _passwordController.text);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _termsError = !_acceptedTerms;
      _formError = null;
    });
    if (nameError != null || emailError != null || passwordError != null || confirmError != null || !_acceptedTerms) {
      return;
    }

    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().signUp(
      fullName: _nameController.text.trim(),
      email: AuthValidators.normalizeEmail(_emailController.text),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success<bool>(:final data):
        if (data) {
          context.go('/check-email', extra: AuthValidators.normalizeEmail(_emailController.text));
        }
      case Error<bool>(:final failure):
        setState(() => _formError = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.authRegisterTitle,
      subtitle: l10n.authRegisterSubtitle,
      children: [
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _nameController,
          label: l10n.authFullNameLabel,
          icon: Icons.person_outline_rounded,
          hintText: l10n.authFullNameHint,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          errorText: _nameError,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: l10n.commonEmailLabel,
          icon: Icons.mail_outline_rounded,
          hintText: l10n.commonEmailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: l10n.commonPasswordLabel,
          icon: Icons.lock_outline_rounded,
          hintText: l10n.authPasswordMinHint(AuthValidators.minPasswordLength),
          obscurable: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthTextField(
          controller: _confirmController,
          focusNode: _confirmFocus,
          label: l10n.authConfirmPasswordLabel,
          icon: Icons.lock_outline_rounded,
          hintText: l10n.authConfirmPasswordHint,
          obscurable: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TermsCheckbox(
          value: _acceptedTerms,
          hasError: _termsError,
          onChanged: (value) => setState(() {
            _acceptedTerms = value;
            if (value) _termsError = false;
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: l10n.authRegisterButton,
          loading: _loading,
          loadingLabel: l10n.authCreatingAccount,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.hasError, required this.onChanged});

  final bool value;
  final bool hasError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final linkStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.primary);
    final baseStyle = TextStyle(fontSize: 13, height: 1.4, color: colors.textSecondary);

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
                color: hasError ? colors.error : (value ? colors.primary : colors.border),
                width: 1.5,
              ),
            ),
            child: value ? Icon(Icons.check_rounded, size: 15, color: colors.onPrimary) : null,
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
                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/profile/terms'),
                ),
                TextSpan(text: l10n.authTermsConnector),
                TextSpan(
                  text: l10n.authPrivacyLink,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/profile/privacy'),
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
