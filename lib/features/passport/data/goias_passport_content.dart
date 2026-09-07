import 'package:goias_app/features/passport/domain/club_passport_content.dart';

/// Identidade do Passaporte Esmeraldino.
///
/// Cada string aqui é a que já estava em `app_pt.arb`/`app_en.arb`/
/// `app_es.arb` — transcrita ao pé da letra, pontuação e emoji incluídos.
/// A migração para `ClubPassportContent` é de ORIGEM, não de conteúdo: nada
/// do que o torcedor do Goiás lê hoje muda.
///
/// Detalhe fácil de perder num "ajuste de consistência" futuro: só o
/// português tem caso especial pra zero jogos. Inglês e espanhol sempre
/// usaram a forma plural, inclusive no zero — era assim antes e continua.
class GoiasPassportContent {
  const GoiasPassportContent._();

  static const content = ClubPassportContent(pt: _pt, en: _en, es: _es);
}

String _matchesLivedPt(int count) => switch (count) {
  0 => 'Nenhum jogo vivido ainda com o Verdão',
  1 => '1 jogo cantando e vibrando com o Verdão',
  _ => '$count jogos cantando e vibrando com o Verdão',
};

String _matchesLivedEn(int count) => count == 1
    ? '1 match singing and roaring with Verdão'
    : '$count matches singing and roaring with Verdão';

String _matchesLivedEs(int count) => count == 1
    ? '1 partido cantando y vibrando con el Verdão'
    : '$count partidos cantando y vibrando con el Verdão';

const _pt = PassportCopy(
  title: 'Passaporte Esmeraldino',
  cardDescription: 'Marque os jogos que você viveu com o Verdão.',
  emptyBody:
      'Marque os jogos que você viveu com o Verdão e construa seu '
      'Passaporte Esmeraldino.',
  shareText: 'Essa é a minha trajetória com o Goiás! 💚',
  levels: PassportLevelNames(
    starter: 'Primeiros Passos',
    present: 'Torcedor Presente',
    bleacher: 'Esmeraldino de Arquibancada',
    roots: 'Verdão Raiz',
    legend: 'Lenda Esmeraldina',
  ),
  matchesLived: _matchesLivedPt,
);

const _en = PassportCopy(
  title: 'Passaporte Esmeraldino',
  cardDescription: 'Mark the matches you lived with Goiás.',
  emptyBody:
      'Mark the matches you lived with Verdão and build your '
      'Passaporte Esmeraldino.',
  shareText: 'This is my journey with Goiás! 💚',
  levels: PassportLevelNames(
    starter: 'First Steps',
    present: 'Regular Supporter',
    bleacher: 'Bleacher Esmeraldino',
    roots: 'Verdão Roots',
    legend: 'Esmeraldino Legend',
  ),
  matchesLived: _matchesLivedEn,
);

const _es = PassportCopy(
  title: 'Passaporte Esmeraldino',
  cardDescription: 'Marca los partidos que viviste con el Goiás.',
  emptyBody:
      'Marca los partidos que viviste con el Verdão y construye tu '
      'Passaporte Esmeraldino.',
  shareText: '¡Esta es mi trayectoria con el Goiás! 💚',
  levels: PassportLevelNames(
    starter: 'Primeros Pasos',
    present: 'Hincha Presente',
    bleacher: 'Esmeraldino de Tribuna',
    roots: 'Raíz Verdão',
    legend: 'Leyenda Esmeraldina',
  ),
  matchesLived: _matchesLivedEs,
);
