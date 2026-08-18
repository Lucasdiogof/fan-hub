import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  String? _emailError;
  String? _formError;
  bool _loading = false;
  bool _sent = false;
  String _sentEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final emailError = AuthValidators.email(_emailController.text);
    setState(() {
      _emailError = emailError;
      _formError = null;
    });
    if (emailError != null) return;

    final email = AuthValidators.normalizeEmail(_emailController.text);
    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().sendPasswordReset(email);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success<void>():
        setState(() {
          _sent = true;
          _sentEmail = email;
        });
      case Error<void>(:final failure):
        setState(() => _formError = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthScaffold(
        title: 'Verifique seu e-mail',
        subtitle: 'Enviamos as instruções de redefinição para $_sentEmail.',
        children: [
          AuthPrimaryButton(label: 'VOLTAR PARA O LOGIN', onPressed: () => context.go('/login')),
        ],
      );
    }

    return AuthScaffold(
      title: 'Recuperar senha',
      subtitle: 'Informe seu e-mail e enviaremos as instruções para redefinir sua senha.',
      children: [
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _emailController,
          label: 'E-mail',
          icon: Icons.mail_outline_rounded,
          hintText: 'seuemail@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthPrimaryButton(
          label: 'ENVIAR INSTRUÇÕES',
          loading: _loading,
          loadingLabel: 'Enviando...',
          onPressed: _submit,
        ),
      ],
    );
  }
}
