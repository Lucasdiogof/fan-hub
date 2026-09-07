import 'package:goias_app/features/passport/domain/passport_level.dart';

/// Identidade editorial do Passaporte, escrita por clube.
///
/// POR QUE ISTO NÃO É l10n COMUM, NEM DERIVA DE `ClubIdentity.fanDemonym`
///
/// A tentação óbvia seria uma chave `"Lenda {demonym}"` e cada clube manda o
/// seu gentílico. Isso quebra em português no primeiro clube: o Goiás tem
/// "Lenda Esmeraldina" (feminino, concordando com "Lenda") — a mesma fórmula
/// aplicada ao Bragantino produziria "Lenda Massa Bruta" no lugar de "Lenda
/// da Massa Bruta". Gênero, artigo e preposição não saem de interpolação.
///
/// Então o contrato aqui é: **cada clube entrega a frase pronta, já
/// localizada**. Nada nesta feature monta texto de identidade concatenando
/// pedaço — se um dia aparecer uma frase nova com identidade do clube, ela
/// entra aqui inteira, nos três idiomas, e não vira mais um `${...}`.
///
/// Não mora em `ClubInstitutionalContent` de propósito: aquilo é a parte
/// institucional do clube (história, títulos, hino, ídolos), e isto pertence
/// ao Passaporte. A tela lê sempre do clube ativo, nunca com `if (clube ==
/// tal)`.
class ClubPassportContent {
  const ClubPassportContent({
    required this.pt,
    required this.en,
    required this.es,
  });

  /// Os três idiomas são obrigatórios de propósito: um clube novo não
  /// compila enquanto não escrever a cópia inteira, em vez de silenciosamente
  /// cair no português pra quem está em inglês.
  final PassportCopy pt;
  final PassportCopy en;
  final PassportCopy es;

  PassportCopy forLanguageCode(String code) => switch (code) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
}

/// A cópia do Passaporte de um clube, num idioma.
class PassportCopy {
  const PassportCopy({
    required this.title,
    required this.cardDescription,
    required this.emptyBody,
    required this.shareText,
    required this.levels,
    required this.matchesLived,
  });

  /// Nome do produto — ex.: `'Passaporte Esmeraldino'`. Nome próprio: não se
  /// traduz em EN/ES, só o texto ao redor.
  final String title;

  /// Chamada do card no Arena.
  final String cardDescription;

  /// Texto do estado vazio, antes de qualquer jogo marcado.
  final String emptyBody;

  /// Legenda ao compartilhar a trajetória.
  final String shareText;

  final PassportLevelNames levels;

  /// Quantos jogos a pessoa viveu, já flexionado. É função em vez de string
  /// com placeholder porque cada clube (e cada idioma) decide as próprias
  /// formas — inclusive se existe um caso especial pra zero, que hoje só o
  /// português do Goiás tem.
  final String Function(int count) matchesLived;
}

/// Nome de cada faixa de progressão. Os cinco são obrigatórios: os dois
/// primeiros costumam ser neutros, mas ficam aqui junto dos outros pra
/// existir uma fonte só de nome de nível — não metade em l10n e metade no
/// clube.
class PassportLevelNames {
  const PassportLevelNames({
    required this.starter,
    required this.present,
    required this.bleacher,
    required this.roots,
    required this.legend,
  });

  final String starter;
  final String present;
  final String bleacher;
  final String roots;
  final String legend;

  String forLevel(PassportLevel level) => switch (level) {
    PassportLevel.starter => starter,
    PassportLevel.present => present,
    PassportLevel.bleacher => bleacher,
    PassportLevel.roots => roots,
    PassportLevel.legend => legend,
  };
}
