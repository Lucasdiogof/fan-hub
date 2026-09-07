/// Papel do parceiro — `sponsor` é o default (a maioria dos parceiros de
/// qualquer clube é patrocínio comercial genérico); `kitSupplier` é quem
/// FABRICA o material esportivo (camisa/uniforme) — categoria à parte
/// porque é sempre um fato público e verificável, ao contrário de
/// "patrocinador master/principal", que exigiria saber valor de contrato
/// pra classificar com segurança. `shirtSponsor`/`academySponsor` só
/// existem quando a própria fonte já classifica explicitamente o
/// posicionamento contratual (nunca inferido pela gente).
enum PartnerCategory { sponsor, kitSupplier, shirtSponsor, academySponsor }

class Partner {
  const Partner({
    required this.name,
    required this.url,
    this.assetPath,
    this.logoUrl,
    this.category = PartnerCategory.sponsor,
  });

  final String name;

  /// Logo local empacotado no app (padrão histórico do Goiás,
  /// `lib/assets/sponsors/*.png`).
  final String? assetPath;

  /// Logo remoto (CDN oficial do próprio clube/parceiro) — mesmo padrão
  /// já usado pra foto de jogador (`SquadAvatar`/`squad_members.photo_url`):
  /// nunca baixar/versionar dezenas de logos no repo quando a URL oficial
  /// já é estável. `PartnerCard` tenta [assetPath] primeiro, depois
  /// [logoUrl]; os dois `null` = nome em texto (ASSET_GAP real, nunca um
  /// placeholder genérico só pra preencher o espaço).
  final String? logoUrl;
  final String url;
  final PartnerCategory category;
}
