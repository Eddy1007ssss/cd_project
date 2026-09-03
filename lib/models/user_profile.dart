enum UserRole { tourist, operator, staff, administrator }

enum AccountStatus { active, deactivated }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.preferredLanguage,
    required this.role,
    required this.status,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String preferredLanguage;
  final UserRole role;
  final AccountStatus status;
  final String? avatarUrl;

  bool get isActive => status == AccountStatus.active;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    fullName: map['full_name'] as String,
    phone: map['phone'] as String?,
    preferredLanguage: map['preferred_language'] as String? ?? 'en',
    role: UserRole.values.byName(map['role'] as String),
    status: AccountStatus.values.byName(map['status'] as String),
    avatarUrl: map['avatar_url'] as String?,
  );
}
