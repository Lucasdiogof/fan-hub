import 'package:goias_app/features/partners/domain/entities/partner.dart';

/// Fonte única dos parceiros do Goiás — Home (carrossel) e PartnersPage
/// (grid completa) leem daqui, nunca duas listas separadas. Estáticos por
/// enquanto: sem API, sem banco, ordem fixa (não alfabética) combinada com
/// o clube.
class PartnersData {
  const PartnersData._();

  static const List<Partner> all = [
    Partner(name: 'Viva Sorte', assetPath: 'lib/assets/viva_sorte.png', url: 'https://vivasorteoficial.com.br/'),
    Partner(name: 'Cristal Alimentos', assetPath: 'lib/assets/cristal.png', url: 'https://cristalalimentos.com.br/'),
    Partner(
      name: 'Unimed',
      assetPath: 'lib/assets/unimed.png',
      url: 'https://www.unimedgoiania.coop.br/wps/portal/internet',
    ),
    Partner(name: 'Vedacil', assetPath: 'lib/assets/vedacil.png', url: 'https://vedacil.com.br/'),
    Partner(name: 'Séren', assetPath: 'lib/assets/seren.png', url: 'https://seren.inc/empreendimento/seren-hausen/'),
    Partner(name: 'Diadora', assetPath: 'lib/assets/diadora.png', url: 'https://www.diadorabrasil.com.br/'),
    Partner(name: 'Movement', assetPath: 'lib/assets/movement.png', url: 'https://www.movement.com.br/'),
    Partner(name: 'CDI', assetPath: 'lib/assets/cdi.png', url: 'https://cdig.com.br/'),
    Partner(name: 'Colombina', assetPath: 'lib/assets/colombina.png', url: 'https://cervejacolombina.com.br/'),
    Partner(name: 'Grupo Josidth', assetPath: 'lib/assets/josidith.png', url: 'https://grupojosidith.com.br/'),
    Partner(name: 'Lebrinha', assetPath: 'lib/assets/lebrinha.png', url: 'https://lebrinha.com.br/'),
    Partner(
      name: 'Coco Bambu',
      assetPath: 'lib/assets/coco_bambu.png',
      url: 'https://www.instagram.com/cocobambugyn/',
    ),
    Partner(name: 'Leinertex', assetPath: 'lib/assets/leinertex.png', url: 'https://leinertex.com.br/'),
    Partner(name: 'Mega Frios', assetPath: 'lib/assets/mega_frios.png', url: 'https://www.instagram.com/megafrios/'),
    Partner(name: 'Linq Telecom', assetPath: 'lib/assets/linq.png', url: 'https://linq.net.br/'),
    Partner(name: 'La Fruit', assetPath: 'lib/assets/la_fruit.png', url: 'https://www.grupoimperial.com.br/la-fruit/'),
    Partner(
      name: 'Goianinho',
      assetPath: 'lib/assets/goianinho.png',
      url: 'https://www.grupoimperial.com.br/goianinho/',
    ),
    Partner(name: 'Italac', assetPath: 'lib/assets/italac.png', url: 'https://www.italac.com.br/'),
    Partner(name: 'CenterPisos', assetPath: 'lib/assets/center_pisos.png', url: 'https://www.centerpisos.com.br/'),
    Partner(name: 'Tikmais', assetPath: 'lib/assets/tikt.png', url: 'https://tikmais.com.br/'),
    Partner(name: 'Mata Pragas', assetPath: 'lib/assets/mata_pragas.png', url: 'https://www.matapragas.com/'),
    Partner(
      name: 'Óticas Motta',
      assetPath: 'lib/assets/oticas_motta.png',
      url: 'https://www.instagram.com/oticasmotta/?hl=pt-br',
    ),
    Partner(name: 'Abelha Rainha', assetPath: 'lib/assets/abelha_rainha.png', url: 'https://www.abelharainha.com.br/'),
    Partner(name: 'Xodó', assetPath: 'lib/assets/xodo.png', url: 'https://www.xododeminas.com.br/'),
    Partner(name: 'Replicadores', assetPath: 'lib/assets/replicadores.png', url: 'https://replicadores.com.br/'),
    Partner(name: 'Tymus', assetPath: 'lib/assets/tymus.png', url: 'https://tymuschat.com.br/'),
  ];
}
