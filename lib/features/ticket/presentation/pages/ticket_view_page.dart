import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/presentation/ticket_pdf.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:printing/printing.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Visualização real do PDF do ingresso (mock) — `PdfPreview` já renderiza
/// o PDF de verdade na tela; a barra de ações nativa do pacote fica
/// desligada porque o app usa seu próprio botão "Salvar ingresso" (mesmo
/// texto/estilo do resto do app) em vez do ícone padrão do `printing`.
class TicketViewPage extends StatelessWidget {
  const TicketViewPage({required this.ticket, super.key});

  final Ticket ticket;

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
                      BackButtonCircle(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PageTitle(context.l10n.ticketsViewTicketTitle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: PdfPreview(
                    build: (format) => buildTicketPdf(ticket, context.l10n),
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
                      onPressed: () => shareTicketPdf(ticket, context.l10n),
                      icon: const Icon(Icons.ios_share_rounded, size: 19),
                      label: Text(
                        context.l10n.ticketsSaveTicketButton,
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
