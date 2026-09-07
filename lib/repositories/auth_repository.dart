import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/tourflow_localization.dart';
import '../models/user_profile.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static final ValueNotifier<UserProfile?> _profileNotifier =
      ValueNotifier<UserProfile?>(null);

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  UserProfile? get cachedProfile => _profileNotifier.value;
  ValueListenable<UserProfile?> get profileChanges => _profileNotifier;

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
    final profile = UserProfile.fromMap(data);
    _profileNotifier.value = profile;
    TourFlowLocaleController.instance.useLanguageCode(
      profile.preferredLanguage,
    );
    return profile;
  }

  Future<UserProfile> getCurrentProfile() {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to view your profile.');
    }
    return getProfile(user.id);
  }

  Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to update your profile.');
    }

    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();
    if (normalizedName.length < 2) {
      throw const FormatException(
        'Full name must contain at least 2 characters.',
      );
    }

    await _client.rpc(
      'update_my_profile',
      params: {
        'p_full_name': normalizedName,
        'p_phone': normalizedPhone.isEmpty ? null : normalizedPhone,
      },
    );

    return getProfile(user.id);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AuthException(
        'Please sign in again to change your password.',
      );
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  Future<void> signOut() async {
    await _client.auth.signOut();
    _profileNotifier.value = null;
  }
}
