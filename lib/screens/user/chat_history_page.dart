import 'package:flutter/material.dart';

import '../../models/chat_models.dart';
import '../../services/gemini_chat_service.dart';
import '../../widgets/tourflow_widgets.dart';
import 'chat_support_page.dart';
import 'support_ticket_list_page.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  static const routeName = '/user/chat-history';

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final GeminiChatService _chatService = GeminiChatService();

  List<ChatConversation> _conversations = const [];
  String _displayName = 'Tourist';
  String _email = '';
  String _query = '';
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userContext = await _chatService.getCurrentUserContext();
      final conversations = await _chatService.getConversations();
      if (!mounted) return;
      setState(() {
        _displayName = userContext.displayName;
        _email = userContext.email;
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openConversation(ChatConversation conversation) async {
    await Navigator.pushNamed(
      context,
      ChatSupportPage.routeName,
      arguments: conversation.id,
    );
    if (mounted) await _loadHistory();
  }

  Future<void> _deleteConversation(ChatConversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TourFlowText('Delete conversation?'),
        content: TourFlowText(
          '“${conversation.title}” and all of its messages will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const TourFlowText('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: TourFlowColors.danger,
            ),
            child: const TourFlowText('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.deleteConversation(conversation.id);
      if (!mounted) return;
      setState(() {
        _conversations = _conversations
            .where((item) => item.id != conversation.id)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TourFlowText('Conversation deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TourFlowText(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visible = _conversations.where((item) {
      return normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.lastMessagePreview.toLowerCase().contains(normalizedQuery) ||
          item.language.toLowerCase().contains(normalizedQuery);
    }).toList();

    return TourFlowPage(
      title: 'Chat History',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: _displayName,
      email: _email,
      actions: [
        IconButton(
          tooltip: context.tr('Refresh'),
          onPressed: _isLoading ? null : _loadHistory,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: context.tr('Search your conversations'),
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
                  'Your conversations',
                  subtitle:
                      'Only your signed-in account can read these messages.',
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  SupportTicketListPage.routeName,
                ),
                icon: const Icon(Icons.support_agent_outlined, size: 18),
                label: const TourFlowText('Tickets'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            ModuleCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: TourFlowColors.muted,
                    ),
                    const SizedBox(height: 10),
                    TourFlowText(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const TourFlowText('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else if (visible.isEmpty)
            ModuleCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 44,
                      color: TourFlowColors.muted,
                    ),
                    const SizedBox(height: 10),
                    TourFlowText(
                      normalizedQuery.isEmpty
                          ? 'No saved conversations yet.'
                          : 'No matching conversations found.',
                    ),
                    if (normalizedQuery.isEmpty) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          ChatSupportPage.routeName,
                        ),
                        icon: const Icon(Icons.add_comment_outlined),
                        label: const TourFlowText('Start a conversation'),
                      ),
                    ],
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
                    onTap: () => _openConversation(conversation),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 23,
                            backgroundColor: TourFlowColors.lavender,
                            foregroundColor: TourFlowColors.primaryText,
                            child: Icon(Icons.chat_bubble_outline_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TourFlowText(
                                  conversation.title,
                                  style: const TextStyle(
                                    color: TourFlowColors.heading,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TourFlowText(
                                  conversation.lastMessagePreview.isEmpty
                                      ? 'No messages yet.'
                                      : conversation.lastMessagePreview,
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
                                    TourFlowText(
                                      _formatDate(conversation.lastMessageAt),
                                      style: const TextStyle(
                                        color: TourFlowColors.muted,
                                        fontSize: 9,
                                      ),
                                    ),
                                    TourFlowText(
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
                          PopupMenuButton<String>(
                            tooltip: context.tr('Conversation options'),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteConversation(conversation);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.delete_outline_rounded,
                                    color: TourFlowColors.danger,
                                  ),
                                  title: TourFlowText('Delete'),
                                ),
                              ),
                            ],
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

  String _formatDate(DateTime value) {
    final now = DateTime.now();
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    if (value.year == now.year &&
        value.month == now.month &&
        value.day == now.day) {
      return 'Today, $time';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}, $time';
  }
}
