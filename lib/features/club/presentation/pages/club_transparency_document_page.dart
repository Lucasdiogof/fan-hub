import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:printing/printing.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

final _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ),
);

Future<Uint8List> _fetchPdfBytes(String url) async {
  final response = await _dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  return Uint8List.fromList(response.data!);
}

/// Visualização real do PDF de um documento de transparência — mesmo
/// padrão do ingresso (`TicketViewPage`): `PdfPreview` renderiza o PDF de
/// verdade na tela, com um botão próprio de baixar/compartilhar embaixo em
/// vez da barra de ações padrão do `printing`. A diferença é que aqui o
/// PDF vem de uma URL remota (site oficial do clube), não gerado no app.
class ClubTransparencyDocumentPage extends StatelessWidget {
  const ClubTransparencyDocumentPage({required this.document, super.key});

  final ClubTransparencyDocument document;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
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
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: PageTitle(document.title)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: PdfPreview(
                    build: (format) => _fetchPdfBytes(document.pdfUrl),
                    useActions: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    loadingWidget: const Center(child: GoiasLoadingIndicator()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final bytes = await _fetchPdfBytes(document.pdfUrl);
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: '${document.id}.pdf',
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 19),
                      label: Text(
                        context.l10n.clubTransparencyDownloadButton,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: matchCtaFilledStyle(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
