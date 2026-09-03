import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiChatResponse {
  const GeminiChatResponse({required this.reply});

  final String reply;
}

class GeminiChatService {
  GeminiChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<GeminiChatResponse> sendMessage({
    required String message,
    String language = 'English',
  }) async {
    final response = await _client.functions.invoke(
      'gemini-chat',
      body: {'message': message, 'language': language},
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

    return GeminiChatResponse(reply: reply);
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
