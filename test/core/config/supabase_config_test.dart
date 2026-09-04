import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/config/supabase_config.dart';

/// Mesmo [bragantinoClubConfig], mas sem config de Supabase — só pra provar
/// que `SupabaseConfig.configure` falha loud quando falta, sem depender de
/// mutar a constante real.
ClubConfig _bragantinoWithoutSupabase() => ClubConfig(
  identity: bragantinoClubConfig.identity,
  branding: bragantinoClubConfig.branding,
  assets: bragantinoClubConfig.assets,
  capabilities: bragantinoClubConfig.capabilities,
  productNames: bragantinoClubConfig.productNames,
  integrations: ClubIntegrations(
    oneFootballTeamId: bragantinoClubConfig.integrations.oneFootballTeamId,
    oneFootballSlug: bragantinoClubConfig.integrations.oneFootballSlug,
    oneFootballCompetitionSlug: bragantinoClubConfig.integrations.oneFootballCompetitionSlug,
    orderPrefix: bragantinoClubConfig.integrations.orderPrefix,
    pickupAddress: bragantinoClubConfig.integrations.pickupAddress,
    supabaseUrl: null,
    supabasePublishableKey: null,
  ),
);

void main() {
  group('SupabaseConfig.configure — por clube, fail-loud, zero fallback pro Goiás', () {
    test('configure(goiasClubConfig) resolve pro projeto real do Goiás', () {
      SupabaseConfig.configure(goiasClubConfig);
      expect(SupabaseConfig.url, 'https://yonozsdgyrhgqrvydbnr.supabase.co');
      expect(SupabaseConfig.publishableKey, isNotEmpty);
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test('configure(bragantinoClubConfig) resolve pro projeto REAL do Bragantino, nunca pro do Goiás', () {
      SupabaseConfig.configure(bragantinoClubConfig);
      expect(SupabaseConfig.url, 'https://yrgyzkaaudyzmsqwzecj.supabase.co');
      expect(SupabaseConfig.url, isNot(contains('yonozsdgyrhgqrvydbnr')));
      expect(SupabaseConfig.publishableKey, 'sb_publishable_pa2JzbHgClEqRBAajsPjig_uvL5Ntcc');
      expect(SupabaseConfig.publishableKey, isNot(goiasClubConfig.integrations.supabasePublishableKey));
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test('a chave publishable do Bragantino nunca é a legacy anon key nem um segredo de servidor (formato sb_publishable_, nunca eyJ.../sb_secret_)', () {
      final key = bragantinoClubConfig.integrations.supabasePublishableKey!;
      expect(key, startsWith('sb_publishable_'));
      expect(key, isNot(startsWith('eyJ')));
      expect(key.toLowerCase(), isNot(contains('service_role')));
      expect(key.toLowerCase(), isNot(contains('secret')));
    });

    test('redirectUrl do Bragantino é null (sem Worker próprio ainda) — nunca herda o do Goiás', () {
      SupabaseConfig.configure(bragantinoClubConfig);
      expect(SupabaseConfig.redirectUrl, isNull);
      SupabaseConfig.configure(goiasClubConfig);
      expect(SupabaseConfig.redirectUrl, isNotNull);
    });

    test('FABRICADO — um clube sem supabaseUrl/supabasePublishableKey faz configure() lançar StateError', () {
      expect(
        () => SupabaseConfig.configure(_bragantinoWithoutSupabase()),
        throwsStateError,
      );
    });
  });
}
