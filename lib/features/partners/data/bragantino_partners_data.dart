import 'package:goias_app/features/partners/domain/entities/partner.dart';

/// Auditoria em 2026-09-06 direto na API da própria página oficial
/// "Parceiros" (redbullbragantino.com/br-pt/parceiros) — fonte de verdade
/// sobre QUEM é parceiro atual, em que categoria, com link oficial e logo,
/// algo que reportagem antiga não garante (patrocínio muda de temporada
/// pra temporada). A página organiza em 3 categorias:
///   - Patrocinadores Premium: Puma, ASAAS, N&D, Curaprox, KNN Idiomas
///   - Patrocinadores Regionais: Peluso Sperandio, Convém, Unimed,
///     Unimagem, Humanitarian, Lo Sardo
///   - Fornecedores Oficiais: Colégio Populus, Ecobier, CPJóia,
///     Campus.Live, Meu Inglês Sob Medida, Trendx
/// (mais Rhodes/Nogalves/Bellicasa, num carrossel sem categoria explícita
/// no texto extraído da página).
///
/// 10 de ~19 têm `link` oficial exposto pela própria API (o resto vem
/// `null` direto na fonte) — só esses entram como [Partner] de verdade.
/// Os outros 9 (KNN Idiomas, TRENDX, RHODES, Nogalves, Lo Sardo,
/// Humanitarian, Unimagem, Bellicasa, Curaprox) ficam de fora do model —
/// DATA_GAP de URL, não de existência: todos têm nome/logo reais
/// confirmados, só sem destino oficial pra abrir.
///
/// `logoUrl`: nenhum logo baixado/versionado no repo — vem direto do CDN
/// oficial do clube (img.redbullbragantino.com), mesmo padrão já usado
/// pra foto de jogador (`squad_members.photo_url`/`SquadAvatar`).
///
/// "N&D" (marca) x "Farmina" (fabricante): fora do model por ora (sem
/// `link` na API) — mesmo assim, nunca cadastrar os dois como parceiros
/// separados se voltar a ter link: é o mesmo contrato/marca.
///
/// Unimed aqui é a unidade regional "Os Bandeirantes" (Bragança
/// Paulista) — cooperativa independente da Unimed Goiânia que patrocina
/// o Goiás; mesma marca nacional, contratos/URLs diferentes, nunca a
/// mesma linha do Goiás reaproveitada.
class BragantinoPartnersData {
  const BragantinoPartnersData._();

  static const List<Partner> all = [
    Partner(
      name: 'Puma',
      url: 'https://br.puma.com/esportes/futebol/red-bull-bragantino',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/2/4/dfcsflqaf3nupklqk7za/puma',
      category: PartnerCategory.kitSupplier,
    ),
    Partner(
      name: 'Asaas',
      url: 'https://www.asaas.com/parceiros/redbullbragantino',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/4/9/sttqoyvrxewigmndoxxy/asaas',
    ),
    Partner(
      name: 'Peluso Sperandio',
      url: 'https://pelusosperandio.com.br/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/2/4/b3blwskeo5ad98lxhiab/peluso-sperandio',
    ),
    Partner(
      name: 'Convém',
      url: 'https://www.instagram.com/convemsupermercados/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/7/22/bnmf27esnngescqkmlvd/convem-supermercados',
    ),
    Partner(
      name: 'Unimed',
      url: 'https://www.unimed.coop.br/site/web/osbandeirantes',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/30/lgzporikoavbq9pbe4vg/unimed',
    ),
    Partner(
      name: 'Colégio Populus',
      url: 'https://populusitatiba.com.br/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/2/4/adcn0uoz3xz3dd3kl3pn/colegio-populus',
    ),
    Partner(
      name: 'Ecobier',
      url: 'https://ecobier.com.br/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/19/ibpr9rgycnvofmrzgdta/ecobier-logo',
    ),
    Partner(
      name: 'CPJóia',
      url: 'http://www.cpjoia.com.br/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/2/4/rssbn35q1kpdfm97t3gb/cpjoia',
    ),
    Partner(
      name: 'Campus.Live',
      url: 'https://www.campus.live/pt-br/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/2/4/amwid1dfbyxbqwsj1qix/campus-live',
    ),
    Partner(
      name: 'Meu Inglês Sob Medida',
      url: 'https://meuinglessobmedida.com.br/red-bull/',
      logoUrl:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/2/4/uhguugeltbzukv5vkc8z/meu-ingles-sob-medida',
    ),
  ];
}
