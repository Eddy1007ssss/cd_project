import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'language_settings_page.dart';

class ProfileSecurityPage extends StatefulWidget {
  const ProfileSecurityPage({
    this.navigationRole = TourFlowNavigationRole.tourist,
    this.pageLevel = TourFlowPageLevel.topLevel,
    this.selectedNavigationIndex = 4,
    super.key,
  });

  static const routeName = TourFlowRoutes.profileSecurity;

  final TourFlowNavigationRole navigationRole;
  final TourFlowPageLevel pageLevel;
  final int selectedNavigationIndex;

  @override
  State<ProfileSecurityPage> createState() => _ProfileSecurityPageState();
}

class _ProfileSecurityPageState extends State<ProfileSecurityPage> {
  final AuthRepository _authRepository = AuthRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  UserProfile? _profile;
  String _email = '';
  String? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSendingReset = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final profile = await _authRepository.getCurrentProfile();
      final email = _authRepository.currentUser?.email ?? '';
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _email = email;
        _fullNameController.text = profile.fullName;
        _phoneController.text = profile.phone ?? '';
        _isLoading = false;
        _loadError = null;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load your profile. Please try again.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final profile = await _authRepository.updateMyProfile(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      _showMessage('Profile updated successfully.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } on PostgrestException catch (error) {
      if (mounted) _showMessage(error.message);
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to update your profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openLanguageSettings() async {
    final result = await Navigator.pushNamed(
      context,
      LanguageSettingsPage.routeName,
    );
    if (!mounted || result is! String) return;
    await _loadProfile(showLoader: false);
  }

  Future<void> _sendPasswordReset() async {
    if (_isSendingReset || _email.isEmpty) return;
    setState(() => _isSendingReset = true);

    try {
      await _authRepository.sendPasswordReset(_email);
      if (mounted) {
        _showMessage('Password reset link sent to $_email.');
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to send the reset link. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  Future<void> _showPasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? dialogError;
    bool isChanging = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            final currentPassword = currentPasswordController.text;
            final newPassword = newPasswordController.text;
            final confirmation = confirmPasswordController.text;

            String? validationError;
            if (currentPassword.isEmpty) {
              validationError = 'Enter your current password.';
            } else if (newPassword.length < 8) {
              validationError =
                  'The new password must contain at least 8 characters.';
            } else if (newPassword != confirmation) {
              validationError = 'The new passwords do not match.';
            } else if (newPassword == currentPassword) {
              validationError =
                  'The new password must be different from the current password.';
            }

            if (validationError != null) {
              setDialogState(() => dialogError = validationError);
              return;
            }

            setDialogState(() {
              isChanging = true;
              dialogError = null;
            });

            try {
              await _authRepository.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (mounted) _showMessage('Password updated successfully.');
            } on AuthException catch (error) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  isChanging = false;
                  dialogError = error.message;
                });
              }
            } catch (_) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  isChanging = false;
                  dialogError =
                      'Unable to change the password. Please try again.';
                });
              }
            }
          }

          return AlertDialog(
            title: const TourFlowText('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    enabled: !isChanging,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: context.tr('Current password'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    enabled: !isChanging,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: context.tr('New password'),
                      helperText: context.tr('Use at least 8 characters.'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    enabled: !isChanging,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) {
                      if (!isChanging) submit();
                    },
                    decoration: InputDecoration(
                      labelText: context.tr('Confirm new password'),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TourFlowText(
                        dialogError!,
                        style: const TextStyle(
                          color: TourFlowColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isChanging
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const TourFlowText('Cancel'),
              ),
              FilledButton(
                onPressed: isChanging ? null : submit,
                child: isChanging
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const TourFlowText('Update Password'),
              ),
            ],
          );
        },
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: TourFlowText(message)));
  }

  String get _roleLabel {
    final role = _profile?.role.name ?? widget.navigationRole.name;
    return 'TOURFLOW · ${role.toUpperCase()}';
  }

  String _languageLabel(String code) => switch (code.toLowerCase()) {
    'ms' || 'bm' => 'Bahasa Malaysia',
    'zh' || 'zh-cn' => 'Mandarin (简体中文)',
    'ja' => 'Japanese (日本語)',
    'ko' => 'Korean (한국어)',
    _ => 'English',
  };

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }
    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final displayName = profile?.fullName ?? 'Tourist';

    return TourFlowPage(
      title: 'Profile and Security',
      role: _roleLabel,
      navigationRole: widget.navigationRole,
      pageLevel: widget.pageLevel,
      selectedNavigationIndex: widget.selectedNavigationIndex,
      displayName: displayName,
      email: _email,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          : _loadError != null
          ? _ProfileLoadError(
              message: _loadError!,
              onRetry: () => _loadProfile(),
            )
          : _buildProfile(profile!),
    );
  }

  Widget _buildProfile(UserProfile profile) {
    final avatarUrl = profile.avatarUrl?.trim();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          ModuleCard(
            color: TourFlowColors.lavender,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: TourFlowColors.primary,
                  backgroundImage:
                      avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? TourFlowText(
                          _initials(profile.fullName),
                          style: const TextStyle(
                            color: TourFlowColors.primaryText,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TourFlowText(
                        profile.fullName,
                        style: const TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      TourFlowText(
                        _email,
                        style: const TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: profile.status.name.toUpperCase(),
                  color: profile.isActive
                      ? TourFlowColors.success
                      : TourFlowColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Personal Details',
                  subtitle:
                      'Your information is loaded from your TourFlow account.',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: context.tr('Full Name'),
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.length < 2) {
                      return 'Enter at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                StaticField(
                  label: 'Email Address',
                  value: _email,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: context.tr('Phone Number'),
                    hintText: context.tr('+60 12-345 6789'),
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isNotEmpty &&
                        !RegExp(r'^[0-9+()\-\s]{7,30}$').hasMatch(phone)) {
                      return 'Enter a valid phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                StaticField(
                  label: 'Preferred Language',
                  value: _languageLabel(profile.preferredLanguage),
                  icon: Icons.language_outlined,
                  trailing:
                      widget.navigationRole == TourFlowNavigationRole.tourist
                      ? IconButton(
                          tooltip: context.tr('Change language'),
                          onPressed: _openLanguageSettings,
                          icon: const Icon(Icons.chevron_right_rounded),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                StaticField(
                  label: 'Account Role',
                  value: profile.role.name.toUpperCase(),
                  icon: Icons.badge_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: TourFlowText(_isSaving ? 'Saving...' : 'Save Profile Changes'),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.navigationRole == TourFlowNavigationRole.tourist) ...[
            ModuleCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.rate_review_outlined),
                title: const TourFlowText('Feedback Centre'),
                subtitle: const TourFlowText('Ratings, feedback and issue reports'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(context, '/feedback-centre'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Security'),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.key_rounded),
                  title: const TourFlowText('Change Password'),
                  subtitle: const TourFlowText(
                    'Verify your current password before choosing a new one',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showPasswordDialog,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mark_email_read_outlined),
                  title: const TourFlowText('Reset Password Link'),
                  subtitle: TourFlowText(
                    _isSendingReset
                        ? 'Sending recovery email...'
                        : 'Send a recovery link to $_email',
                  ),
                  trailing: _isSendingReset
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _isSendingReset ? null : _sendPasswordReset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Column(
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 42,
            color: TourFlowColors.danger,
          ),
          const SizedBox(height: 12),
          TourFlowText(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const TourFlowText('Try Again'),
          ),
        ],
      ),
    );
  }
}
