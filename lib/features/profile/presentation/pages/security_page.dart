import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _newPasswordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _currentPasswordError;
  String? _passwordError;
  String? _confirmError;
  String? _formError;
  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _newPasswordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final currentPasswordError = AuthValidators.password(
      l10n,
      _currentPasswordController.text,
    );
    final passwordError = AuthValidators.newPassword(l10n, _passwordController.text);
    final confirmError = AuthValidators.confirmPassword(
      l10n,
      _confirmController.text,
      _passwordController.text,
    );
    setState(() {
      _currentPasswordError = currentPasswordError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _formError = null;
    });
    if (currentPasswordError != null ||
        passwordError != null ||
        confirmError != null) {
      return;
    }

    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is Error<void>) {
      setState(() => _formError = result.failure.message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.securityChangeSuccess)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(context.l10n.securityTitle),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      Text(
                        context.l10n.securitySubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AuthErrorBanner(message: _formError),
                      AuthTextField(
                        controller: _currentPasswordController,
                        label: context.l10n.securityCurrentPassword,
                        icon: Icons.lock_person_outlined,
                        hintText: context.l10n.securityCurrentPasswordHint,
                        obscurable: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        errorText: _currentPasswordError,
                        onChanged: (_) {
                          if (_currentPasswordError != null) {
                            setState(() => _currentPasswordError = null);
                          }
                        },
                        onSubmitted: (_) => _newPasswordFocus.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        controller: _passwordController,
                        focusNode: _newPasswordFocus,
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
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
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
                          if (_confirmError != null) {
                            setState(() => _confirmError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppPrimaryButton(
                        label: context.l10n.securitySaveButton,
                        loading: _loading,
                        loadingLabel: context.l10n.commonSaving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
