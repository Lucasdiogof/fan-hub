// Auditoria de branding cross-club 2026-09-09 — 4 chaves l10n em telas
// COMPARTILHADAS (Arena, Notícias, Clube/Músicas, Ingressos) tinham texto
// fixo "Goiás"/"Esmeraldino" sem nenhum `{clubCode, select, ...}`, então
// sempre apareciam pro Bragantino também. arenaAchievementTitle,
// newsSourceLabel e clubSongsSection já eram vazamento AO VIVO (Arena,
// Notícias e Clube já estão ligados pro Bragantino); ticketsHomeCrowdLabel
// segue dormente (hasTickets=false hoje), corrigido preventivamente pro
// mesmo bug não se repetir quando a capability ligar — mesma lição do
// vazamento real achado em storeHomeEntryBadge (ver
// store_entry_card_test.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/l10n/app_localizations.dart';

const _goiasLeakTerms = ['Goiás', 'GOIÁS', 'Verdão', 'Esmeraldin'];

Future<Map<String, String>> _renderAll(
  WidgetTester tester,
  ClubConfig club,
  Locale locale,
) async {
  await sl.reset();
  sl.registerSingleton<ClubConfig>(club);

  final values = <String, String>{};
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final code = club.identity.code;
          final name = club.identity.shortName.toUpperCase();
          values['arenaAchievementTitle'] = l10n.arenaAchievementTitle(
            code,
            name,
          );
          values['newsSourceLabel'] = l10n.newsSourceLabel(code, name);
          values['clubSongsSection'] = l10n.clubSongsSection(code, name);
          values['ticketsHomeCrowdLabel'] = l10n.ticketsHomeCrowdLabel(
            code,
            name,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return values;
}

void main() {
  tearDown(() => sl.reset());

  const pt = Locale('pt');
  const en = Locale('en');
  const es = Locale('es');

  group('Goiás preserva o texto EXATO de sempre (nunca muda)', () {
    testWidgets('pt', (tester) async {
      final v = await _renderAll(tester, goiasClubConfig, pt);
      expect(v['arenaAchievementTitle'], 'LENDA ESMERALDINA');
      expect(v['newsSourceLabel'], 'FONTE: GOIÁS ESPORTE CLUBE');
      expect(v['clubSongsSection'], 'MÚSICAS ESMERALDINAS');
      expect(v['ticketsHomeCrowdLabel'], 'TORCIDA DO GOIÁS');
    });

    testWidgets('en', (tester) async {
      final v = await _renderAll(tester, goiasClubConfig, en);
      expect(v['arenaAchievementTitle'], 'ESMERALDINA LEGEND');
      expect(v['newsSourceLabel'], 'SOURCE: GOIÁS ESPORTE CLUBE');
      expect(v['clubSongsSection'], 'ESMERALDINA SONGS');
      expect(v['ticketsHomeCrowdLabel'], 'GOIÁS SUPPORTERS');
    });

    testWidgets('es', (tester) async {
      final v = await _renderAll(tester, goiasClubConfig, es);
      expect(v['arenaAchievementTitle'], 'LEYENDA ESMERALDINA');
      expect(v['newsSourceLabel'], 'FUENTE: GOIÁS ESPORTE CLUBE');
      expect(v['clubSongsSection'], 'CANCIONES ESMERALDINAS');
      expect(v['ticketsHomeCrowdLabel'], 'HINCHADA DEL GOIÁS');
    });
  });

  group(
    'Bragantino nunca mostra termo do Goiás nessas 4 telas compartilhadas',
    () {
      for (final locale in [pt, en, es]) {
        testWidgets('locale ${locale.languageCode}', (tester) async {
          final v = await _renderAll(tester, bragantinoClubConfig, locale);
          for (final entry in v.entries) {
            for (final term in _goiasLeakTerms) {
              expect(
                entry.value.contains(term),
                isFalse,
                reason:
                    '${entry.key} (${locale.languageCode}) = "${entry.value}" '
                    'contém o termo do Goiás "$term"',
              );
            }
            // Prova que usou o nome REAL do Bragantino, não caiu num texto
            // genérico vazio por acidente.
            expect(entry.value.contains('BRAGANTINO'), isTrue);
          }
        });
      }
    },
  );

  test(
    'membershipFaqAssetPath: Goiás tem path real, Bragantino nunca herda o dele',
    () {
      expect(
        goiasClubConfig.assets.membershipFaqAssetPath,
        'lib/assets/content/membership_faq.json',
      );
      expect(bragantinoClubConfig.assets.membershipFaqAssetPath, isNull);
    },
  );

  test('auditoria automatizada de baixo custo — nenhum campo de branding '
      'reutilizável do Bragantino contém termo do Goiás', () {
    final riskyBragantinoStrings = [
      bragantinoClubConfig.identity.displayName,
      bragantinoClubConfig.identity.shortName,
      bragantinoClubConfig.identity.fanDemonym,
      bragantinoClubConfig.productNames.arenaName,
      bragantinoClubConfig.productNames.passportName,
      bragantinoClubConfig.productNames.storeName,
      bragantinoClubConfig.productNames.membershipProgramName,
      ...bragantinoClubConfig.assets.storeHomeBanners,
      ?bragantinoClubConfig.assets.membershipFaqAssetPath,
      ?bragantinoClubConfig.assets.storeCatalogAssetPath,
    ];
    for (final value in riskyBragantinoStrings) {
      for (final term in _goiasLeakTerms) {
        expect(
          value.contains(term),
          isFalse,
          reason: '"$value" contém o termo do Goiás "$term"',
        );
      }
    }
  });
}
