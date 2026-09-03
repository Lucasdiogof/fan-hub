import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:goias_app/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  final _emailTouch = FieldTouch();
  final _passwordTouch = FieldTouch();
  bool _loading = false;

  bool get _canSubmit =>
      AppValidators.email(context.l10n, _emailController.text) == null &&
      AppValidators.password(context.l10n, _passwordController.text) == null;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().signIn(
      email: AppValidators.normalizeEmail(_emailController.text),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is Error<void>) {
      final l10n = context.l10n;
      await AppBottomSheet.show(
        context,
        icon: Icons.error_outline_rounded,
        title: l10n.authSignInErrorTitle,
        description: result.failure.message,
        confirmLabel: l10n.commonClose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              sl<ClubConfig>().assets.loginBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Align(
                        alignment: const Alignment(0, 0.7),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: ContentWidth.form.maxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
    final l10n = context.l10n;
    const labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: _emailController,
          label: l10n.commonEmailLabel,
          labelStyle: labelStyle,
          icon: Icons.mail_outline_rounded,
          hintText: l10n.commonEmailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailTouch.errorFor(
            _emailController.text,
            submitted: false,
            format: (v) => AppValidators.email(l10n, v),
            requiredMessage: l10n.validatorEmailRequired,
          ),
          onChanged: (_) {
            _emailTouch.touched = true;
            setState(() {});
          },
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: l10n.commonPasswordLabel,
          labelStyle: labelStyle,
          icon: Icons.lock_outline_rounded,
          hintText: '••••••••',
          obscurable: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordTouch.errorFor(
            _passwordController.text,
            submitted: false,
            format: (v) => AppValidators.password(l10n, v),
            requiredMessage: l10n.validatorPasswordRequired,
          ),
          onChanged: (_) {
            _passwordTouch.touched = true;
            setState(() {});
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => ForgotPasswordSheet.show(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.authForgotPassword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: l10n.authSignInButton,
          loading: _loading,
          loadingLabel: l10n.authSigningIn,
          onPressed: _canSubmit ? _submit : null,
          // Explícito e independente do tema do app — o fundo desta tela é
          // sempre uma foto escura, então o botão precisa do mesmo verde
          // vívido tanto no light quanto no dark theme do app, ao contrário
          // do padrão novo do `AppPrimaryButton` (que decide pelo tema).
          color: AppColors.dark.ctaGreen,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.authNoAccountQuestion,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  l10n.authCreateAccount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
