import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Rótulos de exibição pra tudo que na Store é guardado por ID/enum
/// (categoria, coleção, público, tipo de produto, velocidade de frete) —
/// nunca texto pronto no catálogo/repositório/entidade, sempre traduzido
/// aqui a partir do identificador estável. `StoreCategory.name` e
/// `ShippingOption.label`/`.etaLabel` continuam existindo nas entidades
/// (útil pra uma futura integração real com a Tray, que devolve o nome
/// já pronto), mas a UI da Store sempre usa estas funções em vez de ler
/// esses campos direto.
String categoryDisplayName(AppLocalizations l10n, String id) {
  return switch (id) {
    'launches' => l10n.storeCategoryLaunches,
    'uniforms' => l10n.storeCategoryUniforms,
    'masculine' => l10n.storeAudienceMasculine,
    'feminine' => l10n.storeAudienceFeminine,
    'kids' => l10n.storeAudienceKids,
    'training' => l10n.storeTypeTraining,
    'personalizable' => l10n.storeCategoryPersonalizable,
    'accessories' => l10n.storeCategoryAccessories,
    'souvenirs' => l10n.storeCategorySouvenirs,
    'kit_01' => l10n.storeUniform01,
    'kit_02' => l10n.storeUniform02,
    'kit_03' => l10n.storeUniform03,
    'goalkeeper' => l10n.storeTypeGoalkeeper,
    'fan' => l10n.storeCollectionFan,
    'player' => l10n.storeCollectionPlayer,
    'casual' => l10n.storeTypeCasual,
    'training_travel' => l10n.storeCollectionTrainingTravel,
    'socks_gloves' => l10n.storeCollectionSocksGloves,
    _ => id,
  };
}

String audienceDisplayName(AppLocalizations l10n, StoreAudience audience) {
  return switch (audience) {
    StoreAudience.masculine => l10n.storeAudienceMasculine,
    StoreAudience.feminine => l10n.storeAudienceFeminine,
    StoreAudience.kids => l10n.storeAudienceKids,
    StoreAudience.unisex => l10n.storeAudienceUnisex,
  };
}

String productTypeDisplayName(AppLocalizations l10n, ProductType type) {
  return switch (type) {
    ProductType.matchJersey => l10n.storeTypeMatchJersey,
    ProductType.goalkeeper => l10n.storeTypeGoalkeeper,
    ProductType.training => l10n.storeTypeTraining,
    ProductType.casual => l10n.storeTypeCasual,
    ProductType.accessory => l10n.storeTypeAccessory,
    ProductType.souvenir => l10n.storeTypeSouvenir,
  };
}

String shippingSpeedLabel(AppLocalizations l10n, ShippingSpeed speed) {
  return switch (speed) {
    ShippingSpeed.economy => l10n.storeShippingEconomyLabel,
    ShippingSpeed.standard => l10n.storeShippingStandardLabel,
    ShippingSpeed.express => l10n.storeShippingExpressLabel,
  };
}

String shippingEtaLabel(AppLocalizations l10n, ShippingSpeed speed) {
  return switch (speed) {
    ShippingSpeed.economy => l10n.storeShippingEconomyEta,
    ShippingSpeed.standard => l10n.storeShippingStandardEta,
    ShippingSpeed.express => l10n.storeShippingExpressEta,
  };
}
