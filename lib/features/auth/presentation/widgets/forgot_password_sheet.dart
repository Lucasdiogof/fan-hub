import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const ForgotPasswordSheet(),
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
  bool _canSubmit = false;

  bool _sent = false;
  String _sentEmail = '';

  bool _resending = false;
  bool _resendDone = false;
  String? _resendError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    final valid = AuthValidators.email(context.l10n, value) == null;
    if (valid != _canSubmit) setState(() => _canSubmit = valid);
    if (_emailError != null) setState(() => _emailError = null);
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final emailError = AuthValidators.email(context.l10n, _emailController.text);
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

  Future<void> _resend() async {
    if (_resending) return;
    setState(() {
      _resending = true;
      _resendDone = false;
      _resendError = null;
    });
    final result = await context.read<AuthCubit>().sendPasswordReset(_sentEmail);
    if (!mounted) return;
    setState(() {
      _resending = false;
      switch (result) {
        case Success<void>():
          _resendDone = true;
        case Error<void>(:final failure):
          _resendError = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _sent ? _buildConfirmation(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(
          icon: Icons.lock_reset_rounded,
          title: l10n.forgotTitle,
          description: l10n.forgotSubtitle,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AuthErrorBanner(message: _formError),
        AuthTextField(
          controller: _emailController,
          label: l10n.commonEmailLabel,
          fillColor: colors.background,
          icon: Icons.mail_outline_rounded,
          hintText: l10n.commonEmailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: _onEmailChanged,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppPrimaryButton(
          label: l10n.forgotSendButton,
          loading: _loading,
          loadingLabel: l10n.forgotSending,
          color: colors.primary,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('confirmation'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(
          icon: Icons.mark_email_read_rounded,
          title: l10n.forgotVerifyEmailTitle,
          description: l10n.forgotSentDescription,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _sentEmail,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppPrimaryButton(
          label: l10n.commonGotIt,
          color: colors.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ResendAction(
          resending: _resending,
          done: _resendDone,
          error: _resendError,
          onResend: _resend,
        ),
      ],
    );
  }
}

/// Cabeçalho comum às duas telas: ícone num círculo verde bem suave, título
/// e descrição centralizados.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: colors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ResendAction extends StatelessWidget {
  const _ResendAction({
    required this.resending,
    required this.done,
    required this.error,
    required this.onResend,
  });

  final bool resending;
  final bool done;
  final String? error;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    if (error != null) {
      return Text(
        error!,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: colors.error),
      );
    }
    if (done) {
      return Text(
        l10n.forgotResendSuccess,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      );
    }
    if (resending) {
      return Text(
        l10n.checkEmailResending,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: colors.textSecondary),
      );
    }
    return GestureDetector(
      onTap: onResend,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${l10n.forgotNotReceived} ',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            TextSpan(
              text: l10n.checkEmailResend,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
