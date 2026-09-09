import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';

class SidebarIdentity {
  const SidebarIdentity(this.name, this.email, this.avatarUrl);
  final String name;
  final String email;
  final String? avatarUrl;

  factory SidebarIdentity.resolve(UserProfile? profile, String? userId, String? email) {
    if (userId == null) return const SidebarIdentity('Guest', '', null);
    // A profile cached for a previous account must never appear for this user.
    final current = profile?.id == userId ? profile : null;
    return SidebarIdentity(current?.fullName ?? 'Signed-in user', email ?? '', current?.avatarUrl);
  }
}

/// Shared by every tourist/operator/staff/admin drawer.
class SignedInIdentity extends StatefulWidget {
  const SignedInIdentity({super.key, required this.builder});
  final Widget Function(SidebarIdentity) builder;
  @override
  State<SignedInIdentity> createState() => _SignedInIdentityState();
}

class _SignedInIdentityState extends State<SignedInIdentity> {
  AuthRepository? _repository;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    // Widget-only previews/tests need not initialize Supabase.
    try {
      final repository = AuthRepository();
      _repository = repository;
      repository.profileChanges.addListener(_changed);
      _subscription = repository.authStateChanges.listen((_) {
        _changed();
        unawaited(_refresh());
      });
      unawaited(_refresh());
    } catch (_) { /* An uninitialized preview renders Guest. */ }
  }

  Future<void> _refresh() async {
    final repository = _repository;
    if (repository == null || repository.currentUser == null) return;
    try { await repository.getCurrentProfile(); } catch (_) {
      // Keep the current account's email visible if the profile request fails.
    }
    _changed();
  }

  void _changed() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository?.profileChanges.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(SidebarIdentity.resolve(
    _repository?.cachedProfile, _repository?.currentUser?.id, _repository?.currentUser?.email));
}
