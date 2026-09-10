import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_models.dart';

class SupportTicketService {
  SupportTicketService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _bucket = 'support-ticket-attachments';
  static const _ticketColumns =
      'id, ticket_code, requester_name, attraction_name, booking_code, '
      'category, subject, description, priority, status, submission_language, '
      'user_id, assigned_to, issue_type, handler_type, created_at, updated_at, resolved_at';

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to continue.');
    return id;
  }

  Future<TicketCreationResult> createFromDraft({
    required SupportTicketDraft draft,
    required String conversationId,
  }) {
    final category = draft.category;
    final issueType = draft.issueType;
    if (!draft.readyForConfirmation || category == null || issueType == null) {
      throw const FormatException('The support information is incomplete.');
    }

    return createTicket(
      attractionId: draft.attractionId,
      bookingId: draft.bookingId,
      category: category,
      issueType: issueType,
      subject: draft.generatedSubject,
      description: draft.generatedDescription,
      sourceConversationId: conversationId,
    );
  }

  Future<TicketCreationResult> createTicket({
    required String category,
    required String issueType,
    required String subject,
    required String description,
    String? attractionId,
    String? bookingId,
    String? sourceConversationId,
  }) async {
    _userId;
    if (subject.trim().runes.length < 5 || subject.trim().runes.length > 160 ||
        description.trim().runes.length < 10 || description.trim().runes.length > 4000) {
      throw const FormatException('Use a subject of 5–160 characters and details of 10–4000 characters.');
    }
    final result = await _client.rpc(
      'create_support_ticket',
      params: {
        'p_category': category,
        'p_issue_type': issueType,
        'p_subject': subject.trim(),
        'p_description': description.trim(),
        'p_booking_id': bookingId,
        'p_attraction_id': attractionId,
        'p_source_conversation_id': sourceConversationId,
      },
    );
    final row = _rpcRow(result);
    final ticketId = row['id'] as String;

    return TicketCreationResult(
      id: ticketId,
      code: row['ticket_code'] as String,
      status: row['status'] as String? ?? 'pending',
      confirmationMessage: row['confirmation_message'] as String? ??
          'Support ticket submitted.',
    );
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
          (row) =>
              SupportAttractionOption.fromMap(Map<String, dynamic>.from(row)),
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
          (row) => SupportBookingOption.tryFromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .whereType<SupportBookingOption>()
        .toList();
  }

  Future<List<SupportTicket>> fetchMyTickets() async {
    final rows = await _client
        .from('support_tickets')
        .select(_ticketColumns)
        .eq('user_id', _userId)
        .eq('case_type', 'support')
        .order('created_at', ascending: false);
    return _ticketList(rows);
  }

  Future<List<SupportTicket>> fetchManagedTickets({required bool isAdmin}) async {
    _userId;
    var query = _client
        .from('support_tickets')
        .select(_ticketColumns)
        .eq('case_type', 'support');
    if (!isAdmin) query = query.eq('handler_type', 'operator');
    final rows = await query.order('created_at', ascending: false);
    if (!isAdmin) return _ticketList(rows);
    final ticketRows = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    final userIds = ticketRows.map((row) => row['user_id']?.toString()).whereType<String>().toSet().toList();
    if (userIds.isEmpty) return _ticketList(ticketRows);
    final profiles = await _client.from('profiles').select('id, role').inFilter('id', userIds);
    final roles = <String, String>{for (final profile in profiles) profile['id'].toString(): profile['role']?.toString() ?? 'tourist'};
    for (final row in ticketRows) { row['user_role'] = roles[row['user_id']?.toString()] ?? 'tourist'; }
    return _ticketList(ticketRows);
  }

  Future<SupportTicketDetailsData> fetchTicketDetails(String ticketId) async {
    _userId;
    final ticketRow = await _client
        .from('support_tickets')
        .select(_ticketColumns)
        .eq('id', ticketId)
        .eq('case_type', 'support')
        .single();
    final ticketMap = Map<String, dynamic>.from(ticketRow);
    final requesterId = ticketMap['user_id']?.toString();
    if (requesterId != null) {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', requesterId)
          .maybeSingle();
      ticketMap['user_role'] = profile?['role']?.toString() ?? 'tourist';
    }
    final relatedRows = await Future.wait([
      _client
          .from('support_ticket_events')
          .select(
            'id, sequence_number, actor_name, actor_role, event_type, message, '
            'from_status, to_status, created_at',
          )
          .eq('ticket_id', ticketId)
          .order('sequence_number', ascending: true),
      _client
          .from('support_ticket_attachments')
          .select(
            'id, storage_bucket, storage_path, file_name, mime_type, '
            'size_bytes, created_at',
          )
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true),
    ]);
    final eventRows = relatedRows[0];
    final attachmentRows = relatedRows[1];

    final attachments = await Future.wait(
      attachmentRows.map((raw) async {
        final row = Map<String, dynamic>.from(raw);
        final bucket = row['storage_bucket'] as String? ?? _bucket;
        final signedUrl = await _client.storage
            .from(bucket)
            .createSignedUrl(row['storage_path'] as String, 3600);
        return SupportTicketAttachment(
          id: row['id'] as String,
          fileName: row['file_name'] as String,
          mimeType: row['mime_type'] as String,
          sizeBytes: (row['size_bytes'] as num).toInt(),
          createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          signedUrl: signedUrl,
          storageBucket: bucket,
        );
      }),
    );

    return SupportTicketDetailsData(
      ticket: SupportTicket.fromMap(ticketMap),
      events: eventRows
          .map(
            (row) => SupportTicketEvent.fromMap(Map<String, dynamic>.from(row)),
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

  Future<void> replyAsTourist(String ticketId, String message) async {
    await _client.rpc(
      'reply_to_my_support_ticket',
      params: {'p_ticket_id': ticketId, 'p_message': message.trim()},
    );
  }

  Future<void> closeMyTicket(String ticketId) async {
    await _client.rpc(
      'close_my_support_ticket',
      params: {'p_ticket_id': ticketId},
    );
  }

  Future<void> reopenMyTicket(String ticketId) async {
    await _client.rpc(
      'reopen_my_support_ticket',
      params: {'p_ticket_id': ticketId},
    );
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _client.rpc(
      'update_support_ticket_status',
      params: {'p_ticket_id': ticketId, 'p_status': status},
    );
  }

  Future<TicketDeletionResult> deletePendingTicket(String ticketId) async {
    final result = await _client.rpc(
      'delete_my_pending_support_ticket',
      params: {'p_ticket_id': ticketId},
    );
    final row = _rpcRow(result);
    final objects = (row['storage_objects'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    try {
      final grouped = <String, List<String>>{};
      for (final object in objects) {
        final bucket = object['bucket']?.toString();
        final path = object['path']?.toString();
        if (bucket == null || path == null) continue;
        grouped.putIfAbsent(bucket, () => <String>[]).add(path);
      }
      await Future.wait(
        grouped.entries.map(
          (entry) => _client.storage.from(entry.key).remove(entry.value),
        ),
      );
      return const TicketDeletionResult();
    } catch (error) {
      return TicketDeletionResult(
        cleanupWarning:
            'The ticket was deleted, but an attachment could not '
            'be removed: ${_message(error)}',
      );
    }
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
