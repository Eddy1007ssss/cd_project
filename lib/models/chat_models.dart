enum ChatMessageSender { user, assistant }

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.language,
    required this.lastMessagePreview,
    required this.createdAt,
    required this.lastMessageAt,
  });

  final String id;
  final String title;
  final String language;
  final String lastMessagePreview;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'TourFlow conversation',
      language: map['language'] as String? ?? 'English',
      lastMessagePreview: map['last_message_preview'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      lastMessageAt: DateTime.parse(
        map['last_message_at'] as String? ?? map['created_at'] as String,
      ).toLocal(),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final ChatMessageSender sender;
  final String content;
  final DateTime createdAt;

  bool get isUser => sender == ChatMessageSender.user;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      sender: map['sender'] == 'user'
          ? ChatMessageSender.user
          : ChatMessageSender.assistant,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

class ChatUserContext {
  const ChatUserContext({
    required this.displayName,
    required this.email,
    required this.languageCode,
    required this.languageName,
  });

  final String displayName;
  final String email;
  final String languageCode;
  final String languageName;
}
