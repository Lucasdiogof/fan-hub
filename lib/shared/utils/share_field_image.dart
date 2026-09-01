import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Captura só o `RepaintBoundary` marcado por [fieldKey] (nunca a tela
/// inteira) e abre o compartilhamento nativo com essa imagem — usado tanto
/// pelo campo da torcida (`CrowdTab`) quanto pelo campo em edição
/// (`EscaleTab`), "como se fosse uma screenshot do campo".
Future<void> shareFieldImage(
  GlobalKey fieldKey, {
  required String text,
  required String fileName,
}) async {
  final boundary =
      fieldKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  final image = await boundary.toImage(pixelRatio: 2.5);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;
  final bytes = byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
    ),
  );
}
