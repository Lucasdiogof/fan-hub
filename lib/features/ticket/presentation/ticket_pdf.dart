import 'dart:typed_data';

import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
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
Future<void> shareTicketPdf(Ticket ticket) async {
  final bytes = await buildTicketPdf(ticket);
  await Printing.sharePdf(bytes: bytes, filename: 'ingresso-${ticket.id}.pdf');
}

const _green = PdfColor.fromInt(0xFF004C1B);
const _grey = PdfColor.fromInt(0xFF6B7280);

/// PDF mock do ingresso — usado tanto pro ingresso de check-in quanto pro
/// de compra, só os dados mudam ([Ticket.origin]/[Ticket.price]/
/// [Ticket.categoryLabel]). Deixa explícito em texto e no QR Code que é
/// demonstração — nada aqui deve ser tratado como credencial real de
/// acesso, é só o formato que a integração futura com a API de ingressos
/// vai preencher de verdade.
Future<Uint8List> buildTicketPdf(Ticket ticket) async {
  final doc = pw.Document();
  final maskedDocument = ticket.holderDocument.contains(RegExp(r'^\d{11}$'))
      ? maskCpf(ticket.holderDocument)
      : ticket.holderDocument;
  final kickoff = ticket.kickoff;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return [
          pw.Text(
            'GOIÁS ESPORTE CLUBE',
            style: const pw.TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF4CC),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'DEMONSTRAÇÃO — não é um ingresso válido de acesso',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            ticket.competition,
            style: const pw.TextStyle(fontSize: 10, color: _grey),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${shortTeamName(ticket.homeTeam.name)} x ${shortTeamName(ticket.awayTeam.name)}',
            style: const pw.TextStyle(
              fontSize: 18,
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
          pw.Row(
            children: [
              pw.Expanded(
                child: _field(
                  'Data',
                  kickoff != null ? fullDateLabel(kickoff) : 'A confirmar',
                ),
              ),
              pw.Expanded(
                child: _field(
                  'Horário',
                  kickoff != null ? timeLabel(kickoff) : '—',
                ),
              ),
            ],
          ),
          _field('Estádio', ticket.stadium),
          pw.Row(
            children: [
              pw.Expanded(child: _field('Setor', ticket.sectorName)),
              pw.Expanded(child: _field('Portão', ticket.gate)),
            ],
          ),
          if (ticket.categoryLabel != null)
            _field('Categoria', ticket.categoryLabel!),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          _field('Titular', ticket.holderName),
          _field('CPF/Passaporte', maskedDocument),
          _field(
            'Origem',
            ticket.origin == TicketOrigin.membershipCheckIn
                ? 'Check-in Sócio'
                : 'Compra',
          ),
          if (ticket.price != null) _field('Valor', formatBrl(ticket.price!)),
          _field('Identificador', ticket.id),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Column(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'DEMO-TICKET-${ticket.id}',
                  width: 90,
                  height: 90,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'QR Code de demonstração',
                  style: const pw.TextStyle(fontSize: 7, color: _grey),
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
  padding: const pw.EdgeInsets.only(bottom: 8),
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
