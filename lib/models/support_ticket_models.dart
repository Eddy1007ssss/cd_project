class ComplaintBookingOption {
  const ComplaintBookingOption({
    required this.id,
    required this.code,
    required this.attractionName,
    required this.startsAt,
  });

  final String id;
  final String code;
  final String attractionName;
  final DateTime? startsAt;

  factory ComplaintBookingOption.fromMap(Map<String, dynamic> map) {
    final rawStartsAt = map['startsAt']?.toString();
    return ComplaintBookingOption(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      attractionName: map['attractionName']?.toString() ?? '',
      startsAt: rawStartsAt == null || rawStartsAt.isEmpty
          ? null
          : DateTime.tryParse(rawStartsAt)?.toLocal(),
    );
  }
}

class ComplaintDraft {
  const ComplaintDraft({
    required this.attractionId,
    required this.attractionName,
    required this.category,
    required this.bookingId,
    required this.bookingCode,
    required this.bookingNotApplicable,
    required this.baseDescription,
    required this.additionalDetails,
    required this.additionalDetailsComplete,
    required this.description,
    required this.wantsPhoto,
    required this.missingFields,
    required this.bookingOptions,
  });

  final String? attractionId;
  final String? attractionName;
  final String? category;
  final String? bookingId;
  final String? bookingCode;
  final bool bookingNotApplicable;
  final String? baseDescription;
  final String? additionalDetails;
  final bool additionalDetailsComplete;
  final String? description;
  final bool? wantsPhoto;
  final List<String> missingFields;
  final List<ComplaintBookingOption> bookingOptions;

  bool get readyForConfirmation => missingFields.isEmpty;
  bool get requiresPhoto => wantsPhoto == true;
  bool get canGoBack => attractionId != null;

  String get categoryLabel => supportTicketCategoryLabel(category);

  String get generatedSubject {
    final attraction = attractionName?.trim();
    final place = attraction == null || attraction.isEmpty
        ? 'TourFlow attraction'
        : attraction;
    return '$categoryLabel - $place';
  }

