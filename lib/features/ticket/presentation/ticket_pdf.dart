import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// "Salvar ingresso" no resto do app — gera o PDF e abre o compartilhamento
/// nativo, mesmo padrão já usado pra imagem da escalação
/// (`shareFieldImage`), só que aqui via `printing` (que já embute o próprio
/// fluxo de compartilhar/salvar bytes de PDF).
Future<void> shareTicketPdf(
  Ticket ticket,
  AppLocalizations l10n, {
  required bool isDemo,
}) async {
  final bytes = await buildTicketPdf(ticket, l10n, isDemo: isDemo);
  await Printing.sharePdf(bytes: bytes, filename: 'ingresso-${ticket.id}.pdf');
}

/// Payload do QR do ingresso — extraído pra função pura testável sem
/// montar PDF nenhum. `DEMO-` nunca é omitido quando [isDemo]: o payload
/// em si precisa ser inequivocamente diferente de uma emissão real, não
/// só o texto ao redor do QR.
String ticketQrPayload(String ticketId, {required bool isDemo}) =>
    isDemo ? 'DEMO-GOIAS-EC-$ticketId' : 'GOIAS-EC-$ticketId';

/// Tema do PDF do ingresso — existe por causa de um limite concreto do
/// pacote `pdf`: o Helvetica embutido é um Type1 cujo `isRuneSupported` é
/// literalmente `charCode >= 0x00 && charCode <= 0xff`
/// (`pdf/src/pdf/obj/type1_font.dart`). Acento de português passa (tudo
/// abaixo de 0xFF), mas pontuação tipográfica não: em dash (U+2014),
/// bullet (U+2022), aspas curvas e reticências ficam de fora. E o pacote
/// não ignora o caractere que não sabe desenhar — ele desenha um
/// `Placeholder`, o retângulo riscado. Ou seja, sem uma fonte de verdade o
/// ingresso sai com caixas cruzadas no meio do texto.
///
/// Lato cobre tudo isso e é SIL OFL (ver `lib/assets/fonts/OFL.txt`).
/// Carregada uma vez por processo: são ~640 KB por peso, e reparsear a
/// cada ingresso gerado seria desperdício puro.
pw.ThemeData? _cachedTheme;

