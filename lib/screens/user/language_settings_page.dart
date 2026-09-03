import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  static const routeName = '/user/language-settings';

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String _selectedLanguage = 'English';

  static const _languages = [
    ('English', 'English', 'EN'),
    ('Bahasa Malaysia', 'Bahasa Malaysia', 'BM'),
    ('Mandarin', '简体中文', '中文'),
    ('Japanese', '日本語', '日'),
    ('Korean', '한국어', '한'),
  ];

  void _saveLanguage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Preferred language changed to $_selectedLanguage.'),
        ),
      );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Language Settings',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: 'Alex Tan',
      email: 'alex@example.com',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Preferred chatbot language',
            subtitle:
                'TourFlow will automatically translate chatbot responses into your selected language.',
          ),
          const SizedBox(height: 16),
          ModuleCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _languages.map((language) {
                final selected = _selectedLanguage == language.$1;
                return RadioListTile<String>(
                  value: language.$1,
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                    }
                  },
                  secondary: CircleAvatar(
                    backgroundColor: selected
                        ? TourFlowColors.primary
                        : TourFlowColors.lavender,
                    foregroundColor: selected
                        ? TourFlowColors.primaryText
                        : TourFlowColors.muted,
                    child: Text(
                      language.$3,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    language.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(language.$2),
                  activeColor: TourFlowColors.primaryText,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: TourFlowColors.primaryText,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Attraction names, addresses and registration codes will remain unchanged to prevent confusion.',
                    style: TextStyle(
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
              onPressed: _saveLanguage,
              style: FilledButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Language'),
            ),
          ),
        ],
      ),
    );
  }
}
