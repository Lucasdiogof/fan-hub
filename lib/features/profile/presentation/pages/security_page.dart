import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();

  String? _passwordError;
  String? _confirmError;
  String? _formError;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final passwordError = AuthValidators.newPassword(_passwordController.text);
    final confirmError = AuthValidators.confirmPassword(_confirmController.text, _passwordController.text);
    setState(() {
      _passwordError = passwordError;
      _confirmError = confirmError;
      _formError = null;
    });
    if (passwordError != null || confirmError != null) return;

    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().updatePassword(_passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is Error<void>) {
      setState(() => _formError = result.failure.message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso.')));
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
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      const PageTitle('SEGURANÇA'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
                    children: [
                      Text(
                        'Altere a senha da sua conta Goiás EC.',
                        style: TextStyle(fontSize: 14, height: 1.35, color: colors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AuthErrorBanner(message: _formError),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Nova senha',
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
                        label: 'Confirmar nova senha',
                        icon: Icons.lock_outline_rounded,
                        hintText: 'Repita a nova senha',
                        obscurable: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        errorText: _confirmError,
                        onChanged: (_) {
                          if (_confirmError != null) setState(() => _confirmError = null);
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppPrimaryButton(
                        label: 'SALVAR NOVA SENHA',
                        loading: _loading,
                        loadingLabel: 'Salvando...',
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
