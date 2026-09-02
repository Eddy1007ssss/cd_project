import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'support_ticket_list_page.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  static const routeName = '/user/chat-history';

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  String _query = '';

  static const _conversations = [
    _Conversation(
      title: 'National Museum opening hours',
      preview: 'The museum is open from 9:00 AM to 5:00 PM...',
      date: 'Today, 10:24 AM',
      language: 'English',
      icon: Icons.account_balance_outlined,
    ),
    _Conversation(
      title: 'Low-crowd attractions near me',
      preview: 'Lumina Botanical Gardens currently has a Low crowd level...',
      date: '30 Aug, 4:18 PM',
      language: 'Bahasa Malaysia',
      icon: Icons.groups_outlined,
    ),
    _Conversation(
      title: 'Transport to Old Town Square',
      preview: 'Take the MRT and exit at Pasar Seni Gate A...',
      date: '27 Aug, 11:03 AM',
      language: 'Mandarin',
      icon: Icons.directions_transit_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _conversations
        .where(
          (item) =>
              item.title.toLowerCase().contains(_query.toLowerCase()) ||
              item.preview.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return TourFlowPage(
      title: 'Chat History',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: 'Alex Tan',
      email: 'alex@example.com',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search previous conversations',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TourFlowColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TourFlowColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  'Previous conversations',
                  subtitle: 'Continue an earlier conversation with TourFlow.',
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  SupportTicketListPage.routeName,
                ),
                icon: const Icon(Icons.support_agent_outlined, size: 18),
                label: const Text('Tickets'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 44,
                      color: TourFlowColors.muted,
                    ),
                    SizedBox(height: 10),
                    Text('No matching conversations found.'),
                  ],
                ),
              ),
            )
          else
            ...visible.map(
              (conversation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ModuleCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/user/chat',
                      (route) => false,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: TourFlowColors.lavender,
                            foregroundColor: TourFlowColors.primaryText,
                            child: Icon(conversation.icon),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conversation.title,
                                  style: const TextStyle(
                                    color: TourFlowColors.heading,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  conversation.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: TourFlowColors.muted,
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    Text(
                                      conversation.date,
                                      style: const TextStyle(
                                        color: TourFlowColors.muted,
                                        fontSize: 9,
                                      ),
                                    ),
                                    Text(
                                      conversation.language,
                                      style: const TextStyle(
                                        color: TourFlowColors.primaryText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: TourFlowColors.primaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Conversation {
  const _Conversation({
    required this.title,
    required this.preview,
    required this.date,
    required this.language,
    required this.icon,
  });

  final String title;
  final String preview;
  final String date;
  final String language;
  final IconData icon;
}
