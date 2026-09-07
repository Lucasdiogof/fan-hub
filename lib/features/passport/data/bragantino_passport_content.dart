import 'package:goias_app/features/passport/domain/club_passport_content.dart';

/// Identidade do Passaporte Massa Bruta.
///
/// Título, subtítulo, compartilhamento e os três níveis com identidade
/// (`bleacher`, `roots`, `legend`) foram escritos pelo usuário — não mexer
/// sem ele. `starter`/`present` continuam com a redação neutra que o app já
/// usava ("Primeiros Passos"/"Torcedor Presente"), porque não carregam nome
/// de clube; se o Bragantino quiser nome próprio nessas duas faixas, é
/// decisão dele, não invenção daqui.
///
/// `Massa Bruta` e `Braga` são nomes próprios: em inglês e espanhol só a
/// frase ao redor é traduzida.
///
/// Nada aqui é derivado do Goiás. Nenhuma string deste arquivo pode conter
/// "Esmeraldino", "Verdão", "Goiás" ou "Esmeralda" — há teste travando isso.
class BragantinoPassportContent {
  const BragantinoPassportContent._();

  static const content = ClubPassportContent(pt: _pt, en: _en, es: _es);
}

String _matchesLivedPt(int count) => switch (count) {
  0 => 'Nenhum jogo vivido ainda com o Massa Bruta',
  1 => '1 jogo cantando e vibrando com o Massa Bruta',
  _ => '$count jogos cantando e vibrando com o Massa Bruta',
};

String _matchesLivedEn(int count) => count == 1
    ? '1 match singing and roaring with Massa Bruta'
    : '$count matches singing and roaring with Massa Bruta';

String _matchesLivedEs(int count) => count == 1
    ? '1 partido cantando y vibrando con el Massa Bruta'
    : '$count partidos cantando y vibrando con el Massa Bruta';

const _pt = PassportCopy(
  title: 'Passaporte Massa Bruta',
  cardDescription: 'Marque os jogos que você viveu com o Massa Bruta',
  // Sem repetir "Massa Bruta" duas vezes na mesma frase — no Goiás as duas
  // metades têm nomes diferentes ("Verdão" e "Esmeraldino"), aqui seriam o
  // mesmo nome colado.
  emptyBody:
      'Marque os jogos que você viveu com o Massa Bruta e construa o seu '
      'Passaporte.',
  shareText: 'Essa é a minha trajetória com o Massa Bruta! 🔴⚪',
  levels: PassportLevelNames(
    starter: 'Primeiros Passos',
    present: 'Torcedor Presente',
    bleacher: 'Bragantino de Arquibancada',
    roots: 'Braga Raiz',
    legend: 'Lenda da Massa Bruta',
  ),
  matchesLived: _matchesLivedPt,
);

const _en = PassportCopy(
  title: 'Passaporte Massa Bruta',
  cardDescription: 'Mark the matches you lived with Massa Bruta',
  emptyBody:
      'Mark the matches you lived with Massa Bruta and build your Passaporte.',
  shareText: 'This is my journey with Massa Bruta! 🔴⚪',
  levels: PassportLevelNames(
    starter: 'First Steps',
    present: 'Regular Supporter',
    bleacher: 'Bleacher Bragantino',
    roots: 'Braga Roots',
    legend: 'Massa Bruta Legend',
  ),
  matchesLived: _matchesLivedEn,
);

const _es = PassportCopy(
  title: 'Passaporte Massa Bruta',
  cardDescription: 'Marca los partidos que viviste con el Massa Bruta',
  emptyBody:
      'Marca los partidos que viviste con el Massa Bruta y construye tu '
      'Passaporte.',
  shareText: '¡Esta es mi trayectoria con el Massa Bruta! 🔴⚪',
  levels: PassportLevelNames(
    starter: 'Primeros Pasos',
    present: 'Hincha Presente',
    bleacher: 'Bragantino de Tribuna',
    roots: 'Raíz Braga',
    legend: 'Leyenda de la Massa Bruta',
  ),
  matchesLived: _matchesLivedEs,
);
