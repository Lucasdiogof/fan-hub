import 'package:goias_app/features/passport/domain/club_passport_content.dart';

/// Cópia do Passaporte do Vila Nova. "Colorado" é o gentílico da torcida e
/// "Tigrão" o apelido institucional do clube (ver
/// `docs/vila_nova_data/data/club.json`). O nome do produto ("Passaporte
/// Colorado") é sugestão do pacote de pesquisa, não um nome oficial do clube.
class VilaNovaPassportContent {
  const VilaNovaPassportContent._();

  static const content = ClubPassportContent(pt: _pt, en: _en, es: _es);
}

String _matchesLivedPt(int count) => switch (count) {
  0 => 'Nenhum jogo vivido ainda com o Tigrão',
  1 => '1 jogo cantando e vibrando com o Tigrão',
  _ => '$count jogos cantando e vibrando com o Tigrão',
};

String _matchesLivedEn(int count) => count == 1
    ? '1 match singing and roaring with Vila Nova'
    : '$count matches singing and roaring with Vila Nova';

String _matchesLivedEs(int count) => count == 1
    ? '1 partido cantando y vibrando con el Vila Nova'
    : '$count partidos cantando y vibrando con el Vila Nova';

const _pt = PassportCopy(
  title: 'Passaporte Colorado',
  cardDescription: 'Marque os jogos que você viveu com o Tigrão',
  emptyBody:
      'Marque os jogos que você viveu com o Tigrão e construa o seu '
      'Passaporte.',
  shareText: 'Essa é a minha trajetória com o Tigrão! 🔴⚪',
  levels: PassportLevelNames(
    starter: 'Primeiros Passos',
    present: 'Torcedor Presente',
    bleacher: 'Colorado de Arquibancada',
    roots: 'Colorado Raiz',
    legend: 'Lenda do Tigrão',
  ),
  matchesLived: _matchesLivedPt,
);

const _en = PassportCopy(
  title: 'Passaporte Colorado',
  cardDescription: 'Mark the matches you lived with Vila Nova',
  emptyBody:
      'Mark the matches you lived with Vila Nova and build your Passaporte.',
  shareText: 'This is my journey with Vila Nova! 🔴⚪',
  levels: PassportLevelNames(
    starter: 'First Steps',
    present: 'Regular Supporter',
    bleacher: 'Bleacher Colorado',
    roots: 'Colorado Roots',
    legend: 'Tigrão Legend',
  ),
  matchesLived: _matchesLivedEn,
);

const _es = PassportCopy(
  title: 'Passaporte Colorado',
  cardDescription: 'Marca los partidos que viviste con el Vila Nova',
  emptyBody:
      'Marca los partidos que viviste con el Vila Nova y construye tu '
      'Passaporte.',
  shareText: '¡Esta es mi trayectoria con el Vila Nova! 🔴⚪',
  levels: PassportLevelNames(
    starter: 'Primeros Pasos',
    present: 'Hincha Presente',
    bleacher: 'Colorado de Tribuna',
    roots: 'Raíz Colorada',
    legend: 'Leyenda del Tigrão',
  ),
  matchesLived: _matchesLivedEs,
);
