import 'package:goias_app/features/partners/domain/entities/partner.dart';

/// Categorização OFICIAL fechada pelo usuário em 2026-09-11 (mesma
/// estrutura hoje publicada pela página "Parceiros" do clube) — usar
/// exatamente esta, não inventar outra:
///   - Institucional: Red Bull (relação estrutural/dona da marca, NUNCA
///     misturada com patrocínio comercial comum — ver
///     [PartnerRelationshipTier.institutional]);
///   - Patrocinadores Premium: Puma, Asaas, N&D, Curaprox, KNN Idiomas;
///   - Patrocinadores Regionais: Peluso Sperandio, Convém, Unimed,
///     Unimagem, Humanitarian, Lo Sardo;
///   - Fornecedores Oficiais: Colégio Populus, Ecobier, CPJóia,
///     Campus.Live, Meu Inglês Sob Medida, Trendx.
///
/// Só entram como [Partner] de verdade os que têm link oficial confirmado
/// (nunca inventado) — hoje 13 dos ~19 nomes acima (12 comerciais + Red
/// Bull). Fora do runtime, de propósito, por falta de URL oficial
/// confirmada (nomes/tier já são conhecidos, só falta destino seguro pra
/// abrir — avise se tiver o link oficial de algum):
///   - N&D (a marca; "Farmina" é o fabricante — nunca cadastrar os dois
///     como parceiros separados se algum dia tiver link, é o mesmo
///     contrato);
///   - Unimagem, Humanitarian, Lo Sardo, Trendx.
///
/// Betfast NÃO entra — havia anúncio antigo de patrocínio Premium, mas
/// ela não aparece na página oficial atual de Parceiros; a página oficial
/// é sempre a autoridade pro cadastro ativo (nunca anúncio antigo).
///
/// `assetPath`: logos baixados do CDN oficial do clube
/// (img.redbullbragantino.com) e versionados em
/// `lib/assets/sponsors/bragantino/` (2026-09-10) — mesmo padrão histórico
/// do Goiás (`PartnersData`), preferido a `logoUrl` porque não depende do
/// CDN estar no ar pra o logo aparecer. Red Bull ainda não tem asset
/// próprio aqui (ASSET_GAP real) — cai no fallback de nome em texto do
/// `PartnerCard`, nunca um logo genérico/placeholder.
///
/// Unimed aqui é a unidade regional "Os Bandeirantes" (Bragança
/// Paulista) — cooperativa independente da Unimed Goiânia que patrocina
/// o Goiás; mesma marca nacional, contratos/URLs diferentes, nunca a
/// mesma linha do Goiás reaproveitada.
class BragantinoPartnersData {
  const BragantinoPartnersData._();

  static const List<Partner> all = [
    Partner(
      name: 'Red Bull',
      url: 'https://www.redbull.com/br-pt/',
      tier: PartnerRelationshipTier.institutional,
    ),
    Partner(
      name: 'Puma',
      url: 'https://br.puma.com/esportes/futebol/red-bull-bragantino',
      assetPath: 'lib/assets/sponsors/bragantino/puma.png',
      category: PartnerCategory.kitSupplier,
      tier: PartnerRelationshipTier.premiumSponsor,
    ),
    Partner(
      name: 'Asaas',
      url: 'https://www.asaas.com/parceiros/redbullbragantino',
      assetPath: 'lib/assets/sponsors/bragantino/asaas.png',
      category: PartnerCategory.shirtSponsor,
      tier: PartnerRelationshipTier.premiumSponsor,
    ),
    Partner(
      name: 'Curaprox',
      url: 'https://www.loja.curaprox.com.br/',
      assetPath: 'lib/assets/sponsors/bragantino/curaprox.png',
      category: PartnerCategory.academySponsor,
      tier: PartnerRelationshipTier.premiumSponsor,
    ),
    Partner(
      name: 'KNN Idiomas',
      url: 'https://www.knnidiomas.com.br/',
      assetPath: 'lib/assets/sponsors/bragantino/knn-idiomas.png',
      category: PartnerCategory.academySponsor,
      tier: PartnerRelationshipTier.premiumSponsor,
    ),
    Partner(
      name: 'Peluso Sperandio',
      url: 'https://pelusosperandio.com.br/',
      assetPath: 'lib/assets/sponsors/bragantino/peluso-sperandio.png',
      tier: PartnerRelationshipTier.regionalSponsor,
    ),
    Partner(
      name: 'Convém',
      url: 'https://www.instagram.com/convemsupermercados/',
      assetPath: 'lib/assets/sponsors/bragantino/convem.png',
      tier: PartnerRelationshipTier.regionalSponsor,
    ),
    Partner(
      name: 'Unimed',
      url: 'https://www.unimed.coop.br/site/web/osbandeirantes',
      assetPath: 'lib/assets/sponsors/bragantino/unimed.png',
      tier: PartnerRelationshipTier.regionalSponsor,
    ),
    Partner(
      name: 'Colégio Populus',
      url: 'https://populusitatiba.com.br/',
      assetPath: 'lib/assets/sponsors/bragantino/colegio-populus.png',
      tier: PartnerRelationshipTier.officialSupplier,
    ),
    Partner(
      name: 'Ecobier',
      url: 'https://ecobier.com.br/',
      assetPath: 'lib/assets/sponsors/bragantino/ecobier.png',
      tier: PartnerRelationshipTier.officialSupplier,
    ),
    Partner(
      name: 'CPJóia',
      url: 'http://www.cpjoia.com.br/',
      assetPath: 'lib/assets/sponsors/bragantino/cpjoia.png',
      tier: PartnerRelationshipTier.officialSupplier,
    ),
    Partner(
      name: 'Campus.Live',
      url: 'https://www.campus.live/pt-br/',
      assetPath: 'lib/assets/sponsors/bragantino/campus-live.png',
      tier: PartnerRelationshipTier.officialSupplier,
    ),
    Partner(
      name: 'Meu Inglês Sob Medida',
      url: 'https://meuinglessobmedida.com.br/red-bull/',
      assetPath: 'lib/assets/sponsors/bragantino/meu-ingles-sob-medida.png',
      tier: PartnerRelationshipTier.officialSupplier,
    ),
  ];
}
