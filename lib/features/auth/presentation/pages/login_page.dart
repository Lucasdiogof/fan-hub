import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:goias_app/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:goias_app/features/auth/presentation/widgets/login_hero.dart';

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
      backgroundColor: colors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 820) {
            return Row(
              children: [
                const Expanded(child: LoginHero()),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildForm(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final heroHeight = (constraints.maxHeight * 0.42).clamp(280.0, 420.0);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(height: heroHeight, child: const LoginHero()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
                    child: _buildForm(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Entrar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Acesse sua conta e viva a experiência esmeraldina.',
          style: TextStyle(fontSize: 14, height: 1.35, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _emailController,
          label: 'E-mail',
          icon: Icons.mail_outline_rounded,
          hintText: 'seuemail@email.com',
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
          label: 'Senha',
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
            child: const Text('Esqueci a senha', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthPrimaryButton(
          label: 'ENTRAR',
          loading: _loading,
          loadingLabel: 'Entrando...',
          showArrow: true,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Ainda não possui uma conta? ', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  'Criar conta',
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
