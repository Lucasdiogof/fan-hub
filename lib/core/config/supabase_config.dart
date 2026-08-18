class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yonozsdgyrhgqrvydbnr.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_G7wFeRd5jcKNI0oek24-5g_x3lDJV8t',
  );

  static const String redirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'https://goias-app.lucasdiogo1234.workers.dev',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
