import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/pages/squad_member_detail_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';

void main() {
  tearDown(() => sl.reset());

  testWidgets(
    'REGRESSÃO 2026-09-09: atleta com instagramUrl próprio não quebra num '
    'clube sem Instagram do CLUBE configurado (Bragantino) — "Bad state: '
    'No element" achado ao vivo, causado por buscar o glifo do ícone via '
    '`SocialLinksData.all` (lista das redes DO CLUBE) em vez de um '
    'acessor direto',
    (tester) async {
      await sl.reset();
      sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
      expect(
        bragantinoClubConfig.integrations.socialInstagramUrl,
        isNull,
        reason:
            'a premissa do teste é justamente essa: clube sem Instagram '
            'próprio configurado',
      );

      const member = SquadMember(
        id: 'x',
        name: 'Atleta Teste',
        position: 'Zagueiro',
        positionGroup: 'Zagueiros',
        instagramUrl: 'https://instagram.com/atleta_teste',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SquadMemberDetailPage(member: member),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}
