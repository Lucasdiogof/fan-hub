import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

/// Exibe um PDF remoto (ex.: press kit de uma notícia) dentro do próprio
/// app, com opção de compartilhar — mesmo padrão já usado pro PDF do
/// ingresso (`ticket_view_page.dart`: `PdfPreview` + `Printing.sharePdf`),
/// só que aqui os bytes vêm de download em vez de geração local. Antes
/// disso, um link de PDF dentro de uma notícia abria no navegador externo
/// e saía do app.
class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({required this.url, required this.title, super.key});

  final String url;
  final String title;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late Future<Uint8List> _bytesFuture = _download();

  Future<Uint8List> _download() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} ao baixar ${widget.url}');
    }
    return response.bodyBytes;
  }

  void _retry() => setState(() => _bytesFuture = _download());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  BackButtonCircle(
                    size: 34,
                    iconSize: 16,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _bytesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: GoiasLoadingIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: StateMessage(
                        icon: Icons.picture_as_pdf_outlined,
                        title: context.l10n.newsPdfLoadErrorTitle,
                        message: context.l10n.commonLoadError,
                        actionLabel: context.l10n.commonRetry,
                        onAction: _retry,
                      ),
                    );
                  }
                  final bytes = snapshot.data!;
                  return Column(
                    children: [
                      Expanded(
                        child: PdfPreview(
                          build: (format) async => bytes,
                          useActions: false,
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          loadingWidget: const Center(
                            child: GoiasLoadingIndicator(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: () => Printing.sharePdf(
                              bytes: bytes,
                              filename: '${_fileName(widget.title)}.pdf',
                            ),
                            icon: const Icon(Icons.ios_share_rounded, size: 19),
                            label: Text(context.l10n.newsPdfShareButton),
                            style: matchCtaFilledStyle(context),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fileName(String title) => title
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Detecta se um link do corpo da notícia aponta pra um PDF (ex.: press
/// kit) — ignora query string (`?token=...`) e maiúsculas/minúsculas.
bool isPdfUrl(String url) {
  final withoutQuery = url.split('?').first;
  return withoutQuery.toLowerCase().endsWith('.pdf');
}
