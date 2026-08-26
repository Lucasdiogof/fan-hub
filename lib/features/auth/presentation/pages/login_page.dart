import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:goias_app/features/auth/presentation/widgets/forgot_password_sheet.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final emailError = AuthValidators.email(_emailController.text);
    final passwordError = AuthValidators.password(_passwordController.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });
    if (emailError != null || passwordError != null) return;

    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().signIn(
      email: AuthValidators.normalizeEmail(_emailController.text),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is Error<void>) {
      setState(() => _formError = result.failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppAssets.loginBackground, fit: BoxFit.cover),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Align(
                        alignment: const Alignment(0, -0.28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withValues(alpha: 0.38),
                                        blurRadius: 40,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: colors.primary.withValues(alpha: 0.18),
                                        blurRadius: 84,
                                        spreadRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: SvgPicture.asset(
                                    AppAssets.goiasCrest,
                                    height: 124,
                                    colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxxl),
                              _buildForm(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.authTagline,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _emailController,
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
          hintText: '••••••••',
          obscurable: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => ForgotPasswordSheet.show(context),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.authForgotPassword, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: l10n.authSignInButton,
          loading: _loading,
          loadingLabel: l10n.authSigningIn,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.authNoAccountQuestion, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  l10n.authCreateAccount,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
