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
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();

  String? _passwordError;
  String? _confirmError;
  String? _formError;
  bool _loading = false;
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final passwordError = AuthValidators.newPassword(
      l10n,
      _passwordController.text,
    );
    final confirmError = AuthValidators.confirmPassword(
      l10n,
      _confirmController.text,
      _passwordController.text,
    );
    setState(() {
      _passwordError = passwordError;
      _confirmError = confirmError;
      _formError = null;
    });
    if (passwordError != null || confirmError != null) return;

    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().updatePassword(
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success<void>():
        setState(() => _done = true);
      case Error<void>(:final failure):
        setState(() => _formError = failure.message);
    }
  }

  Future<void> _goToLogin() async {
    await context.read<AuthCubit>().signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _done ? _buildSuccess(context) : _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.resetPasswordTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.resetPasswordSubtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _passwordController,
          label: context.l10n.securityNewPassword,
          icon: Icons.lock_outline_rounded,
          hintText: context.l10n.authPasswordMinHint(
            AuthValidators.minPasswordLength,
          ),
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
          label: context.l10n.securityConfirmNewPassword,
          icon: Icons.lock_outline_rounded,
          hintText: context.l10n.securityConfirmNewPasswordHint,
          obscurable: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          label: context.l10n.securitySaveButton,
          loading: _loading,
          loadingLabel: context.l10n.commonSaving,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 42,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.resetPasswordSuccessTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.resetPasswordSuccessMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppPrimaryButton(
          label: context.l10n.authSignInButton,
          showArrow: true,
          onPressed: _goToLogin,
        ),
      ],
    );
  }
}
