import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/env_config.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _redirectUri => '${EnvConfig.oauthRedirectScheme}://login-callback/';

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUri,
    );
  }

  Future<bool> signInWithGitHub() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: _redirectUri,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
