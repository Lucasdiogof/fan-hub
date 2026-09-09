import 'package:flutter/material.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Mesmo `AppPrimaryButton` do resto do app, só um alias local — sem seta,
/// já que os CTAs do cadastro (Continuar/Criar minha conta) não são
/// navegação simples, são o próprio passo de avanço.
class RegisterPrimaryButton extends StatelessWidget {
  const RegisterPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }
}
