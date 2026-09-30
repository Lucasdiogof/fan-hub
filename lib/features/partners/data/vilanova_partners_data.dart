import 'package:goias_app/features/partners/domain/entities/partner.dart';

/// Patrocinadores do Vila Nova — lista ATIVA como o próprio clube publica na
/// faixa de patrocinadores de vilanovafc.com.br (lida em 2026-09-30), na
/// mesma ordem. Mesmo critério do Bragantino: a página oficial é a
/// autoridade pro cadastro ativo, nunca anúncio antigo.
///
/// Sem `tier` (a tela vira grade simples, como a do Goiás): o site não
/// separa máster/premium/regional e o máster atual NÃO está confirmado —
/// GingaBet era máster em fev/2026 (Máquina do Esporte, Poder360) e já não
/// aparece no site; a Bet Dá Sorte vem em 1º lugar, mas não há anúncio
/// oficial dela como máster. Não inventar hierarquia.
///
/// Categoria só onde há fonte: Volt = fornecedora de material (contrato de
/// 4 anos desde 2024); Fatal Fans = estampada no número da camisa (2026).
///
/// Links: os do site do clube, conferidos por HTTP em 2026-09-30. Ajustes:
/// Arroz Cristal e PIX das Estrelas apontavam pra caminho quebrado (404) —
/// usada a raiz do domínio; Marrada teve o domínio desativado (sem DNS) —
/// usado o Instagram oficial. FORA: V de Vantagens (domínio sem DNS e sem
/// perfil oficial encontrado — sem destino seguro pra abrir).
///
/// Logos: baixados do próprio site (140×110, é o tamanho publicado) em
/// `lib/assets/sponsors/vilanova/`. São TODOS brancos (feitos pro rodapé
/// escuro do site) — `lightLogo: true` faz o card usar o fundo escuro da
/// marca, sem recolorir a marca de terceiros.
///
/// Unimed aqui é a Unimed Goiânia — a mesma cooperativa que patrocina o
/// Goiás; é patrocínio real dos dois clubes, não dado reaproveitado.
class VilaNovaPartnersData {
  const VilaNovaPartnersData._();

  static const List<Partner> all = [
    Partner(
      name: 'Bet Dá Sorte',
      url: 'https://betdasortee.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/bet_da_sorte.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Arroz Cristal',
      url: 'https://cristalalimentos.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/arroz_cristal.png',
      lightLogo: true,
    ),
    Partner(
      name: 'BCJ',
      url: 'https://meubcj.com/',
      assetPath: 'lib/assets/sponsors/vilanova/bcj.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Oficial Sport',
      url: 'https://oficialsport.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/oficial_sport.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Volt',
      url: 'https://voltsport.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/volt.png',
      lightLogo: true,
      category: PartnerCategory.kitSupplier,
    ),
    Partner(
      name: 'Unimed',
      url: 'https://www.unimedgoiania.coop.br/wps/portal/internet',
      assetPath: 'lib/assets/sponsors/vilanova/unimed.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Fatal Fans',
      url: 'https://fatalfans.com/',
      assetPath: 'lib/assets/sponsors/vilanova/fatal_fans.png',
      lightLogo: true,
      category: PartnerCategory.shirtSponsor,
    ),
    Partner(
      name: 'Cash Cash',
      url: 'https://cashcash.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/cash_cash.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Pastarosa',
      url: 'http://www.grupopastarosa.com.br/site/index.php',
      assetPath: 'lib/assets/sponsors/vilanova/pastarosa.png',
      lightLogo: true,
    ),
    Partner(
      name: 'GAV Resorts',
      url: 'https://gavresorts.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/gav_resorts.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Luztol',
      url: 'https://www.luztol.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/luztol.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Proeza',
      url: 'http://proeza.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/proeza.png',
      lightLogo: true,
    ),
    Partner(
      name: 'TNT Energy Drink',
      url: 'https://tntenergydrink.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/tnt.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Milky Moo',
      url: 'https://www.milkymoo.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/milky_moo.png',
      lightLogo: true,
    ),
    Partner(
      name: 'New Brasil Tecnologia',
      url: 'https://newbrasiltecnologia.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/new_brasil_tecnologia.png',
      lightLogo: true,
    ),
    Partner(
      name: 'PIX das Estrelas',
      url: 'https://www.pixdasestrelas.com/',
      assetPath: 'lib/assets/sponsors/vilanova/pix_das_estrelas.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Grupo F8',
      url: 'http://grupof8.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/grupo_f8.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Fórmula Shell',
      url: 'https://formuladistribuidora.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/formula_shell.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Unicesumar',
      url: 'https://www.unicesumar.edu.br/',
      assetPath: 'lib/assets/sponsors/vilanova/unicesumar.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Claro',
      url: 'https://www.claro.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/claro.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Imprilux',
      url: 'https://imprilux.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/imprilux.png',
      lightLogo: true,
    ),
    Partner(
      name: 'King Grass',
      url: 'http://www.kinggrass.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/king_grass.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Cristal Pisos',
      url: 'https://www.cristalpisos.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/cristal_pisos.png',
      lightLogo: true,
    ),
    Partner(
      name: 'FlexiBase',
      url: 'https://flexibase.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/flexibase.png',
      lightLogo: true,
    ),
    Partner(
      name: 'LinQ',
      url: 'https://linq.net.br/',
      assetPath: 'lib/assets/sponsors/vilanova/linq.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Fast Açaí',
      url: 'https://fastacai.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/fast_acai.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Vedacil',
      url: 'https://vedacil.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/vedacil.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Marrada',
      url: 'https://www.instagram.com/marradaenergydrink/',
      assetPath: 'lib/assets/sponsors/vilanova/marrada.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Agência MPrado',
      url: 'https://www.agenciamprado.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/agencia_mprado.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Nativa Águas',
      url: 'http://www.aguanativa.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/nativa_aguas.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Aquarius',
      url: 'https://restauranteaquarius.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/aquarius.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Fricó',
      url: 'https://fricoalimentos.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/frico.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Frutap',
      url: 'https://www.frutap.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/frutap.png',
      lightLogo: true,
    ),
    Partner(
      name: 'Condromed',
      url: 'https://condromedultra.com.br/',
      assetPath: 'lib/assets/sponsors/vilanova/condromed.png',
      lightLogo: true,
    ),
  ];
}
