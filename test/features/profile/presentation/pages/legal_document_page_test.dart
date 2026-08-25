import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/profile/data/legal_documents_data.dart';
import 'package:goias_app/features/profile/domain/entities/legal_document.dart';
import 'package:goias_app/features/profile/presentation/pages/legal_document_page.dart';

void main() {
  Widget wrap(LegalDocument document) {
    return MaterialApp(
      theme: AppTheme.light,
      home: LegalDocumentPage(document: document),
    );
  }

  // Documento longo — o ListView só materializa o que está visível no
  // viewport padrão de teste. Aumenta a "tela" pra tudo renderizar de uma
  // vez, já que o teste checa até a última seção sem rolar.
  void useTallSurface(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(800, 12000);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('renders every section title of the terms of use', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap(LegalDocumentsData.termsOfUse));

    expect(find.text('TERMOS DE USO'), findsOneWidget);
    for (final section in LegalDocumentsData.termsOfUse.sections) {
      expect(find.text(section.title), findsOneWidget, reason: section.title);
    }
  });

  testWidgets('renders every section title of the privacy policy', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap(LegalDocumentsData.privacyPolicy));

    expect(find.text('POLÍTICA DE PRIVACIDADE'), findsOneWidget);
    for (final section in LegalDocumentsData.privacyPolicy.sections) {
      expect(find.text(section.title), findsOneWidget, reason: section.title);
    }
  });
}
