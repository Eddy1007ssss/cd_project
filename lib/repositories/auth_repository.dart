import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in did not return a user.');
    }
    return getProfile(user.id);
  }

  Future<UserProfile> signUpTourist({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String preferredLanguage,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'preferred_language': preferredLanguage,
      },
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up did not return a user.');
    }
    return getProfile(user.id);
  }

  Future<UserProfile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromMap(data);
  }

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  Future<void> signOut() => _client.auth.signOut();
}
