import 'package:flutter/material.dart' show Color;
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/shared/widgets/team_visuals/team_visual_identity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Equivalente do [StyledTeamBadge] pro PDF do ingresso — mesma fonte de
/// identidade visual ([resolveActiveClubVisualIdentity]/[TeamVisualIdentity],
/// já usada pelo widget Flutter), sem duplicar tabela de cor/sigla em outro
/// lugar. Existe só porque `package:pdf` usa sua própria árvore de widgets
/// (`pw.Widget`) — `StyledTeamBadge` (Flutter) não pode ser embutido direto
/// num `pw.Document`, não tem `package:pdf` como plataforma.
pw.Widget teamPdfBadge({required ClubConfig clubConfig, double size = 44}) {
  final identity = resolveActiveClubVisualIdentity(clubConfig);
  final primary = PdfColor.fromInt(identity.primaryColor.toARGB32());
  final secondary = identity.secondaryColor == null
      ? null
      : PdfColor.fromInt(identity.secondaryColor!.toARGB32());

  return pw.SizedBox(
    width: size,
    height: size,
    child: pw.Stack(
      alignment: pw.Alignment.center,
      children: [
        pw.CustomPaint(
          size: PdfPoint(size, size),
          painter: (canvas, pdfSize) => _paintShield(
            canvas,
            pdfSize,
            primary: primary,
            secondary: secondary,
          ),
        ),
        pw.Text(
          identity.acronym,
          style: pw.TextStyle(
            color: _legiblePdfTextColor(identity.primaryColor),
            fontWeight: pw.FontWeight.bold,
            fontSize: size * 0.32,
          ),
        ),
      ],
    ),
  );
}

PdfColor _legiblePdfTextColor(Color background) {
  return background.computeLuminance() > 0.55
      ? PdfColor.fromInt(0xFF14181B)
      : PdfColors.white;
}

/// Mesma geometria de escudo do `StyledTeamBadge` (Flutter), só espelhada
/// verticalmente: `package:pdf` usa eixo Y crescendo pra CIMA (origem no
/// canto inferior esquerdo), o oposto do `Canvas` do Flutter — sem inverter
/// aqui, a ponta do escudo sairia virada pra baixo... errado, pra cima.
void _paintShield(
  PdfGraphics canvas,
  PdfPoint size, {
  required PdfColor primary,
  PdfColor? secondary,
}) {
  final w = size.x;
  final h = size.y;

  void tracePath() {
    canvas
      ..moveTo(w * 0.5, h)
      ..curveTo(w * 0.5, h, w * 0.98, h * 0.92, w * 0.98, h * 0.92)
      ..lineTo(w * 0.98, h * 0.48)
      ..curveTo(w * 0.98, h * 0.22, w * 0.72, h * 0.06, w * 0.5, 0)
      ..curveTo(w * 0.28, h * 0.06, w * 0.02, h * 0.22, w * 0.02, h * 0.48)
      ..lineTo(w * 0.02, h * 0.92)
      ..curveTo(w * 0.02, h * 0.92, w * 0.5, h, w * 0.5, h)
      ..closePath();
  }

  tracePath();
  canvas
    ..setFillColor(primary)
    ..fillPath();

  if (secondary != null) {
    canvas.saveContext();
    tracePath();
    canvas.clipPath();
    canvas
      ..setFillColor(secondary)
      ..drawRect(0, 0, w, h * 0.28)
      ..fillPath();
    canvas.restoreContext();
  }

  tracePath();
  canvas
    ..setStrokeColor(const PdfColor(0, 0, 0, 0.15))
    ..setLineWidth(w * 0.035)
    ..strokePath();
}
