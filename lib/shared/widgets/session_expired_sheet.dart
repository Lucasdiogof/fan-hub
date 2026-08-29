import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';

/// Aviso global de sessão perdida — chamado a partir de `main.dart` quando
/// `AuthCubit` emite `AuthSessionExpired` (refresh token inválido/revogado,
/// nunca um logout comum). `isDismissible: false` de propósito: não é um
/// aviso que dá pra ignorar tocando fora, já que as telas por trás
/// dependem de uma sessão que não existe mais.
Future<void> showSessionExpiredSheet(BuildContext context) {
  return AppBottomSheet.show(
    context,
    icon: Icons.lock_clock_rounded,
    title: context.l10n.authSessionExpiredTitle,
    description: context.l10n.authSessionExpiredMessage,
    confirmLabel: context.l10n.authSessionExpiredCta,
    isDismissible: false,
    onConfirm: () {
      // Normalmente já nem é necessário — o redirect do router já reage
      // ao `AuthSessionExpired` sozinho (ver `app_router.dart`) — mas
      // garante a navegação mesmo se, por algum motivo, o redirect ainda
      // não tiver rodado no momento em que o usuário confirma.
      if (context.mounted) context.go('/login');
    },
  );
}
