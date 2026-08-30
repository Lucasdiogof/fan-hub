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

  /// Mesmo padrão do `dsn` acima — sobrescrevível via `--dart-define` sem
  /// mexer no código. Sem flavor/build separado pra QA hoje, todo build
  /// nasce "production" a menos que alguém explicitamente rode com
  /// `--dart-define=SENTRY_ENVIRONMENT=qa` (ex.: build de teste manual).
  static const String environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'production',
  );

  static bool get isConfigured => dsn.isNotEmpty;
}
