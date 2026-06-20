/// Environment configuration loaded from compile-time defines.
///
/// All values must be provided via `--dart-define` when building/running.
/// Use [validate] at startup to ensure none are missing.
class EnvConfig {
  EnvConfig._();

  /// Supabase project URL (e.g. https://xxxxx.supabase.co)
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase publishable (anon) key
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// OAuth redirect scheme (e.g. io.supabase.api-tester)
  /// The full redirect URI will be: <scheme>://login-callback/
  static const String oauthRedirectScheme =
      String.fromEnvironment('OAUTH_REDIRECT_SCHEME');

  /// Validates that all required environment variables are set.
  /// Throws an [EnvironmentError] with a clear message listing all missing
  /// variables if any are absent.
  static void validate() {
    final missing = <String>[];

    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (oauthRedirectScheme.isEmpty) missing.add('OAUTH_REDIRECT_SCHEME');

    if (missing.isNotEmpty) {
      throw EnvironmentError(
        'Missing required environment variables:\n'
        '  ${missing.join('\n  ')}\n\n'
        'All variables must be provided via --dart-define flags.\n'
        'Example:\n'
        '  flutter run \\\n'
        "    --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \\\n"
        "    --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx \\\n"
        "    --dart-define=OAUTH_REDIRECT_SCHEME=io.supabase.api-tester\n\n"
        'See README.md for details.',
      );
    }
  }
}

/// Thrown when required environment variables are missing.
class EnvironmentError extends Error {
  final String message;

  EnvironmentError(this.message);

  @override
  String toString() => 'EnvironmentError: $message';
}
