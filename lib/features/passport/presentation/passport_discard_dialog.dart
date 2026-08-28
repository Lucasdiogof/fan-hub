import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Confirmação de "descartar alterações pendentes" — compartilhada entre
/// V1 e V2 (é só um diálogo, não lógica de domínio nem estado do Cubit).
Future<bool> confirmDiscardPassportChanges(BuildContext context) async {
  final l10n = context.l10n;
  final colors = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.passportDiscardChangesTitle),
      content: Text(l10n.passportDiscardChangesMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.passportDiscardChangesConfirm,
            style: TextStyle(color: colors.gold),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
