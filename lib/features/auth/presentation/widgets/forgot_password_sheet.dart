import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (context) => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        child: ForgotPasswordSheet(),
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
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
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sent
            ? [
                Text(
                  'Verifique seu e-mail',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enviamos as instruções de redefinição para $_sentEmail.',
                  style: TextStyle(fontSize: 14, height: 1.35, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(label: 'FECHAR', onPressed: () => Navigator.of(context).pop()),
              ]
            : [
                Text(
                  'Recuperar senha',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Informe seu e-mail e enviaremos as instruções para redefinir sua senha.',
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'ENVIAR INSTRUÇÕES',
                  loading: _loading,
                  loadingLabel: 'Enviando...',
                  onPressed: _submit,
                ),
              ],
      ),
    );
  }
}
