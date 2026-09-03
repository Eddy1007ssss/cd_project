import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiChatResponse {
  const GeminiChatResponse({
    required this.reply,
    this.interactionId,
  });

  final String reply;
  final String? interactionId;
}

class GeminiChatService {
  GeminiChatService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<GeminiChatResponse> sendMessage({
    required String message,
    String language = 'English',
    String? previousInteractionId,
  }) async {
    final response = await _client.functions.invoke(
      'gemini-chat',
      body: {
        'message': message,
        'language': language,
        if (previousInteractionId != null &&
            previousInteractionId.trim().isNotEmpty)
          'previousInteractionId': previousInteractionId,
      },
    );

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      throw Exception(_errorMessage(data));
    }

    if (data is! Map) {
      throw Exception('The chatbot returned an invalid response.');
    }

    final reply = data['reply']?.toString().trim() ?? '';

    if (reply.isEmpty) {
      throw Exception('The chatbot returned an empty reply.');
    }

    final interactionIdValue = data['interactionId'];

    return GeminiChatResponse(
      reply: reply,
      interactionId: interactionIdValue is String &&
          interactionIdValue.trim().isNotEmpty
          ? interactionIdValue
          : null,
    );
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
