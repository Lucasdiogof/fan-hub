import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Único ponto do app que chama `launchUrl` — sempre externo (abre o app
/// nativo quando existe, ex.: Instagram, ou o navegador). Nunca deixa uma
/// URL quebrada virar exception visível: cai num SnackBar amigável.
Future<void> openExternalUrl(BuildContext context, String url) async {
  try {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) throw Exception('launchUrl returned false for $url');
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonLinkOpenError)),
    );
  }
}
