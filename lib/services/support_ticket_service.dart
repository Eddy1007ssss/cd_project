import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_models.dart';

class ComplaintPhoto {
  const ComplaintPhoto({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class SupportTicketService {
  SupportTicketService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _bucket = 'support-ticket-attachments';
  static const _ticketColumns =
      'id, ticket_code, requester_name, attraction_name, booking_code, '
      'category, subject, description, priority, status, submission_language, '
      'assigned_to, created_at, updated_at, resolved_at';

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to continue.');
    return id;
  }

  Future<TicketCreationResult> createFromComplaint({
    required ComplaintDraft draft,
    required String conversationId,
    ComplaintPhoto? photo,
  }) {
    final attractionId = draft.attractionId;
    final description = draft.description;
    final category = draft.category;
    if (!draft.readyForConfirmation ||
        attractionId == null ||
        description == null ||
        category == null) {
      throw const FormatException('The complaint information is incomplete.');
    }
    if (draft.requiresPhoto && photo == null) {
      throw const FormatException(
        'Choose a photo, or restart the complaint and select No Photo.',
      );
    }

    return createTicket(
      attractionId: attractionId,
      bookingId: draft.bookingId,
      category: category,
      subject: draft.generatedSubject,
      description: description,
      sourceConversationId: conversationId,
      photo: photo,
    );
  }

  Future<TicketCreationResult> createTicket({
    required String attractionId,
    required String category,
    required String subject,
    required String description,
    String? bookingId,
    String? sourceConversationId,
    ComplaintPhoto? photo,
  }) async {
    _userId;
    final result = await _client.rpc(
      'create_support_ticket',
      params: {
        'p_attraction_id': attractionId,
        'p_booking_id': bookingId,
        'p_category': category,
        'p_subject': subject.trim(),
        'p_description': description.trim(),
        'p_source_conversation_id': sourceConversationId,
      },
    );
    final row = _rpcRow(result);
    final ticketId = row['id'] as String;

    String? attachmentWarning;
    if (photo != null) {
      try {
        await _uploadPhoto(ticketId, photo);
      } catch (error) {
        attachmentWarning =
            'The ticket was created, but the photo could not be uploaded: '
            '${_message(error)}';
      }
    }

    return TicketCreationResult(
      id: ticketId,
      code: row['ticket_code'] as String,
      status: row['status'] as String? ?? 'pending',
      confirmationMessage:
          row['confirmation_message'] as String? ?? 'Complaint submitted.',
      attachmentWarning: attachmentWarning,
    );
  }

  Future<void> _uploadPhoto(String ticketId, ComplaintPhoto photo) async {
    if (photo.bytes.isEmpty || photo.bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('The image must be 5 MB or smaller.');
    }
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(photo.mimeType)) {
      throw const FormatException('Only JPEG, PNG, or WebP images are allowed.');
    }

    final safeName = photo.fileName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final path =
        '$_userId/$ticketId/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await _client.storage.from(_bucket).uploadBinary(
      path,
      photo.bytes,
      fileOptions: FileOptions(contentType: photo.mimeType, upsert: false),
    );

    try {
      await _client.rpc(
        'add_support_ticket_attachment',
        params: {
          'p_ticket_id': ticketId,
          'p_storage_path': path,
          'p_file_name': photo.fileName,
          'p_mime_type': photo.mimeType,
          'p_size_bytes': photo.bytes.length,
        },
      );
    } catch (_) {
      await _client.storage.from(_bucket).remove([path]);
      rethrow;
    }
  }

  Future<List<SupportAttractionOption>> fetchApprovedAttractions() async {
    _userId;
    final rows = await _client
        .from('attractions')
        .select('id, name')
        .eq('listing_status', 'approved')
        .order('name', ascending: true);
    return rows
        .map(
          (row) => SupportAttractionOption.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<List<SupportBookingOption>> fetchMyBookings() async {
    final rows = await _client
        .from('bookings')
        .select(
          'id, booking_code, slot:attraction_slots(starts_at, '
          'attraction:attractions(id, name))',
        )
        .eq('tourist_id', _userId)
        .order('created_at', ascending: false)
        .limit(30);
    return rows
        .map(
          (row) => SupportBookingOption.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<List<SupportTicket>> fetchMyTickets() async {
    final rows = await _client
        .from('support_tickets')
        .select(_ticketColumns)
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return _ticketList(rows);
  }

  Future<List<SupportTicket>> fetchManagedTickets() async {
    _userId;
    final rows = await _client
        .from('support_tickets')
        .select(_ticketColumns)
        .order('created_at', ascending: false);
    return _ticketList(rows);
  }

  Future<SupportTicketDetailsData> fetchTicketDetails(String ticketId) async {
    _userId;
    final ticketRow = await _client
        .from('support_tickets')
        .select(_ticketColumns)
        .eq('id', ticketId)
        .single();
    final eventRows = await _client
        .from('support_ticket_events')
        .select(
          'id, sequence_number, actor_name, actor_role, event_type, message, '
          'from_status, to_status, created_at',
        )
        .eq('ticket_id', ticketId)
        .order('sequence_number', ascending: true);
    final attachmentRows = await _client
        .from('support_ticket_attachments')
        .select(
          'id, storage_path, file_name, mime_type, size_bytes, created_at',
        )
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    final attachments = <SupportTicketAttachment>[];
    for (final raw in attachmentRows) {
      final row = Map<String, dynamic>.from(raw);
      final signedUrl = await _client.storage
          .from(_bucket)
          .createSignedUrl(row['storage_path'] as String, 3600);
      attachments.add(
        SupportTicketAttachment(
          id: row['id'] as String,
          fileName: row['file_name'] as String,
          mimeType: row['mime_type'] as String,
          sizeBytes: (row['size_bytes'] as num).toInt(),
          createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          signedUrl: signedUrl,
        ),
      );
    }

    return SupportTicketDetailsData(
      ticket: SupportTicket.fromMap(Map<String, dynamic>.from(ticketRow)),
      events: eventRows
          .map(
            (row) => SupportTicketEvent.fromMap(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(),
      attachments: attachments,
    );
  }

  Future<String> replyToTicket(String ticketId, String message) async {
    final result = await _client.rpc(
      'reply_to_support_ticket',
      params: {'p_ticket_id': ticketId, 'p_message': message.trim()},
    );
    return result?.toString() ?? 'in_progress';
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _client.rpc(
      'update_support_ticket_status',
      params: {'p_ticket_id': ticketId, 'p_status': status},
    );
  }

  List<SupportTicket> _ticketList(List<dynamic> rows) => rows
      .map(
        (row) => SupportTicket.fromMap(Map<String, dynamic>.from(row as Map)),
      )
      .toList();
}

Map<String, dynamic> _rpcRow(Object? result) {
  final value = result is List && result.isNotEmpty ? result.first : result;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('The support service returned invalid data.');
}

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '').trim();
