import 'package:flutter/gestures.dart';
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
    final nameError = AuthValidators.fullName(_nameController.text);
    final emailError = AuthValidators.email(_emailController.text);
    final passwordError = AuthValidators.newPassword(_passwordController.text);
    final confirmError = AuthValidators.confirmPassword(_confirmController.text, _passwordController.text);
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
    return AuthScaffold(
      title: 'Criar conta',
      subtitle: 'Faça parte da experiência esmeraldina.',
      children: [
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _nameController,
          label: 'Nome completo',
          icon: Icons.person_outline_rounded,
          hintText: 'Seu nome',
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
          hintText: 'Mínimo ${AuthValidators.minPasswordLength} caracteres',
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
          label: 'Confirmar senha',
          icon: Icons.lock_outline_rounded,
          hintText: 'Repita a senha',
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
        AuthPrimaryButton(
          label: 'CRIAR CONTA',
          loading: _loading,
          loadingLabel: 'Criando...',
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Já possui uma conta? ', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : context.go('/login'),
                child: Text(
                  'Entrar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.primary),
                ),
              ),
            ],
          ),
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

  void _openLegal(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'O conteúdo completo estará disponível em breve.',
              style: TextStyle(fontSize: 14, height: 1.4, color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                const TextSpan(text: 'Li e aceito os '),
                TextSpan(
                  text: 'Termos de Uso',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = () => _openLegal(context, 'Termos de Uso'),
                ),
                const TextSpan(text: ' e a '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = () => _openLegal(context, 'Política de Privacidade'),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
