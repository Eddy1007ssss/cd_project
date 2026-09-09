import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/tourflow_localization.dart';
import '../models/user_profile.dart';
import 'profile_security_gateway.dart';

class AuthRepository implements ProfileSecurityGateway {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static final ValueNotifier<UserProfile?> _profileNotifier =
      ValueNotifier<UserProfile?>(null);

  Session? get currentSession => _client.auth.currentSession;
  @override
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
    if (user.emailConfirmedAt == null) {
      await _client.auth.signOut();
      throw const AuthException(
        'Confirm your email address before signing in. You can resend the verification email below.',
      );
    }
    return getProfile(user.id);
  }

  Future<void> signUpTourist({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String preferredLanguage,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'tourflow://auth/confirm',
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
  }

  Future<UserProfile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    final profile = UserProfile.fromMap(data);
    // A slow profile request may finish after logout or an account switch.
    if (currentUser?.id == userId) {
      _profileNotifier.value = profile;
      TourFlowLocaleController.instance.useLanguageCode(profile.preferredLanguage);
    }
    return profile;
  }

  @override
  Future<UserProfile> getCurrentProfile() {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to view your profile.');
    }
    return getProfile(user.id);
  }

  @override
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

  @override
  Future<UserProfile> updateMyAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to change your profile photo.');
    }

    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choose an image smaller than 5 MB.');
    }

    final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

    if (!allowedExtensions.contains(normalizedExtension)) {
      throw const FormatException('Choose a JPG, PNG or WEBP image.');
    }

    final contentType = switch (normalizedExtension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'image/webp',
    };

    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    final storage = _client.storage.from('profile-avatars');

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );

    final avatarUrl = storage.getPublicUrl(path);

    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', user.id);

    return getProfile(user.id);
  }

  @override
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

  @override
  Future<void> sendPasswordReset(String email) => _client.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );

  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: code.trim(),
    );
    if (response.session == null) {
      throw const AuthException('That verification code is invalid or expired.');
    }
  }

  Future<void> resendEmailVerification(String email) => _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: 'tourflow://auth/confirm',
      );

  Future<void> completePasswordRecovery(String newPassword) async {
    if (newPassword.length < 8) {
      throw const FormatException(
        'The new password must contain at least 8 characters.',
      );
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _profileNotifier.value = null;
  }
}
