import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:goias_app/features/auth/presentation/widgets/otp_code_field.dart';
import 'package:goias_app/features/auth/presentation/widgets/register_primary_button.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

const _otpLength = 6;
const _resendCooldownSeconds = 60;

/// Confirmação de e-mail por código de 6 dígitos (OTP, `{{ .Token }}` do
/// template "Confirm signup" do Supabase — nunca link). [email] vem sempre
/// explícito de quem navegou pra cá (ver `RegisterStepSecurity`) — não há
/// retomada entre sessões: se o app fechar antes da confirmação, reabrir
/// manda pro login e o cadastro recomeça do zero (ver `app_router.dart`).
/// Sucesso na verificação já estabelece sessão sozinho (o SDK faz isso) —
/// o redirect do router tira o usuário desta tela automaticamente, nunca
/// precisa de navegação explícita daqui.
class CheckYourEmailPage extends StatefulWidget {
  const CheckYourEmailPage({this.email, super.key});

  final String? email;

  @override
  State<CheckYourEmailPage> createState() => _CheckYourEmailPageState();
}

class _CheckYourEmailPageState extends State<CheckYourEmailPage> {
  final _otpKey = GlobalKey<OtpCodeFieldState>();

  String _code = '';
  Timer? _cooldownTimer;
  int _cooldown = 0;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  String get _email => widget.email ?? '';

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.length != _otpLength || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final result = await context.read<AuthCubit>().verifyEmailOtp(
      email: _email,
      token: _code,
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    switch (result) {
      case Success<void>():
        // Nunca navega explicitamente — o redirect do router já tira o
        // usuário desta tela assim que `AuthCubit` emite Authenticated (ver
        // `app_router.dart`).
        break;
      case Error<void>(:final failure):
        setState(() {
          _error = failure.message;
          _code = '';
        });
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    final result = await context.read<AuthCubit>().resendConfirmation(_email);
    if (!mounted) return;
    setState(() => _resending = false);
    final messenger = ScaffoldMessenger.of(context);
    if (result is Error<void>) {
      setState(() => _error = result.failure.message);
    } else {
      _startCooldown();
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.checkEmailResent)),
      );
    }
  }

  Future<void> _changeEmail() async {
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.alternate_email_rounded,
      title: context.l10n.checkEmailChangeTitle,
      description: context.l10n.checkEmailChangeMessage,
      confirmLabel: context.l10n.checkEmailChangeConfirm,
      cancelLabel: context.l10n.commonCancel,
    );
    if (confirmed != true || !mounted) return;
    // O signup antigo (mesmo CPF, e-mail errado) fica pendente e some
    // sozinho na limpeza de 48h do servidor — nunca tentamos "corrigir" via
    // `updateUser` (não existe sessão válida nesse ponto pra isso).
    context.go('/register');
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return email;
    final local = parts[0];
    final visible = local.length <= 3 ? local : local.substring(0, 3);
    return '$visible***@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
              child: Column(
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
                      Icons.mark_email_unread_outlined,
                      size: 40,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.checkEmailTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.checkEmailOtpSentTo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _maskEmail(_email),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AuthErrorBanner(message: _error),
                  OtpCodeField(
                    key: _otpKey,
                    length: _otpLength,
                    value: _code,
                    onChanged: (value) {
                      setState(() {
                        _code = value;
                        _error = null;
                      });
                    },
                    onSubmitted: _verify,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  RegisterPrimaryButton(
                    label: l10n.checkEmailConfirmButton,
                    loading: _verifying,
                    onPressed: _code.length == _otpLength && !_verifying
                        ? _verify
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.checkEmailDidNotReceive,
                    style: TextStyle(fontSize: 13, color: colors.textHint),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ResendLink(
                    cooldown: _cooldown,
                    sending: _resending,
                    onTap: _resend,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _changeEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                    child: Text(
                      l10n.checkEmailChangeEmail,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResendLink extends StatelessWidget {
  const _ResendLink({
    required this.cooldown,
    required this.sending,
    required this.onTap,
  });

  final int cooldown;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = cooldown > 0 || sending;
    final label = sending
        ? context.l10n.checkEmailResending
        : cooldown > 0
        ? context.l10n.checkEmailResendIn(cooldown)
        : context.l10n.checkEmailResend;

    return TextButton(
      onPressed: disabled ? null : onTap,
      style: TextButton.styleFrom(foregroundColor: colors.primary),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
