// Flavor Vila Nova (F1–F3). Trava que nome/escudo/cores/ícones/integrações e
// o conteúdo institucional do Vila nunca coincidem com os do Goiás (rival
// local) nem com os do Bragantino, e que só as capabilities já validadas
// estão ligadas.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/club/data/vilanova_history_data.dart';
import 'package:goias_app/features/club/data/vilanova_idols_data.dart';
import 'package:goias_app/features/club/data/vilanova_timeline_data.dart';
import 'package:goias_app/features/club/data/vilanova_titles_data.dart';
import 'package:goias_app/features/partners/data/vilanova_partners_data.dart';
import 'package:goias_app/features/partners/domain/entities/partner.dart';
import 'package:goias_app/features/ticket/data/vilanova_ticket_content.dart';
import 'package:goias_app/features/ticket/domain/gate_label.dart';

void main() {
  final others = <String, ClubConfig>{
    'goias': goiasClubConfig,
    'bragantino': bragantinoClubConfig,
  };
  final v = vilaNovaClubConfig;

  group('Identidade — Vila Nova nunca coincide com outro clube', () {
    for (final entry in others.entries) {
      test('code/slug/nomes/torcida/clubId distintos de ${entry.key}', () {
        final o = entry.value.identity;
        expect(v.identity.code, isNot(o.code));
        expect(v.identity.slug, isNot(o.slug));
        expect(v.identity.displayName, isNot(o.displayName));
        expect(v.identity.shortName, isNot(o.shortName));
        expect(v.identity.fanDemonym, isNot(o.fanDemonym));
        expect(v.identity.canonicalClubId, isNot(o.canonicalClubId));
      });

      test('paleta (light/dark) distinta de ${entry.key}', () {
        expect(
          v.branding.light.primary,
          isNot(entry.value.branding.light.primary),
        );
        expect(
          v.branding.dark.primary,
          isNot(entry.value.branding.dark.primary),
        );
      });

      test(
        'integrações (OneFootball/prefixo de pedido) distintas de ${entry.key}',
        () {
          final o = entry.value.integrations;
          expect(v.integrations.oneFootballTeamId, isNot(o.oneFootballTeamId));
          expect(v.integrations.oneFootballSlug, isNot(o.oneFootballSlug));
          expect(v.integrations.orderPrefix, isNot(o.orderPrefix));
        },
      );
    }

    test('textos do Vila nunca carregam identidade do Goiás/Bragantino', () {
      final texts = [
        v.identity.displayName,
        v.identity.shortName,
        v.identity.fanDemonym,
        v.productNames.arenaName,
        v.productNames.passportName,
        v.productNames.storeName,
        v.productNames.membershipProgramName,
        v.passportContent.pt.title,
        v.passportContent.pt.shareText,
        v.passportContent.pt.levels.legend,
      ];
      for (final text in texts) {
        for (final leaked in [
          'Goiás',
          'Esmeraldin',
          'Verdão',
          'Serrinha',
          'Bragantino',
          'Massa Bruta',
          'Red Bull',
        ]) {
          expect(
            text.toLowerCase(),
            isNot(contains(leaked.toLowerCase())),
            reason: '"$text" contém identidade de outro clube ("$leaked")',
          );
        }
      }
    });

    test(
      '2026-09-30 (feedback do usuário): dourado = acerto/sucesso, nunca verde; '
      'erro é um vermelho vívido, distinguível do vermelho de marca',
      () {
        bool isGreenish(double r, double g, double b) => g > r && g > b;
        for (final palette in [v.branding.light, v.branding.dark]) {
          final success = palette.success;
          expect(
            isGreenish(success.r, success.g, success.b),
            isFalse,
            reason: 'success não pode ser esverdeado: $success',
          );
          expect(
            success,
            palette.gold,
            reason: 'success deve ser o mesmo tom de gold (acerto = dourado)',
          );
        }
      },
    );

    test('todo asset do Vila mora na pasta do Vila e existe no disco', () {
      final a = v.assets;
      for (final path in [
        a.crest,
        a.crestBadge,
        a.crest3d,
        a.loginBackground,
        a.tacticsBoardIllustration,
        a.arenaStadiumIcon,
        a.arenaStadiumPhoto,
        a.storeBanner,
      ]) {
        expect(path, startsWith('lib/assets/branding/vilanova/'));
        expect(File(path).existsSync(), isTrue, reason: 'asset ausente: $path');
      }
    });
  });

  group('Capabilities — só o que já foi validado está ligado', () {
    test(
      'F3/F4/F6/F7/F8 ligaram hasClubContent/hasPassport/hasMembership/hasMatches; o resto segue desligado',
      () {
        final c = v.capabilities;
        expect(c.hasClubContent, isTrue);
        expect(c.hasPassport, isTrue);
        // F7 (2026-09-30): 4 planos reais do Sócio Tigrão, fonte = API
        // pública do provedor de adesão — ver
        // `vilanova_membership_plans_catalog.dart`.
        expect(c.hasMembership, isTrue);
        // F8 (2026-09-30): Worker próprio no ar — jogos e aba Mídia.
        expect(c.hasMatches, isTrue);
        expect(c.hasNews, isTrue);
        expect(c.hasSocial, isTrue);
        // 2026-09-30: ingressos (notícias oficiais de venda) e parceiros
        // (faixa de patrocinadores do site oficial).
        expect(c.hasTickets, isTrue);
        expect(c.hasPartners, isTrue);
        expect([c.hasStore, c.hasCrowdLineup], everyElement(isFalse));
      },
    );

    test(
      'F5/F7-fotos: os 6 jogos da Arena ligados (guess_player desde 2026-09-30, ASSET_GAP resolvido)',
      () {
        expect(v.capabilities.enabledArenaGames, {
          'quiz',
          'lineup',
          'player_identity',
          'tactical_identity',
          'career_path',
          'guess_player',
        });
      },
    );

    test(
      'guessPlayerPhotos do Vila: 31 fotos do elenco atual, todas do CDN oficial dele',
      () {
        final photos = v.assets.guessPlayerPhotos;
        expect(photos, hasLength(31));
        for (final url in photos.values) {
          expect(url, startsWith('https://www.vilanovafc.com.br/'));
        }
      },
    );

    test(
      'Supabase do próprio Vila (projeto vkybbrfvmexevakknlsi) — nunca aponta pro de outro clube',
      () {
        expect(
          v.integrations.supabaseUrl,
          'https://vkybbrfvmexevakknlsi.supabase.co',
        );
        expect(v.integrations.supabasePublishableKey, isNotNull);
        expect(
          v.integrations.supabaseUrl,
          isNot(goiasClubConfig.integrations.supabaseUrl),
        );
        expect(
          v.integrations.supabaseUrl,
          isNot(bragantinoClubConfig.integrations.supabaseUrl),
        );
      },
    );

    test('Worker/redirect do próprio Vila — nunca o de outro clube', () {
      const url = 'https://vilanova-app.lucasdiogo1234.workers.dev';
      expect(v.integrations.workerBaseUrl, url);
      expect(v.integrations.supabaseRedirectUrl, url);
      expect(
        v.integrations.workerBaseUrl,
        isNot(goiasClubConfig.integrations.workerBaseUrl),
      );
      expect(
        v.integrations.workerBaseUrl,
        isNot(bragantinoClubConfig.integrations.workerBaseUrl),
      );
    });
  });

  group(
    'Ícones e Firebase — Vila Nova nunca reaproveita os de outro clube',
    () {
      const densities = [
        'mipmap-hdpi',
        'mipmap-mdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];
      for (final density in densities) {
        test('ic_launcher ($density) distinto do Goiás e do Bragantino', () {
          final vila = File(
            'android/app/src/vilanova/res/$density/ic_launcher.png',
          ).readAsBytesSync();
          for (final other in ['main', 'bragantino']) {
            final otherIcon = File(
              'android/app/src/$other/res/$density/ic_launcher.png',
            ).readAsBytesSync();
            expect(vila, isNot(equals(otherIcon)), reason: '$other/$density');
          }
        });
      }

      test(
        'google-services.json do flavor tem o client br.com.fanhub.vilanova',
        () {
          final json = File(
            'android/app/src/vilanova/google-services.json',
          ).readAsStringSync();
          expect(json, contains('"package_name": "br.com.fanhub.vilanova"'));
          expect(json, contains('"project_id": "fan-hub-29e9b"'));
        },
      );

      test('plist iOS do flavor é do bundle br.com.fanhub.vilanova', () {
        final plist = File(
          'ios/Runner/Firebase/vilanova/GoogleService-Info.plist',
        ).readAsStringSync();
        expect(plist, contains('<string>br.com.fanhub.vilanova</string>'));
      });
    },
  );

  group('F3 — conteúdo institucional do Vila', () {
    final content = v.institutionalContent;

    test('aponta pras classes estáticas do próprio Vila', () {
      expect(content.history, same(VilaNovaHistoryData.sections));
      expect(content.timeline, same(VilaNovaTimelineData.events));
      expect(content.titles, same(VilaNovaTitlesData.groups));
      expect(
        content.historicalCampaigns,
        same(VilaNovaTitlesData.historicalCampaigns),
      );
      expect(content.idols, same(VilaNovaIdolsData.idols));
    });

    test(
      'parceiros = lista do site oficial; músicas vazias (só metadados)',
      () {
        expect(content.partners, same(VilaNovaPartnersData.all));
        expect(content.songs, isEmpty);
      },
    );

    test('16 Goianos e 3 Séries C, como no site oficial', () {
      int count(String name) =>
          content.titles.firstWhere((g) => g.competitionName == name).count;
      expect(count('Campeonato Goiano'), 16);
      expect(count('Campeonato Brasileiro Série C'), 3);
    });

    test('vice nunca é título: Copa Verde só em historicalCampaigns', () {
      expect(
        content.titles.map((g) => g.competitionName),
        isNot(contains(contains('Copa Verde'))),
      );
      expect(content.historicalCampaigns.map((c) => c.year), [
        2021,
        2022,
        2024,
      ]);
    });

    test('Túlio (números em conflito) nunca é publicado', () {
      expect(
        content.publishedIdols.map((i) => i.name),
        isNot(contains('Túlio Maravilha')),
      );
      expect(content.publishedIdols, hasLength(9));
    });

    test('nenhum texto institucional carrega identidade de outro clube nem '
        'nota interna de pesquisa', () {
      final texts = [
        for (final s in content.history) ...[s.title, ...s.paragraphs],
        for (final e in content.timeline) ...[e.title, e.description ?? ''],
        for (final i in content.publishedIdols) i.description,
      ];
      for (final text in texts) {
        for (final leaked in [
          'Esmeraldin',
          'Verdão',
          'Serrinha',
          'Bragantino',
          'Massa Bruta',
          'acervo',
          'snapshot',
          'lote',
          'REVIEW',
          'listad',
        ]) {
          expect(
            text.toLowerCase(),
            isNot(contains(leaked.toLowerCase())),
            reason: '"$text" contém "$leaked"',
          );
        }
      }
    });

    test('linha do tempo em ordem cronológica e sempre com fonte', () {
      final years = content.timeline.map((e) => e.year).toList();
      expect(years, [...years]..sort());
      for (final e in content.timeline) {
        expect(e.sourceUrl, startsWith('https://'), reason: e.title);
      }
    });
  });

  group('Ingressos do Vila (notícias oficiais de venda)', () {
    final t = v.ticketsContent!;

    test('é o conteúdo do Vila, com os 4 setores do OBA', () {
      expect(t, same(VilaNovaTicketContent.content));
      expect(t.sectors.map((s) => s.name), [
        'Setor A',
        'Setor B',
        'Camarote',
        'Setor C',
      ]);
    });

    test('preços das notícias: A 120/60, B 60/30, Camarote 120, C 120/60', () {
      Map<String, double> prices(String name) => {
        for (final c in t.sectors.firstWhere((s) => s.name == name).categories)
          c.id: c.price,
      };
      expect(prices('Setor A'), {'inteira': 120, 'meia': 60});
      expect(prices('Setor B'), {'inteira': 60, 'meia': 30});
      expect(prices('Camarote'), {'inteira': 120});
      expect(prices('Setor C'), {'inteira': 120, 'meia': 60});
    });

    test('portão nunca inventado: vazio, e o rótulo sai sem " · "', () {
      for (final s in t.sectors) {
        expect(s.gate, isEmpty, reason: s.name);
        expect(withGate(s.name, s.gate), s.name);
      }
      expect(withGate('Cadeiras', 'Portão 6'), 'Cadeiras · Portão 6');
    });

    test('check-in do sócio só nos Setores A e B; C é o visitante', () {
      expect(t.sectors.where((s) => s.availableForCheckIn).map((s) => s.name), [
        'Setor A',
        'Setor B',
      ]);
      expect(t.sectors.where((s) => s.isVisitorSector).map((s) => s.name), [
        'Setor C',
      ]);
    });

    test('nenhum texto de ingresso do Goiás/Bragantino', () {
      final texts = [
        for (final s in t.sectors) ...[s.name, s.venueLabel],
        for (final sec in t.salesInfoSections) ...[sec.title, ...sec.items],
      ];
      for (final text in texts) {
        for (final leaked in [
          'Serra Dourada',
          'Serrinha',
          'Goiás E.C.',
          'São Bernardo',
          'Tobogã',
          'Esmeraldin',
          'Massa Bruta',
        ]) {
          expect(text, isNot(contains(leaked)), reason: text);
        }
      }
    });
  });

  group('Parceiros do Vila (site oficial)', () {
    const all = VilaNovaPartnersData.all;

    test('34 marcas, nomes únicos, logo local existente e claro', () {
      expect(all, hasLength(34));
      expect(all.map((p) => p.name).toSet(), hasLength(34));
      for (final p in all) {
        expect(p.lightLogo, isTrue, reason: p.name);
        expect(p.assetPath, startsWith('lib/assets/sponsors/vilanova/'));
        expect(File(p.assetPath!).existsSync(), isTrue, reason: p.name);
        expect(p.url, startsWith('http'), reason: p.name);
        expect(p.tier, isNull, reason: 'máster não confirmado: sem tier');
      }
    });

    test('categorias só onde há fonte (Volt material, Fatal Fans camisa)', () {
      final byCategory = {
        for (final p in all.where((p) => p.category != PartnerCategory.sponsor))
          p.name: p.category,
      };
      expect(byCategory, {
        'Volt': PartnerCategory.kitSupplier,
        'Fatal Fans': PartnerCategory.shirtSponsor,
      });
    });

    test('fora: V de Vantagens (domínio sem DNS, sem destino seguro)', () {
      expect(all.map((p) => p.name), isNot(contains('V de Vantagens')));
    });
  });
}
