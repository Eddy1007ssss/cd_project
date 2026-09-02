import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import '../../widgets/tourflow_widgets.dart';
import 'attraction_discovery_page.dart';
import 'chat_history_page.dart';
import 'language_settings_page.dart';
import 'support_ticket_form_page.dart';
import 'support_ticket_list_page.dart';

class ChatSupportPage extends StatefulWidget {
  const ChatSupportPage({super.key});

  static const routeName = '/user/chat';

  @override
  State<ChatSupportPage> createState() => _ChatSupportPageState();
}

class _ChatSupportPageState extends State<ChatSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hello Alex! I am your TourFlow assistant. I can help with attractions, available slots, opening hours, transportation and live crowd levels.',
      isUser: false,
      time: '10:24',
    ),
  ];

  static const _quickQuestions = [
    'Available attractions',
    'Live crowd status',
    'Opening hours',
    'Transportation help',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? quickQuestion]) {
    final value = (quickQuestion ?? _messageController.text).trim();
    if (value.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: value, isUser: true, time: '10:25'));
      _messages.add(
        _ChatMessage(
          text: _responseFor(value),
          isUser: false,
          time: '10:25',
        ),
      );
    });
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _responseFor(String question) {
    final value = question.toLowerCase();
    if (value.contains('crowd')) {
      return 'Old Town Square is currently Moderate at 58% capacity. Lumina Botanical Gardens is Low at 27% capacity.';
    }
    if (value.contains('hour')) {
      return 'National Museum is open today from 9:00 AM to 5:00 PM. Last entry is at 4:30 PM.';
    }
    if (value.contains('transport')) {
      return 'You can reach National Museum by MRT Muzium Negara. The entrance is about a 5-minute walk from Gate B.';
    }
    if (value.contains('slot') || value.contains('attraction')) {
      return 'I found several available attractions. National Museum has slots at 10:30 AM and 2:00 PM, while Lake Garden has a low-crowd slot at 4:00 PM.';
    }
    return 'I found information related to your question. If you still need help, you can create a support ticket for an administrator or attraction operator.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TourFlowColors.background,
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 3,
        onLogout: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/sign-in',
          (route) => false,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chatbot & Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Online · English',
              style: TextStyle(
                color: TourFlowColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Language',
            onPressed: () => Navigator.pushNamed(
              context,
              LanguageSettingsPage.routeName,
            ),
            icon: const Icon(Icons.translate_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Support menu',
            onSelected: (value) {
              if (value == 'history') {
                Navigator.pushNamed(context, ChatHistoryPage.routeName);
              } else if (value == 'tickets') {
                Navigator.pushNamed(context, SupportTicketListPage.routeName);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded),
                  title: Text('Chat history'),
                ),
              ),
              PopupMenuItem(
                value: 'tickets',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.support_agent_rounded),
                  title: Text('My support tickets'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              children: [
                const _AssistantInfoCard(),
                const SizedBox(height: 14),
                ..._messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MessageBubble(message: message),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quick questions',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickQuestions
                      .map(
                        (question) => ActionChip(
                          onPressed: () => _sendMessage(question),
                          avatar: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: TourFlowColors.primaryText,
                          ),
                          label: Text(question),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: TourFlowColors.border),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                _RecommendationCard(
                  onBrowse: () => Navigator.pushNamed(
                    context,
                    AttractionDiscoveryPage.routeName,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    SupportTicketFormPage.routeName,
                  ),
                  icon: const Icon(Icons.contact_support_outlined),
                  label: const Text('Still need help? Create a support ticket'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TourFlowColors.primaryText,
                    side: const BorderSide(color: TourFlowColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ],
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 3),
    );
  }
}

class _AssistantInfoCard extends StatelessWidget {
  const _AssistantInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D3B7)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: TourFlowColors.primary,
            foregroundColor: TourFlowColors.primaryText,
            child: Icon(Icons.smart_toy_outlined),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TourFlow Assistant',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Answers use attraction information, booking availability, visitor guidelines and live crowd data.',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 15,
              backgroundColor: TourFlowColors.primary,
              foregroundColor: TourFlowColors.primaryText,
              child: Icon(Icons.smart_toy_outlined, size: 16),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
              decoration: BoxDecoration(
                color: message.isUser
                    ? TourFlowColors.primary
                    : Colors.white,
                border: Border.all(
                  color: message.isUser
                      ? TourFlowColors.primary
                      : TourFlowColors.border.withOpacity(.65),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: Radius.circular(message.isUser ? 15 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TourFlowColors.border.withOpacity(.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: TourFlowColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: TourFlowColors.primaryText,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need attraction suggestions?',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Browse available attractions and time slots.',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onBrowse, child: const Text('Browse')),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7E2DA))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask TourFlow anything...',
                  filled: true,
                  fillColor: TourFlowColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              style: IconButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
              ),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  final String text;
  final bool isUser;
  final String time;
}
