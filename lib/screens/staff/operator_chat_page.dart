import 'package:flutter/material.dart';

import '../../services/gemini_chat_service.dart';
import '../../widgets/tourflow_widgets.dart';

/// A separate operator-only assistant. It deliberately does not expose the
/// tourist booking, complaint, or support-ticket actions from ChatSupportPage.
class OperatorChatPage extends StatefulWidget {
  const OperatorChatPage({super.key});

  @override
  State<OperatorChatPage> createState() => _OperatorChatPageState();
}

class _OperatorChatPageState extends State<OperatorChatPage> {
  final _chatService = GeminiChatService();
  final _messageController = TextEditingController();
  final List<_OperatorChatMessage> _messages = [];

  String _language = 'English';
  String? _conversationId;
  bool _isSending = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadOperatorContext();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadOperatorContext() async {
    try {
      final user = await _chatService.getCurrentUserContext();
      if (!mounted) return;
      setState(() {
        _language = user.languageName;
        _loaded = true;
        _messages.add(
          _OperatorChatMessage(
            'Hello ${user.displayName}. I am your Operator Assistant. I can help with attraction listings, approved slots, capacity monitoring and operator reports.',
            isUser: false,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _messages.add(
          const _OperatorChatMessage(
            'I can help with attraction operations, slots, capacity and reports.',
            isUser: false,
          ),
        );
      });
    }
  }

  Future<void> _send([String? quickMessage]) async {
    final message = (quickMessage ?? _messageController.text).trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_OperatorChatMessage(message, isUser: true));
      _messageController.clear();
    });

    try {
      final response = await _chatService.sendMessage(
        message: message,
        language: _language,
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = response.conversationId;
        _messages.add(_OperatorChatMessage(response.reply, isUser: false));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _OperatorChatMessage(
            'The operator assistant could not reply: ${error.toString().replaceFirst('Exception: ', '')}',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Operator Assistant',
    role: 'TOURFLOW · OPERATOR',
    navigationRole: TourFlowNavigationRole.operator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: 4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Operations chat',
          subtitle:
              'Ask about attraction management, approved slots, visitor capacity or reports. This assistant cannot make tourist bookings.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'What needs attention today?',
            'How do I manage approved slots?',
            'How do I monitor live crowd capacity?',
          ]
              .map(
                (message) => ActionChip(
                  label: Text(message),
                  onPressed: _isSending ? null : () => _send(message),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (!_loaded)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 330,
            child: ListView(
              children: _messages.map(
            (message) => Align(
              alignment: message.isUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? TourFlowColors.primary
                      : TourFlowColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(message.text),
              ),
            ),
          ).toList(),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          minLines: 1,
          maxLines: 4,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            labelText: 'Ask the Operator Assistant',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Send',
              onPressed: _isSending ? null : _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ),
      ],
    ),
  );
}

class _OperatorChatMessage {
  const _OperatorChatMessage(this.text, {required this.isUser});
  final String text;
  final bool isUser;
}
