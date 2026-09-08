import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_models.dart';

class ChatImageAttachment {
  const ChatImageAttachment({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class IssueReportCreationResult {
  const IssueReportCreationResult({
    required this.id,
    required this.code,
    required this.status,
    required this.confirmationMessage,
  });

  final String id;
  final String code;
  final String status;
  final String confirmationMessage;
}

class ChatIssueReportService {
  ChatIssueReportService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to continue.');
    return id;
  }

  Future<IssueReportCreationResult> createFromComplaint({
    required ComplaintDraft draft,
    required String conversationId,
    ChatImageAttachment? photo,
  }) async {
    final attractionId = draft.attractionId;
    final category = draft.category;
    final description = draft.description;
    if (!draft.readyForConfirmation ||
        attractionId == null ||
        category == null ||
        description == null) {
      throw const FormatException('The complaint information is incomplete.');
    }
    if (draft.requiresPhoto && photo == null) {
      throw const FormatException('Choose a photo or select No Photo.');
    }

    String? uploadedPath;
    try {
      if (photo != null) uploadedPath = await _uploadEvidence(photo);
      final result = await _client.rpc(
        'create_issue_report_from_chat',
        params: {
          'p_attraction_id': attractionId,
          'p_booking_id': draft.bookingId,
          'p_category': category,
          'p_description': description,
          'p_evidence_path': uploadedPath,
          'p_source_conversation_id': conversationId,
        },
      );
      final row = _rpcRow(result);
      return IssueReportCreationResult(
        id: row['id'] as String,
        code: row['report_code'] as String,
        status: row['status'] as String? ?? 'new',
        confirmationMessage:
            row['confirmation_message'] as String? ?? 'Complaint submitted.',
      );
    } catch (_) {
      if (uploadedPath != null) {
        await _client.storage.from('issue-evidence').remove([uploadedPath]);
      }
      rethrow;
    }
  }

  Future<String> _uploadEvidence(ChatImageAttachment photo) async {
    if (photo.bytes.isEmpty || photo.bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('The image must be 5 MB or smaller.');
    }
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(photo.mimeType)) {
      throw const FormatException('Only JPEG, PNG, or WebP images are allowed.');
    }
    final safeName = photo.fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$_userId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage.from('issue-evidence').uploadBinary(
      path,
      photo.bytes,
      fileOptions: FileOptions(contentType: photo.mimeType, upsert: false),
    );
    return path;
  }

  Map<String, dynamic> _rpcRow(Object? value) {
    final row = value is List ? (value.isEmpty ? null : value.first) : value;
    if (row is! Map) throw const FormatException('Invalid database response.');
    return Map<String, dynamic>.from(row);
  }
}
