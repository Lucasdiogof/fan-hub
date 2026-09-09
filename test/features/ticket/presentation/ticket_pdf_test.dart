import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/presentation/ticket_pdf.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

const _home = Team(
  id: 1863,
  name: 'Goiás',
  shortName: 'GOI',
  color: Color(0xFF004C1B),
);
const _away = Team(
  id: 2,
  name: 'Vila Nova',
  shortName: 'VNO',
  color: Color(0xFF1F6F4A),
);

Ticket _ticket({
  String sectorName = 'Arquibancada',
  String venueLabel = 'Estádio Hailé Pinheiro',
  String holderName = 'Torcedor Esmeraldino',
  String? categoryLabel,
  double? price,
}) => Ticket(
  id: 'tkt-1',
  matchId: 'match-1',
  competition: 'Campeonato Brasileiro Série B',
  round: 'Rodada 20',
  homeTeam: _home,
  awayTeam: _away,
  kickoff: DateTime(2026, 8, 15, 19),
  stadium: 'Estádio Hailé Pinheiro',
  sectorName: sectorName,
  venueLabel: venueLabel,
  gate: 'Portão 3',
  holderName: holderName,
  holderDocument: '12345678901',
  status: TicketStatus.active,
  origin: TicketOrigin.purchase,
  createdAt: DateTime(2026, 8, 1),
  categoryLabel: categoryLabel,
  price: price,
);

/// O PDF do ingresso é montado numa `Column` única numa página A5 (595,28pt
/// de altura). Uma Column não é `SpanningWidget`, então quando o conteúdo
/// passa da altura da página o `pdf` lança em vez de encolher — foi
/// exatamente o crash visto em produção ("height 650.424 exceed a page
/// height 595.275"). Os testes abaixo cobrem os dois lados: o ingresso
/// comum e o que tem os textos mais longos que a tela realmente produz.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  tearDown(() => sl.reset());

  test('ingresso comum gera PDF sem estourar a página', () async {
    final bytes = await buildTicketPdf(_ticket(), l10n, isDemo: false);
    expect(bytes, isNotEmpty);
  });

  test('ingresso de demonstração (marca d\'água) também cabe', () async {
    final bytes = await buildTicketPdf(_ticket(), l10n, isDemo: true);
    expect(bytes, isNotEmpty);
  });

  test('ingresso comprado, com categoria e preço, cabe', () async {
    final bytes = await buildTicketPdf(
      _ticket(categoryLabel: 'Meia-entrada estudante', price: 45),
      l10n,
      isDemo: true,
    );
    expect(bytes, isNotEmpty);
  });

  test('textos longos não derrubam a geração', () async {
    // Nomes de setor/local/titular longos são o que empurra a Column pra
    // além da página: cada um que quebra em duas linhas soma altura.
    final bytes = await buildTicketPdf(
      _ticket(
        sectorName: 'Cadeira Coberta Central Superior Setor Vermelho',
        venueLabel: 'Estádio Hailé Pinheiro (Serrinha) — Goiânia, Goiás',
        holderName: 'Maria Aparecida de Souza Oliveira dos Santos Filha',
        categoryLabel: 'Meia-entrada para estudante da rede pública estadual',
        price: 129.9,
      ),
      l10n,
      isDemo: true,
    );
    expect(bytes, isNotEmpty);
  });

  group('fonte embutida', () {
    // O Helvetica embutido no pacote `pdf` é um Type1 cujo isRuneSupported é
    // `charCode <= 0xff` (pdf/src/pdf/obj/type1_font.dart). Quem cai fora
    // disso não é ignorado: vira um Placeholder, o retângulo riscado, no meio
    // do ingresso. Por isso o documento precisa de uma fonte TTF de verdade.
    const glifos = {
      0x2014: 'em dash',
      0x2022: 'bullet',
      0x2013: 'en dash',
      0x2026: 'reticências',
      0x201C: 'aspa curva esquerda',
      0x201D: 'aspa curva direita',
    };

    for (final arquivo in ['Lato-Regular.ttf', 'Lato-Bold.ttf']) {
      test('$arquivo traz a pontuação tipográfica e os acentos', () async {
        final parser = TtfParser(
          await rootBundle.load('lib/assets/fonts/$arquivo'),
        );
        glifos.forEach((rune, nome) {
          expect(
            parser.charToGlyphIndexMap.containsKey(rune),
            isTrue,
            reason:
                '$nome (U+${rune.toRadixString(16)}) sairia como caixa riscada',
          );
        });
        for (final char in 'áàâãéêíóôõúüçÁÃÇÉÍÓÕÚ'.runes) {
          expect(parser.charToGlyphIndexMap.containsKey(char), isTrue);
        }
      });
    }

    test('o tema usa TTF nos dois pesos, não o Type1 embutido', () async {
      final theme = await ticketPdfTheme();
      // `TtfFont` é o que `Font.ttf` devolve; qualquer `Font.type1` aqui
      // significaria ter voltado pro Helvetica com o limite de 0xFF.
      expect(theme.defaultTextStyle.font, isA<TtfFont>());
      expect(theme.defaultTextStyle.fontBold, isA<TtfFont>());
    });

    test('o tema é reaproveitado entre ingressos', () async {
      // ~640 KB por peso: reparsear a cada PDF gerado seria desperdício.
      expect(identical(await ticketPdfTheme(), await ticketPdfTheme()), isTrue);
    });
  });

  group('payload do QR', () {
    test('emissão real não carrega prefixo de demonstração', () {
      expect(ticketQrPayload('abc', isDemo: false), 'GOIAS-EC-abc');
    });

    test('demonstração é inequívoca no próprio payload', () {
      expect(ticketQrPayload('abc', isDemo: true), 'DEMO-GOIAS-EC-abc');
    });
  });
}
