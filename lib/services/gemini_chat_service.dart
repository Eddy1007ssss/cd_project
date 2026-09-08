import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_booking_models.dart';
import '../models/chat_models.dart';
import '../models/support_ticket_models.dart';

class GeminiChatResponse {
  const GeminiChatResponse({
    required this.reply,
    required this.conversationId,
    this.complaintDraft,
    this.bookingDraft,
    this.supportTicketDraft,
  });

  final String reply;
  final String conversationId;
  final ComplaintDraft? complaintDraft;
  final ChatBookingDraft? bookingDraft;
  final SupportTicketDraft? supportTicketDraft;
}

class GeminiChatService {
  GeminiChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<GeminiChatResponse> sendMessage({
    required String message,
    String language = 'English',
    String? conversationId,
    Map<String, dynamic>? complaintAction,
    Map<String, dynamic>? bookingAction,
    Map<String, dynamic>? supportTicketAction,
  }) async {
    _requireUser();

    final requestBody = <String, dynamic>{
      'message': message,
      'language': language,
    };
    final trimmedConversationId = conversationId?.trim();
    if (trimmedConversationId != null && trimmedConversationId.isNotEmpty) {
      requestBody['conversationId'] = trimmedConversationId;
    }
    if (complaintAction != null) {
      requestBody['complaintAction'] = complaintAction;
    }
    if (bookingAction != null) {
      requestBody['bookingAction'] = bookingAction;
    }
    if (supportTicketAction != null) {
      requestBody['supportTicketAction'] = supportTicketAction;
    }

    final response = await _client.functions.invoke(
      'gemini-chat',
      body: requestBody,
    );

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      throw Exception(_errorMessage(data));
    }

    if (data is! Map) {
      throw Exception('The chatbot returned an invalid response.');
    }

    final reply = data['reply']?.toString().trim() ?? '';
    final returnedConversationId = data['conversationId']?.toString() ?? '';
    final rawComplaintDraft = data['complaintDraft'];
    final rawBookingDraft = data['bookingDraft'];
    final rawSupportTicketDraft = data['supportTicketDraft'];

    if (reply.isEmpty) {
      throw Exception('The chatbot returned an empty reply.');
    }

    if (returnedConversationId.isEmpty) {
      throw Exception('The chatbot did not return a conversation ID.');
    }

