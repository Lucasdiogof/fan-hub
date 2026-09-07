import 'package:goias_app/features/passport/domain/club_passport_content.dart';

/// Cópia de Passaporte de um clube sintético — só teste, nunca no
/// `clubRegistry`.
///
/// Toda string aqui é deliberadamente reconhecível ("Sintético B") e não
/// contém nada do Goiás nem do Bragantino. É isso que faz os testes de
/// isolamento valerem: se a tela cair no conteúdo do clube errado, aparece
/// "Esmeraldino" ou "Massa Bruta" onde deveria aparecer "Sintético B", e o
/// teste quebra. Uma fixture que reaproveitasse a cópia do Goiás nunca
/// provaria esse tipo de vazamento.
const syntheticPassportContent = ClubPassportContent(
  pt: PassportCopy(
    title: 'Passaporte Sintético B',
    cardDescription: 'Marque os jogos do Clube Sintético B.',
    emptyBody: 'Nada marcado ainda no Clube Sintético B.',
    shareText: 'Minha trajetória no Clube Sintético B!',
    levels: PassportLevelNames(
      starter: 'Nível B 1',
      present: 'Nível B 2',
      bleacher: 'Nível B 3',
      roots: 'Nível B 4',
      legend: 'Nível B 5',
    ),
    matchesLived: _syntheticMatchesLivedPt,
  ),
  en: PassportCopy(
    title: 'Passaporte Sintético B',
    cardDescription: 'Mark the matches of Clube Sintético B.',
    emptyBody: 'Nothing marked yet at Clube Sintético B.',
    shareText: 'My journey at Clube Sintético B!',
    levels: PassportLevelNames(
      starter: 'B Level 1',
      present: 'B Level 2',
      bleacher: 'B Level 3',
      roots: 'B Level 4',
      legend: 'B Level 5',
    ),
    matchesLived: _syntheticMatchesLivedEn,
  ),
  es: PassportCopy(
    title: 'Passaporte Sintético B',
    cardDescription: 'Marca los partidos del Clube Sintético B.',
    emptyBody: 'Nada marcado todavía en el Clube Sintético B.',
    shareText: '¡Mi trayectoria en el Clube Sintético B!',
    levels: PassportLevelNames(
      starter: 'Nivel B 1',
      present: 'Nivel B 2',
      bleacher: 'Nivel B 3',
      roots: 'Nivel B 4',
      legend: 'Nivel B 5',
    ),
    matchesLived: _syntheticMatchesLivedEs,
  ),
);

String _syntheticMatchesLivedPt(int count) => '$count jogos no Sintético B';
String _syntheticMatchesLivedEn(int count) => '$count matches at Sintético B';
String _syntheticMatchesLivedEs(int count) => '$count partidos en Sintético B';
