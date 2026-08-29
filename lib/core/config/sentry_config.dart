class SentryConfig {
  const SentryConfig._();

  /// Um DSN do Sentry não é segredo — ele só permite ENVIAR eventos pro
  /// projeto, nunca ler dado nenhum (mesma lógica de já commitar a chave
  /// publicável do Supabase direto no código). Mesmo padrão de
  /// `SupabaseConfig`: dá pra sobrescrever via `--dart-define` sem
  /// precisar mexer aqui.
  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://468d490443602c3d9d08c740111e1cef@o4511991962927104.ingest.us.sentry.io/4511991967645696',
  );

  static bool get isConfigured => dsn.isNotEmpty;
}