    return GeminiChatResponse(
      reply: reply,
      conversationId: returnedConversationId,
      complaintDraft: rawComplaintDraft is Map
          ? ComplaintDraft.fromMap(
              Map<String, dynamic>.from(rawComplaintDraft),
            )
          : null,
      bookingDraft: rawBookingDraft is Map
          ? ChatBookingDraft.fromMap(
              Map<String, dynamic>.from(rawBookingDraft),
            )
          : null,
      supportTicketDraft: rawSupportTicketDraft is Map
          ? SupportTicketDraft.fromMap(
              Map<String, dynamic>.from(rawSupportTicketDraft),
            )
          : null,
    );
  }

  Future<SupportTicketDraft?> getSupportTicketDraft(
    String conversationId,
  ) async {
    final user = _requireUser();
    final row = await _client
        .from('chat_conversations')
        .select('support_ticket_draft')
        .eq('id', conversationId)
        .eq('user_id', user.id)
        .maybeSingle();
    final rawDraft = row?['support_ticket_draft'];
    if (rawDraft is! Map) return null;
    return SupportTicketDraft.fromMap(Map<String, dynamic>.from(rawDraft));
  }

  Future<ChatBookingDraft?> getBookingDraft(String conversationId) async {
    final user = _requireUser();
    final row = await _client
        .from('chat_conversations')
        .select('booking_action_draft')
        .eq('id', conversationId)
        .eq('user_id', user.id)
        .maybeSingle();
    final rawDraft = row?['booking_action_draft'];
    if (rawDraft is! Map) return null;
    return ChatBookingDraft.fromMap(Map<String, dynamic>.from(rawDraft));
  }

  Future<void> clearBookingDraft(String conversationId) async {
    final user = _requireUser();
    await _client
        .from('chat_conversations')
        .update({'booking_action_draft': null})
        .eq('id', conversationId)
        .eq('user_id', user.id);
  }

  Future<ComplaintDraft?> getComplaintDraft(String conversationId) async {
    final user = _requireUser();
    final row = await _client
        .from('chat_conversations')
        .select('complaint_draft')
        .eq('id', conversationId)
        .eq('user_id', user.id)
        .maybeSingle();
    final rawDraft = row?['complaint_draft'];
    if (rawDraft is! Map) return null;
    return ComplaintDraft.fromMap(Map<String, dynamic>.from(rawDraft));
  }

  Future<List<ComplaintDraftConversation>> getComplaintDrafts() async {
    final user = _requireUser();
    final rows = await _client
        .from('chat_conversations')
        .select('id, title, last_message_at, complaint_draft')
        .eq('user_id', user.id)
        .not('complaint_draft', 'is', null)
        .order('last_message_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => row['complaint_draft'] is Map)
        .map(ComplaintDraftConversation.fromMap)
        .where((item) => item.conversationId.isNotEmpty)
        .toList();
  }

  Future<ChatUserContext> getCurrentUserContext() async {
    final user = _requireUser();
    final metadata = user.userMetadata ?? const <String, dynamic>{};

    Map<String, dynamic>? profile;
    try {
      final value = await _client
          .from('profiles')
          .select('full_name, preferred_language')
          .eq('id', user.id)
          .maybeSingle();
      if (value != null) profile = Map<String, dynamic>.from(value);
    } catch (_) {
      // Authentication metadata is the safe fallback while a profile is being
      // created or when the optional profile query is unavailable.
    }

    final rawName = profile?['full_name']?.toString().trim();
    final metadataName = metadata['full_name']?.toString().trim();
    final email = user.email ?? '';
    final fallbackName = email.contains('@') ? email.split('@').first : 'Tourist';
    final languageCode =
        profile?['preferred_language']?.toString().trim() ??
        metadata['preferred_language']?.toString().trim() ??
        'en';

    return ChatUserContext(
      displayName: rawName?.isNotEmpty == true
          ? rawName!
          : metadataName?.isNotEmpty == true
          ? metadataName!
          : fallbackName,
      email: email,
      languageCode: languageCode,
      languageName: languageNameFromCode(languageCode),
    );
  }

  Future<List<ChatConversation>> getConversations() async {
    final user = _requireUser();
    final rows = await _client
        .from('chat_conversations')
        .select(
          'id, title, language, last_message_preview, created_at, last_message_at',
        )
        .eq('user_id', user.id)
        .order('last_message_at', ascending: false);

    return rows
        .map(
          (row) => ChatConversation.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    _requireUser();
    final rows = await _client
        .from('chat_messages')
        .select(
          'id, conversation_id, sender, content, created_at, sequence_number',
        )
        .eq('conversation_id', conversationId)
        // Always request the oldest messages first. The Dart-side sort below
        // repeats this rule so the UI never depends only on server ordering.
        .order('created_at', ascending: true)
        .order('sender', ascending: false)
        .order('sequence_number', ascending: true);

    final orderedRows = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    orderedRows.sort((first, second) {
      final firstTime = DateTime.parse(first['created_at'] as String);
      final secondTime = DateTime.parse(second['created_at'] as String);
      final timeComparison = firstTime.compareTo(secondTime);
      if (timeComparison != 0) return timeComparison;

      // Older two-row inserts can share the exact same timestamp. In that
      // case the user's question must appear before the assistant's reply.
      final firstIsUser = first['sender'] == 'user';
      final secondIsUser = second['sender'] == 'user';
      if (firstIsUser != secondIsUser) return firstIsUser ? -1 : 1;

      final firstSequence = _sequenceNumber(first['sequence_number']);
      final secondSequence = _sequenceNumber(second['sequence_number']);
      return firstSequence.compareTo(secondSequence);
    });

    return orderedRows.map(ChatMessage.fromMap).toList();
  }

  Future<bool> conversationExists(String conversationId) async {
    final user = _requireUser();
    final conversation = await _client
        .from('chat_conversations')
        .select('id')
        .eq('id', conversationId)
        .eq('user_id', user.id)
        .maybeSingle();

    return conversation != null;
  }

  Future<void> deleteConversation(String conversationId) async {
    final user = _requireUser();
    await _client
        .from('chat_conversations')
        .delete()
        .eq('id', conversationId)
        .eq('user_id', user.id);
  }

  Future<void> updatePreferredLanguage(String languageCode) async {
    _requireUser();
    await _client.rpc(
      'set_my_preferred_language',
      params: {'p_language': languageCode},
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in before using the chatbot.');
    }
    return user;
  }

  int _sequenceNumber(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _errorMessage(Object? data) {
    if (data is Map) {
      final error = data['error'];

      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      if (error is Map) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    }

    return 'The chatbot is temporarily unavailable. Please try again.';
  }
}

String languageNameFromCode(String? code) {
  return switch (code?.toLowerCase()) {
    'ms' || 'bm' => 'Bahasa Malaysia',
    'zh' || 'zh-cn' => 'Mandarin',
    'ja' => 'Japanese',
    'ko' => 'Korean',
    _ => 'English',
  };
}

String languageCodeFromName(String name) {
  return switch (name) {
    'Bahasa Malaysia' => 'ms',
    'Mandarin' => 'zh',
    'Japanese' => 'ja',
    'Korean' => 'ko',
    _ => 'en',
  };
}
