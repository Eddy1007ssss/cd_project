import 'package:flutter/material.dart';

import '../../l10n/tourflow_localization.dart';
import '../../repositories/auth_repository.dart';
import '../../services/gemini_chat_service.dart';
import '../../widgets/tourflow_widgets.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  static const routeName = '/user/language-settings';

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  final GeminiChatService _chatService = GeminiChatService();

  String _selectedLanguage = 'en';
  String _displayName = 'Tourist';
  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  static const _languages = [
    ('en', 'English', 'English', 'EN'),
    ('ms', 'Bahasa Malaysia', 'Bahasa Malaysia', 'BM'),
    ('zh', 'Mandarin', '简体中文', '中文'),
    ('ja', 'Japanese', '日本語', '日'),
    ('ko', 'Korean', '한국어', '한'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = TourFlowLocaleController.instance.languageCode;
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final userContext = await _chatService.getCurrentUserContext();
      if (!mounted) return;
      setState(() {
        _selectedLanguage = TourFlowLocaleController.normalizeLanguageCode(
          userContext.languageCode,
        );
        _displayName = userContext.displayName;
        _email = userContext.email;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TourFlowText(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _saveLanguage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await TourFlowLocaleController.instance.saveLanguageCode(
        _selectedLanguage,
      );
      await AuthRepository().getCurrentProfile();
      if (!mounted) return;
      Navigator.pop(
        context,
        TourFlowLocaleController.instance.languageName,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TourFlowText(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Language Settings',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: _displayName,
      email: _email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Preferred app language',
            subtitle:
            'Navigation, pages, system messages and the chatbot will use the same language.',
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            ModuleCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  if (!_isSaving && value != null) {
                    setState(() => _selectedLanguage = value);
                  }
                },
                child: Column(
                  children: _languages.map((language) {
                    final selected = _selectedLanguage == language.$1;
                    return RadioListTile<String>(
                      value: language.$1,
                      secondary: CircleAvatar(
                        backgroundColor: selected
                            ? TourFlowColors.primary
                            : TourFlowColors.lavender,
                        foregroundColor: selected
                            ? TourFlowColors.primaryText
                            : TourFlowColors.muted,
                        child: TourFlowText(
                          language.$4,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        language.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(language.$3),
                      activeColor: TourFlowColors.primaryText,
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: TourFlowColors.primaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TourFlowText(
                    context.tr(
                      'The selected language applies to the whole TourFlow app, including navigation, pages, system messages and the chatbot. Attraction names, addresses, booking codes and user-written content remain unchanged.',
                    ),
                    style: const TextStyle(
                      color: TourFlowColors.body,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading || _isSaving ? null : _saveLanguage,
              style: FilledButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.check_rounded),
              label: TourFlowText(
                context.tr(_isSaving ? 'Saving...' : 'Save Language'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
