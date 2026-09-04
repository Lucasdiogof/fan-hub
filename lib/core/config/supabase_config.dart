import 'package:goias_app/core/club/club_config.dart';

/// Projeto Supabase do build ATIVO — resolvido 1x em `main()` a partir do
/// [ClubConfig] do flavor (`resolveActiveClub()`), nunca de
/// `String.fromEnvironment`/`--dart-define` solto (isso dependia de quem
/// compila lembrar de passar a flag certa — a fonte de verdade agora é
/// código, determinística por clube, igual `workerBaseUrl`).
///
/// NUNCA cai pro projeto do Goiás quando o clube ativo não tem
/// `supabaseUrl`/`supabasePublishableKey` configurados — [configure] lança
/// [StateError] nesse caso, e nenhum getter aqui tem `defaultValue`.
class SupabaseConfig {
  const SupabaseConfig._();

  static String? _url;
  static String? _publishableKey;
  static String? _redirectUrl;
  static bool _configured = false;

  /// Chamado 1x em `main()`, antes de `Supabase.initialize` e antes de
  /// qualquer leitura de [url]/[publishableKey]/[redirectUrl].
  static void configure(ClubConfig club) {
    final integrations = club.integrations;
    if (integrations.supabaseUrl == null ||
        integrations.supabasePublishableKey == null) {
      throw StateError(
        'Supabase não configurado pro clube "${club.identity.code}" — '
        'supabaseUrl/supabasePublishableKey ausentes em '
        '${club.identity.code}_club_config.dart. Nunca cai pro projeto do '
        'Goiás como fallback: preencha os valores reais (URL + chave '
        'publishable/anon do dashboard Supabase, nunca senha de banco/'
        'service_role) antes de rodar este flavor.',
      );
    }
    _url = integrations.supabaseUrl;
    _publishableKey = integrations.supabasePublishableKey;
    _redirectUrl = integrations.supabaseRedirectUrl;
    _configured = true;
  }

  static String get url => _requireConfigured(_url, 'url');

  static String get publishableKey =>
      _requireConfigured(_publishableKey, 'publishableKey');

  /// Pode ser `null` mesmo configurado (clube sem Worker/rota de redirect
  /// ainda) — quem consome decide o que fazer com ausência, não é
  /// fail-loud como [url]/[publishableKey].
  static String? get redirectUrl {
    if (!_configured) {
      throw StateError(
        'SupabaseConfig.redirectUrl lido antes de SupabaseConfig.configure() '
        'rodar — configure() precisa ser chamado logo no início de main().',
      );
    }
    return _redirectUrl;
  }

  static bool get isConfigured =>
      _configured && _url != null && _publishableKey != null;

  static String _requireConfigured(String? value, String fieldName) {
    if (!_configured) {
      throw StateError(
        'SupabaseConfig.$fieldName lido antes de SupabaseConfig.configure() '
        'rodar — configure() precisa ser chamado logo no início de main().',
      );
    }
    // configure() já garante isto não-nulo pra url/publishableKey — chegar
    // aqui null seria um bug de configure(), nunca um estado válido.
    return value!;
  }
}
