import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/profile/presentation/widgets/social_links_section.dart';

void main() {
  testWidgets('shows the section title and description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SocialLinksSection()),
      ),
    );

    expect(find.text('SIGA O GOIÁS'), findsOneWidget);
    expect(
      find.text('Acompanhe o Verdão também nas redes sociais.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders one tappable tile per channel, labeled for accessibility',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SocialLinksSection()),
        ),
      );

      for (final name in [
        'Instagram',
        'YouTube',
        'TikTok',
        'Facebook',
        'X',
        'Site oficial',
      ]) {
        expect(find.bySemanticsLabel('Abrir $name'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'does not show a text label under the icon — logo only, per feedback',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SocialLinksSection()),
        ),
      );

      expect(find.text('Instagram'), findsNothing);
      expect(find.text('YouTube'), findsNothing);
    },
  );

  testWidgets(
    'tapping a tile never throws an uncaught exception — openExternalUrl always catches',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SocialLinksSection()),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Abrir Instagram'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
