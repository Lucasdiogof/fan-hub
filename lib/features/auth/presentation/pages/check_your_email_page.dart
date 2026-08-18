import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';

class CheckYourEmailPage extends StatefulWidget {
  const CheckYourEmailPage({required this.email, super.key});

  final String email;

  @override
  State<CheckYourEmailPage> createState() => _CheckYourEmailPageState();
}

class _CheckYourEmailPageState extends State<CheckYourEmailPage> {
  static const _cooldownSeconds = 30;

  Timer? _timer;
  int _cooldown = 0;
  bool _sending = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = _cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _sending) return;
    setState(() => _sending = true);
    final result = await context.read<AuthCubit>().resendConfirmation(widget.email);
    if (!mounted) return;
    setState(() => _sending = false);
    final messenger = ScaffoldMessenger.of(context);
    if (result is Error<void>) {
      messenger.showSnackBar(SnackBar(content: Text(result.failure.message)));
    } else {
      _startCooldown();
      messenger.showSnackBar(const SnackBar(content: Text('E-mail reenviado. Confira sua caixa de entrada.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
                    child: Icon(Icons.mark_email_unread_outlined, size: 40, color: colors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Confirme seu e-mail',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Enviamos um link de confirmação para:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4, color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Abra sua caixa de entrada e confirme seu e-mail para ativar a conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4, color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _ResendButton(
                    cooldown: _cooldown,
                    sending: _sending,
                    onTap: _resend,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
                    child: const Text('Voltar para o login', style: TextStyle(fontWeight: FontWeight.w600)),
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

class _ResendButton extends StatelessWidget {
  const _ResendButton({required this.cooldown, required this.sending, required this.onTap});

  final int cooldown;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = cooldown > 0 || sending;
    final label = sending
        ? 'Reenviando...'
        : cooldown > 0
        ? 'Reenviar em ${cooldown}s'
        : 'Reenviar e-mail';

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
