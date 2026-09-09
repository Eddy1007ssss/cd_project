import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

abstract interface class ProfileSecurityGateway {
  User? get currentUser;

  Future<UserProfile> getCurrentProfile();

  Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phone,
  });

  Future<UserProfile> updateMyAvatar({
    required Uint8List bytes,
    required String extension,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> sendPasswordReset(String email);
}
