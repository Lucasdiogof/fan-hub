import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
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
Future<void> shareTicketPdf(Ticket ticket, AppLocalizations l10n) async {
  final bytes = await buildTicketPdf(ticket, l10n);
  await Printing.sharePdf(bytes: bytes, filename: 'ingresso-${ticket.id}.pdf');
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
Future<Uint8List> buildTicketPdf(Ticket ticket, AppLocalizations l10n) async {
  final doc = pw.Document();
  final crestSvg = await rootBundle.loadString('lib/assets/branding/logo.svg');
  final maskedDocument = ticket.holderDocument.contains(RegExp(r'^\d{11}$'))
      ? maskCpf(ticket.holderDocument)
      : ticket.holderDocument;
  final kickoff = ticket.kickoff;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return [
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
                            child: _field(l10n.ticketPdfFieldGate, ticket.gate),
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
                    pw.Container(
                      width: 110,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _green, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Center(
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'GOIAS-EC-${ticket.id}',
                          width: 80,
                          height: 80,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  l10n.ticketPdfFooterNotice,
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: _grey,
                    fontWeight: pw.FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ];
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
