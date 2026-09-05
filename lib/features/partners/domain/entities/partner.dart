/// Papel do parceiro — `sponsor` é o default (a maioria dos parceiros de
/// qualquer clube é patrocínio comercial genérico); `kitSupplier` é quem
/// FABRICA o material esportivo (camisa/uniforme) — categoria à parte
/// porque é sempre um fato público e verificável, ao contrário de
/// "patrocinador master/principal", que exigiria saber valor de contrato
/// pra classificar com segurança.
enum PartnerCategory { sponsor, kitSupplier }

class Partner {
  const Partner({
    required this.name,
    required this.url,
    this.assetPath,
    this.category = PartnerCategory.sponsor,
  });

  final String name;

  /// `null` = parceiro real e confirmado, mas ainda sem logo cedido/
  /// levantado (ASSET_GAP) — `PartnerCard` mostra o nome em texto em vez
  /// de travar o parceiro inteiro até existir arte. Nunca um placeholder
  /// de imagem genérico só pra preencher o espaço.
  final String? assetPath;
  final String url;
  final PartnerCategory category;
}
