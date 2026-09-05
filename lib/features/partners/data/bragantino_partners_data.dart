import 'package:goias_app/features/partners/domain/entities/partner.dart';

/// Pesquisado em 2026-09-05 (CNN Brasil, Gazeta Esportiva, redbullbragantino
/// .com). Só entram aqui parceiros com URL oficial CONFIRMADA — nenhum logo
/// real cedido ainda pra nenhum (ASSET_GAP, `assetPath: null` em todos,
/// `PartnerCard` já mostra o nome em texto nesse caso).
///
/// Parceiros confirmados por nome em 2026, mas de fora desta lista por
/// enquanto (DATA_GAP — URL oficial não verificada com segurança nesta
/// rodada, nunca um link adivinhado):
///   - Betfast (patrocinador de manga/barra traseira) — múltiplos domínios
///     concorrentes encontrados, nenhum confirmado com segurança como o
///     oficial da parceria.
///   - Curaprox — patrocínio só das categorias de base (sub-14 a sub-20),
///     fora do escopo de elenco profissional que o resto do app cobre.
///   - ASAAS, Supermercados Convém, Peluso Sperandio, Unimagem, Lo Sardo,
///     Humanitarian, CP Joia, VR Drive, KNN Idiomas — citados como
///     parceiros em matérias agregadas, sem URL individual verificada.
class BragantinoPartnersData {
  const BragantinoPartnersData._();

  static const List<Partner> all = [
    Partner(
      name: 'Puma',
      url: 'https://br.puma.com/',
      category: PartnerCategory.kitSupplier,
    ),
    Partner(name: 'Farmina', url: 'https://www.farmina.com.br/'),
  ];
}