Future<pw.ThemeData> ticketPdfTheme() async {
  final cached = _cachedTheme;
  if (cached != null) return cached;

  final base = pw.Font.ttf(
    await rootBundle.load('lib/assets/fonts/Lato-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('lib/assets/fonts/Lato-Bold.ttf'),
  );
  // `italic` aponta pros mesmos arquivos de propósito: o ingresso não usa
  // itálico em lugar nenhum, e embutir mais dois pesos só pra preencher o
  // tema seria peso morto no bundle.
  return _cachedTheme = pw.ThemeData.withFont(
    base: base,
    bold: bold,
    italic: base,
    boldItalic: bold,
  );
}

const _green = PdfColor.fromInt(0xFF004C1B);
const _greenBanner = PdfColor.fromInt(0xFF0B7A3B);
const _grey = PdfColor.fromInt(0xFF6B7280);
const _cardBg = PdfColor.fromInt(0xFFF2F3F5);

/// PDF do ingresso — usado tanto pro ingresso de check-in quanto pro de
/// compra, só os dados mudam ([Ticket.origin]/[Ticket.price]/
/// [Ticket.categoryLabel]). Layout espelha o formato de ingresso físico
/// real do Goiás (cabeçalho com escudo, faixa da competição, card de
/// dados, aviso antifraude ao lado do QR) — a integração futura com a API
/// de ingressos preenche os mesmos campos com dados reais.
///
/// [isDemo] (auditoria 2026-09-05, `ticketCommerceMode`) — enquanto true,
/// aplica uma marca d'água diagonal + faixa fixa no rodapé, nunca só um
/// aviso na tela anterior (que some com print/corte). O payload do QR
/// também troca de namespace (`DEMO-GOIAS-EC-`), pra nunca ser confundido
/// com uma emissão real mesmo se extraído do PDF.
Future<Uint8List> buildTicketPdf(
  Ticket ticket,
  AppLocalizations l10n, {
  required bool isDemo,
}) async {
  final doc = pw.Document(theme: await ticketPdfTheme());
  final crestSvg = await rootBundle.loadString('lib/assets/branding/logo.svg');
  final maskedDocument = ticket.holderDocument.contains(RegExp(r'^\d{11}$'))
      ? maskCpf(ticket.holderDocument)
      : ticket.holderDocument;
  final kickoff = ticket.kickoff;

  // `Page` e não `MultiPage`: um ingresso é UMA página por definição —
  // paginar um ingresso não faz sentido. E como o conteúdo é uma `Column`
  // (que não é `SpanningWidget`), o `MultiPage` não conseguia nem quebrar
  // nem encolher: passando da altura da A5 ele simplesmente lançava. Foi o
  // crash real em produção — o modo demonstração sozinho já estourava, e
  // com nomes longos de setor/titular chegava a 694pt contra 595pt de página.
  //
  // O `FittedBox` com `scaleDown` é a rede: se couber, nada muda; se passar,
  // encolhe proporcionalmente em vez de derrubar a tela. O `SizedBox` com a
  // largura da página é necessário porque o `FittedBox` mede o filho sem
  // restrição, e o cabeçalho usa `width: double.infinity`.
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        final content = pw.Column(
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(24, 28, 24, 20),
              color: _green,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SvgImage(svg: crestSvg, width: 44, height: 44),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          ticket.sectorName.toUpperCase(),
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (ticket.categoryLabel != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            ticket.categoryLabel!.toUpperCase(),
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              color: _greenBanner,
              alignment: pw.Alignment.center,
              child: pw.Text(
                ticket.competition.toUpperCase(),
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${shortTeamName(ticket.homeTeam.name)} x ${shortTeamName(ticket.awayTeam.name)}',
                    style: const pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (ticket.round.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      ticket.round,
                      style: const pw.TextStyle(fontSize: 9, color: _grey),
                    ),
                  ],
                  pw.SizedBox(height: 16),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: _cardBg,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _field(l10n.ticketPdfFieldVenue, ticket.stadium),
                        _field(
                          l10n.matchFieldDate,
                          kickoff != null
                              ? '${fullDateLabel(kickoff)} ${timeLabel(kickoff)}'
                              : l10n.matchToBeConfirmed,
                        ),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _field(
                                l10n.membershipSectorLabel,
                                ticket.sectorName,
                              ),
                            ),
                            pw.Expanded(
                              child: _field(
                                l10n.ticketPdfFieldGate,
                                ticket.gate,
                              ),
                            ),
                          ],
                        ),
                        if (ticket.categoryLabel != null)
                          _field(
                            l10n.ticketPdfFieldCategory,
                            ticket.categoryLabel!,
                          ),
                        _field(l10n.membershipHolder, ticket.holderName),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _field(
                                l10n.ticketPdfFieldDocument,
                                maskedDocument,
                              ),
                            ),
                            pw.Expanded(
                              child: _field(
                                l10n.ticketPdfFieldOrigin,
                                ticket.origin == TicketOrigin.membershipCheckIn
                                    ? l10n.ticketsOriginCheckIn
                                    : l10n.ticketsOriginPurchase,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _field(
                                l10n.ticketPdfFieldAmount,
                                formatBrl(ticket.price ?? 0),
                              ),
                            ),
                            pw.Expanded(
                              child: _field(l10n.ticketPdfFieldCode, ticket.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(14),
                          decoration: pw.BoxDecoration(
                            color: _green,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                l10n.ticketPdfAntiScalpingTitle,
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                l10n.ticketPdfAntiScalpingSubtitle,
                                style: const pw.TextStyle(
                                  color: PdfColor(1, 1, 1, 0.85),
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 110,
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: _green, width: 1.5),
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.Center(
                              // Um QR Code só é gerado pra ingresso ATIVO — um
                              // reembolsado/cancelado/usado/expirado nunca pode
                              // ser escaneado como entrada válida. O namespace
                              // `DEMO-` (quando `isDemo`) nunca é omitido — o
                              // payload em si precisa ser inequivocamente
                              // diferente de uma emissão real, não só o texto
                              // ao redor.
                              child: ticket.status == TicketStatus.active
                                  ? pw.BarcodeWidget(
                                      barcode: pw.Barcode.qrCode(),
                                      data: ticketQrPayload(
                                        ticket.id,
                                        isDemo: isDemo,
                                      ),
                                      width: 80,
                                      height: 80,
                                      color: PdfColors.black,
                                    )
                                  : pw.Text(
                                      l10n.ticketPdfInvalidTicket,
                                      textAlign: pw.TextAlign.center,
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _grey,
                                      ),
                                    ),
                            ),
                          ),
                          if (isDemo &&
                              ticket.status == TicketStatus.active) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              l10n.ticketPdfDemoQrCaption,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: _grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    l10n.ticketPdfFooterNotice(
                      sl<ClubConfig>().identity.shortName,
                    ),
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: _grey,
                      fontWeight: pw.FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  if (isDemo) ...[
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red800,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        l10n.ticketPdfDemoWatermark.replaceAll('\n', ' — '),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        // Marca d'água diagonal por cima de TUDO — nunca só um aviso na
        // tela anterior (some com print/corte de tela) e nunca só a faixa
        // fixa do rodapé (fácil de cortar fora numa impressão). Repetida
        // (não 1 só grande) pra sobreviver a qualquer recorte parcial do
        // documento.
        final page = pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment.topCenter,
          child: pw.SizedBox(width: PdfPageFormat.a5.width, child: content),
        );
        if (!isDemo) return page;
        // A marca d'água fica FORA do FittedBox: ela cobre a página inteira,
        // não o conteúdo — se entrasse junto, encolheria com ele e deixaria
        // uma faixa sem marca embaixo, que é justamente o pedaço fácil de
        // recortar.
        return pw.Stack(
          children: [
            page,
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: 0.5,
                  child: pw.Opacity(
                    opacity: 0.16,
                    child: pw.Text(
                      l10n.ticketPdfDemoWatermark,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _field(String label, String value) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 10),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: 7.5,
          color: _grey,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
      pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
    ],
  ),
);
