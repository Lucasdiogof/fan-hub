import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/partners/domain/entities/partner.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';

/// Card de parceiro reutilizado tanto na grid completa (PartnersPage)
/// quanto no carrossel discreto da Home — só [logoHeight]/[padding] mudam
/// entre os dois contextos.
class PartnerCard extends StatelessWidget {
  const PartnerCard({
    required this.partner,
    this.logoHeight = 56,
    this.padding = AppSpacing.lg,
    super.key,
  });

  final Partner partner;
  final double logoHeight;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A maioria das artes de patrocinador já foi desenhada assumindo um
    // fundo branco (fundo opaco embutido no PNG, não transparente —
    // conferido byte a byte: 18 dos 26 logos têm alfa 255 nos cantos).
    // Recolorir por tema apaga esses 18 por completo no escuro, já que todo
    // pixel opaco vira branco sólido. A solução é o card inteiro ser branco
    // — não só uma placa por trás do logo, senão sobra uma margem escura
    // ao redor dela no tema dark — os poucos logos realmente transparentes
    // também ficam legíveis em cima de branco, então não precisa
    // diferenciar caso a caso.
    return Semantics(
      button: true,
      label: _accessibilityLabel(context, partner),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: () => openExternalUrl(context, partner.url),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.border),
            ),
            padding: EdgeInsets.all(padding),
            alignment: Alignment.center,
            child: SizedBox(
              height: logoHeight,
              width: double.infinity,
              child: _PartnerLogo(partner: partner),
            ),
          ),
        ),
      ),
    );
  }
}

/// [Partner.assetPath] (local, padrão histórico) tem prioridade sobre
/// [Partner.logoUrl] (remoto, CDN oficial) — os dois `null`/falha de rede
/// caem no nome em texto (nunca um placeholder genérico de imagem).
class _PartnerLogo extends StatelessWidget {
  const _PartnerLogo({required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    if (partner.assetPath != null) {
      return Image.asset(partner.assetPath!, fit: BoxFit.contain);
    }
    final logoUrl = partner.logoUrl;
    if (logoUrl != null) {
      return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, _, _) =>
            _PartnerNameFallback(name: partner.name),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const SizedBox.shrink(),
      );
    }
    return _PartnerNameFallback(name: partner.name);
  }
}

/// Enquanto o logo real não existe (ver [Partner.assetPath]/[logoUrl]) —
/// nome do parceiro centralizado, sem tentar imitar visualmente uma marca
/// que a gente não tem a arte oficial.
class _PartnerNameFallback extends StatelessWidget {
  const _PartnerNameFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

String _accessibilityLabel(BuildContext context, Partner partner) {
  final l10n = context.l10n;
  final isInstagram = partner.url.contains('instagram.com');
  return isInstagram
      ? l10n.partnersOpenInstagram(partner.name)
      : l10n.partnersOpenWebsite(partner.name);
}
