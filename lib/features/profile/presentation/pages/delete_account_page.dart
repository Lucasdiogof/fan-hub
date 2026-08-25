import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/session/local_game_cache.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/auth_validators.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

const _confirmationWord = 'EXCLUIR';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  final _confirmWordController = TextEditingController();
  final _confirmWordFocus = FocusNode();

  String? _passwordError;
  String? _formError;
  bool _loading = false;
  bool _canSubmit = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmWordController.dispose();
    _confirmWordFocus.dispose();
    super.dispose();
  }

  void _reevaluate() {
    final canSubmit =
        _passwordController.text.isNotEmpty &&
        _confirmWordController.text.trim().toUpperCase() == _confirmationWord;
    if (canSubmit != _canSubmit) setState(() => _canSubmit = canSubmit);
  }

  Future<void> _submit() async {
    if (!_canSubmit || _loading) return;
    FocusScope.of(context).unfocus();
    final passwordError = AuthValidators.password(_passwordController.text);
    setState(() {
      _passwordError = passwordError;
      _formError = null;
    });
    if (passwordError != null) return;

    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().deleteAccount(
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (result is Error<void>) {
      setState(() {
        _loading = false;
        _formError = result.failure.message;
      });
      return;
    }

    await clearLocalGameCaches();
    if (!mounted) return;
    // Não navega manualmente: assim que a sessão local é encerrada (dentro
    // de `deleteAccount`), o redirect do GoRouter já leva pro /login
    // substituindo toda a pilha — inclusive esta tela.
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
                      BackButtonCircle(
                        onTap: _loading ? () {} : () => context.pop(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const PageTitle('EXCLUIR CONTA'),
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
                        'Essa ação é permanente. Confirme sua senha e digite '
                        '$_confirmationWord para excluir sua conta e todo o '
                        'seu progresso.',
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
                        label: 'Senha atual',
                        icon: Icons.lock_person_outlined,
                        hintText: 'Confirme sua senha',
                        obscurable: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        errorText: _passwordError,
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                          _reevaluate();
                        },
                        onSubmitted: (_) => _confirmWordFocus.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        controller: _confirmWordController,
                        focusNode: _confirmWordFocus,
                        label: 'Digite $_confirmationWord para confirmar',
                        icon: Icons.edit_outlined,
                        hintText: _confirmationWord,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _reevaluate(),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppPrimaryButton(
                        label: 'EXCLUIR MINHA CONTA',
                        color: colors.error,
                        loading: _loading,
                        loadingLabel: 'EXCLUINDO CONTA...',
                        onPressed: _canSubmit ? _submit : null,
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