  factory ComplaintDraft.fromMap(Map<String, dynamic> map) {
    final options = map['bookingOptions'];
    return ComplaintDraft(
      attractionId: _nullableString(map['attractionId']),
      attractionName: _nullableString(map['attractionName']),
      category: _nullableString(map['category']),
      bookingId: _nullableString(map['bookingId']),
      bookingCode: _nullableString(map['bookingCode']),
      bookingNotApplicable: map['bookingNotApplicable'] == true,
      baseDescription:
          _nullableString(map['baseDescription']) ??
          _nullableString(map['description']),
      additionalDetails: _nullableString(map['additionalDetails']),
      additionalDetailsComplete: map['additionalDetailsComplete'] is bool
          ? map['additionalDetailsComplete'] as bool
          : _nullableString(map['description']) != null,
      description: _nullableString(map['description']),
      wantsPhoto: map['wantsPhoto'] is bool ? map['wantsPhoto'] as bool : null,
      missingFields: (map['missingFields'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      bookingOptions: (options as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ComplaintBookingOption.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class ComplaintDraftConversation {
  const ComplaintDraftConversation({
    required this.conversationId,
    required this.title,
    required this.lastMessageAt,
    required this.draft,
  });

  final String conversationId;
  final String title;
  final DateTime? lastMessageAt;
  final ComplaintDraft draft;

  factory ComplaintDraftConversation.fromMap(Map<String, dynamic> map) {
    final rawDraft = map['complaint_draft'];
    if (rawDraft is! Map) {
      throw const FormatException('Complaint draft data is missing.');
    }

    final rawLastMessageAt = map['last_message_at']?.toString();
    return ComplaintDraftConversation(
      conversationId: map['id']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? '',
      lastMessageAt: rawLastMessageAt == null || rawLastMessageAt.isEmpty
          ? null
          : DateTime.tryParse(rawLastMessageAt)?.toLocal(),
      draft: ComplaintDraft.fromMap(Map<String, dynamic>.from(rawDraft)),
    );
  }
}

class SupportTicketDraft {
  const SupportTicketDraft({
    required this.category,
    required this.issueType,
    required this.issueLabel,
    required this.bookingId,
    required this.bookingCode,
    required this.attractionId,
    required this.attractionName,
    required this.bookingNotApplicable,
    required this.additionalDetails,
    required this.additionalDetailsComplete,
    required this.missingFields,
    required this.bookingOptions,
  });

  final String? category;
  final String? issueType;
  final String? issueLabel;
  final String? bookingId;
  final String? bookingCode;
  final String? attractionId;
  final String? attractionName;
  final bool bookingNotApplicable;
  final String? additionalDetails;
  final bool additionalDetailsComplete;
  final List<String> missingFields;
  final List<ComplaintBookingOption> bookingOptions;

  bool get readyForConfirmation => missingFields.isEmpty;
  bool get canGoBack => category != null;
  bool get needsBooking => category == 'booking' || category == 'qr_check_in';
  String get categoryLabel => supportTicketCategoryLabel(category);
  String get generatedSubject {
    final label = issueLabel?.trim().isNotEmpty == true
        ? issueLabel!.trim() : '$categoryLabel support request';
    return label.runes.length < 5 ? 'TourFlow · $label' : label;
  }
  String get generatedDescription {
    final details = additionalDetails?.trim();
    final summary = '$categoryLabel — $generatedSubject';
    if (details == null || details.isEmpty) return summary;
    return '$summary\n\n$details';
  }

  factory SupportTicketDraft.fromMap(Map<String, dynamic> map) {
    final options = map['bookingOptions'];
    return SupportTicketDraft(
      category: _nullableString(map['category']),
      issueType: _nullableString(map['issueType']),
      issueLabel: _nullableString(map['issueLabel']),
      bookingId: _nullableString(map['bookingId']),
      bookingCode: _nullableString(map['bookingCode']),
      attractionId: _nullableString(map['attractionId']),
      attractionName: _nullableString(map['attractionName']),
      bookingNotApplicable: map['bookingNotApplicable'] == true,
      additionalDetails: _nullableString(map['additionalDetails']),
      additionalDetailsComplete: map['additionalDetailsComplete'] == true,
      missingFields: (map['missingFields'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      bookingOptions: (options as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ComplaintBookingOption.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class SupportAttractionOption {
  const SupportAttractionOption({required this.id, required this.name});

  final String id;
  final String name;

  factory SupportAttractionOption.fromMap(Map<String, dynamic> map) =>
      SupportAttractionOption(
        id: map['id'] as String,
        name: map['name'] as String,
      );
}

class SupportBookingOption {
  const SupportBookingOption({
    required this.id,
    required this.code,
    required this.attractionId,
    required this.attractionName,
    required this.startsAt,
  });

  final String id;
  final String code;
  final String attractionId;
  final String attractionName;
  final DateTime startsAt;

  factory SupportBookingOption.fromMap(Map<String, dynamic> map) {
    final option = SupportBookingOption.tryFromMap(map);
    if (option == null) {
      throw const FormatException(
        'The booking is missing its time slot or attraction details.',
      );
    }
    return option;
  }

  static SupportBookingOption? tryFromMap(Map<String, dynamic> map) {
    final rawSlot = map['slot'];
    if (rawSlot is! Map) return null;
    final slot = Map<String, dynamic>.from(rawSlot);
    final rawAttraction = slot['attraction'];
    if (rawAttraction is! Map) return null;
    final attraction = Map<String, dynamic>.from(rawAttraction);

    final id = map['id']?.toString().trim() ?? '';
    final code = map['booking_code']?.toString().trim() ?? '';
    final attractionId = attraction['id']?.toString().trim() ?? '';
    final attractionName = attraction['name']?.toString().trim() ?? '';
    final startsAt = DateTime.tryParse(slot['starts_at']?.toString() ?? '');
    if (id.isEmpty ||
        code.isEmpty ||
        attractionId.isEmpty ||
        attractionName.isEmpty ||
        startsAt == null) {
      return null;
    }

    return SupportBookingOption(
      id: id,
      code: code,
      attractionId: attractionId,
      attractionName: attractionName,
      startsAt: startsAt.toLocal(),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.code,
    required this.requesterName,
    required this.attractionName,
    required this.category,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.submissionLanguage,
    required this.createdAt,
    required this.updatedAt,
    this.bookingCode,
    this.assignedTo,
    this.resolvedAt,
    this.issueType,
    this.handlerType = 'admin',
  });

  final String id;
  final String code;
  final String requesterName;
  final String attractionName;
  final String? bookingCode;
  final String category;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String? submissionLanguage;
  final String? assignedTo;
  final String? issueType;
  final String handlerType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  String get categoryLabel => supportTicketCategoryLabel(category);
  String get statusLabel => supportTicketStatusLabel(status);
  String get priorityLabel => _titleCase(priority);
  String get submissionLanguageLabel =>
      supportTicketSubmissionLanguageLabel(submissionLanguage);

  factory SupportTicket.fromMap(Map<String, dynamic> map) => SupportTicket(
    id: map['id'] as String,
    code: map['ticket_code'] as String,
    requesterName: map['requester_name'] as String? ?? 'Tourist',
    attractionName: map['attraction_name'] as String? ?? 'TourFlow App',
    bookingCode: _nullableString(map['booking_code']),
    category: map['category'] as String? ?? 'other',
    subject: map['subject'] as String? ?? 'Support request',
    description: map['description'] as String? ?? '',
    priority: map['priority'] as String? ?? 'normal',
    status: map['status'] as String? ?? 'pending',
    submissionLanguage: _nullableString(map['submission_language']),
    assignedTo: _nullableString(map['assigned_to']),
    issueType: _nullableString(map['issue_type']),
    handlerType: map['handler_type'] as String? ?? 'admin',
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    resolvedAt: _optionalDateTime(map['resolved_at']),
  );
}

class SupportTicketEvent {
  const SupportTicketEvent({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.eventType,
    required this.createdAt,
    this.message,
    this.fromStatus,
    this.toStatus,
  });

  final String id;
  final String actorName;
  final String actorRole;
  final String eventType;
  final String? message;
  final String? fromStatus;
  final String? toStatus;
  final DateTime createdAt;

  factory SupportTicketEvent.fromMap(Map<String, dynamic> map) =>
      SupportTicketEvent(
        id: map['id'] as String,
        actorName: map['actor_name'] as String? ?? 'TourFlow',
        actorRole: map['actor_role'] as String? ?? 'system',
        eventType: map['event_type'] as String? ?? 'reply',
        message: _nullableString(map['message']),
        fromStatus: _nullableString(map['from_status']),
        toStatus: _nullableString(map['to_status']),
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

class SupportTicketAttachment {
  const SupportTicketAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.signedUrl,
    this.storageBucket = 'support-ticket-attachments',
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
  final String signedUrl;
  final String storageBucket;
}

class SupportTicketDetailsData {
  const SupportTicketDetailsData({
    required this.ticket,
    required this.events,
    required this.attachments,
  });

  final SupportTicket ticket;
  final List<SupportTicketEvent> events;
  final List<SupportTicketAttachment> attachments;
}

class TicketCreationResult {
  const TicketCreationResult({
    required this.id,
    required this.code,
    required this.status,
    required this.confirmationMessage,
    this.attachmentWarning,
  });

  final String id;
  final String code;
  final String status;
  final String confirmationMessage;
  final String? attachmentWarning;
}

class TicketDeletionResult {
  const TicketDeletionResult({this.cleanupWarning});

  final String? cleanupWarning;
}

String supportTicketCategoryLabel(String? value) => switch (value) {
  'booking' => 'Booking',
  'account_profile' => 'Account & Profile',
  'payment_refund' => 'Payment & Refund',
  'qr_check_in' => 'QR & Check-in',
  'technical' => 'Technical Problem',
  'overcrowding' => 'Overcrowding',
  'facility_damage' => 'Facility Damage',
  'safety' => 'Safety Concern',
  'staff_service' => 'Staff Service',
  _ => 'Other',
};

String supportTicketStatusLabel(String? value) => switch (value) {
  'in_progress' => 'In Progress',
  'resolved' => 'Resolved',
  'closed' => 'Closed',
  _ => 'Pending',
};

String supportTicketSubmissionLanguageLabel(String? value) {
  final normalized = value?.trim().toLowerCase();
  return switch (normalized) {
    'en' || 'english' => 'English',
    'ms' || 'bm' || 'bahasa malaysia' => 'Bahasa Malaysia',
    'zh' ||
    'zh-cn' ||
    'mandarin' ||
    'chinese' ||
    '中文' ||
    '简体中文' => '中文 (Mandarin)',
    'ja' || 'jp' || 'japanese' || '日本語' => '日本語 (Japanese)',
    'ko' || 'kr' || 'korean' || '한국어' => '한국어 (Korean)',
    _ => value?.trim().isNotEmpty == true ? value!.trim() : 'Unknown',
  };
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _optionalDateTime(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty
      ? null
      : DateTime.tryParse(text)?.toLocal();
}
