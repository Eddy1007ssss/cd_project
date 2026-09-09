import 'package:flutter/material.dart';

import '../../services/gemini_chat_service.dart';
import '../../services/support_ticket_service.dart';
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
  final _ticketService = SupportTicketService();
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

  List<String> get _quickQuestions => switch (_language) {
    'Mandarin' => const ['今天需要处理什么？', '如何管理已批准的时段？', '如何监控实时人流？'],
    'Bahasa Malaysia' => const ['Apa yang perlu diberi perhatian hari ini?', 'Bagaimana mengurus slot yang diluluskan?', 'Bagaimana memantau kapasiti orang ramai?'],
    'Japanese' => const ['今日の対応事項は？', '承認済み時間枠の管理方法は？', '混雑状況の監視方法は？'],
    'Korean' => const ['오늘 무엇을 확인해야 하나요?', '승인된 시간대를 어떻게 관리하나요?', '실시간 혼잡도를 어떻게 모니터링하나요?'],
    _ => const ['What needs attention today?', 'How do I manage approved slots?', 'How do I monitor live crowd capacity?'],
  };

  Future<void> _reportTechnicalProblem() async {
    final subject = TextEditingController();
    final details = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report technical problem'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 12),
          TextField(controller: details, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Describe the app problem')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Submit')),
        ],
      ),
    );
    if (submit != true || !mounted) return;
    try {
      await _ticketService.createTicket(category: 'technical', issueType: 'app_error', subject: subject.text.trim(), description: details.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Technical support ticket submitted to the administrator.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
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
          children: _quickQuestions
              .map(
                (message) => ActionChip(
                  label: Text(message),
                  onPressed: _isSending ? null : () => _send(message),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _isSending ? null : _reportTechnicalProblem,
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Report technical problem'),
          ),
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
