enum ChatBookingOperation { create, reschedule, cancel }

ChatBookingOperation _bookingOperation(Object? value) {
  return switch (value?.toString()) {
    'reschedule' => ChatBookingOperation.reschedule,
    'cancel' => ChatBookingOperation.cancel,
    _ => ChatBookingOperation.create,
  };
}

class ChatBookingAttractionOption {
  const ChatBookingAttractionOption({
    required this.id,
    required this.name,
    required this.isBookable,
  });

  final String id;
  final String name;
  final bool isBookable;

  factory ChatBookingAttractionOption.fromMap(Map<String, dynamic> map) =>
      ChatBookingAttractionOption(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Attraction',
        // Keep compatibility with an older Edge Function response while the
        // updated function is being deployed.
        isBookable: map['isBookable'] != false,
      );
}

class ChatBookingSlotOption {
  const ChatBookingSlotOption({
    required this.id,
    required this.attractionId,
    required this.attractionName,
    required this.startsAt,
    required this.endsAt,
    required this.remainingCapacity,
  });

  final String id;
  final String attractionId;
  final String attractionName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int remainingCapacity;

  factory ChatBookingSlotOption.fromMap(Map<String, dynamic> map) =>
      ChatBookingSlotOption(
        id: map['id']?.toString() ?? '',
        attractionId: map['attractionId']?.toString() ?? '',
        attractionName: map['attractionName']?.toString() ?? 'Attraction',
        startsAt: DateTime.parse(map['startsAt'] as String).toLocal(),
        endsAt: DateTime.parse(map['endsAt'] as String).toLocal(),
        remainingCapacity: _intValue(map['remainingCapacity']),
      );
}

class ChatBookingOption {
  const ChatBookingOption({
    required this.id,
    required this.code,
    required this.attractionId,
    required this.attractionName,
    required this.slotId,
    required this.startsAt,
    required this.endsAt,
    required this.visitorCount,
    required this.status,
  });

  final String id;
  final String code;
  final String attractionId;
  final String attractionName;
  final String slotId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int visitorCount;
  final String status;

  factory ChatBookingOption.fromMap(Map<String, dynamic> map) =>
      ChatBookingOption(
        id: map['id']?.toString() ?? '',
        code: map['code']?.toString() ?? '',
        attractionId: map['attractionId']?.toString() ?? '',
        attractionName: map['attractionName']?.toString() ?? 'Attraction',
        slotId: map['slotId']?.toString() ?? '',
        startsAt: DateTime.parse(map['startsAt'] as String).toLocal(),
        endsAt: DateTime.parse(map['endsAt'] as String).toLocal(),
        visitorCount: _intValue(map['visitorCount']),
        status: map['status']?.toString() ?? '',
      );
}

class ChatBookingDraft {
  const ChatBookingDraft({
    required this.operation,
    required this.attractionId,
    required this.attractionName,
    required this.bookingId,
    required this.bookingCode,
    required this.slotId,
    required this.slotStartsAt,
    required this.slotEndsAt,
    required this.visitorCount,
    required this.missingFields,
    required this.attractionOptions,
    required this.slotOptions,
    required this.bookingOptions,
  });

  final ChatBookingOperation operation;
  final String? attractionId;
  final String? attractionName;
  final String? bookingId;
  final String? bookingCode;
  final String? slotId;
  final DateTime? slotStartsAt;
  final DateTime? slotEndsAt;
  final int? visitorCount;
  final List<String> missingFields;
  final List<ChatBookingAttractionOption> attractionOptions;
  final List<ChatBookingSlotOption> slotOptions;
  final List<ChatBookingOption> bookingOptions;

  bool get readyForConfirmation => missingFields.isEmpty;

  bool get canGoBack => switch (operation) {
    ChatBookingOperation.create => attractionId != null,
    ChatBookingOperation.reschedule ||
    ChatBookingOperation.cancel => bookingId != null,
  };

  factory ChatBookingDraft.fromMap(Map<String, dynamic> map) {
    return ChatBookingDraft(
      operation: _bookingOperation(map['operation']),
      attractionId: _nullableString(map['attractionId']),
      attractionName: _nullableString(map['attractionName']),
      bookingId: _nullableString(map['bookingId']),
      bookingCode: _nullableString(map['bookingCode']),
      slotId: _nullableString(map['slotId']),
      slotStartsAt: _optionalDateTime(map['slotStartsAt']),
      slotEndsAt: _optionalDateTime(map['slotEndsAt']),
      visitorCount: map['visitorCount'] == null
          ? null
          : _intValue(map['visitorCount']),
      missingFields: (map['missingFields'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      attractionOptions: _maps(map['attractionOptions'])
          .map(ChatBookingAttractionOption.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      slotOptions: _maps(map['slotOptions'])
          .map(ChatBookingSlotOption.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      bookingOptions: _maps(map['bookingOptions'])
          .map(ChatBookingOption.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }
}

List<Map<String, dynamic>> _maps(Object? value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _optionalDateTime(Object? value) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text)?.toLocal();
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

const int maxChatBookingVisitors = 6;

int chatBookingVisitorLimit(int remainingCapacity) {
  if (remainingCapacity <= 0) return 0;
  return remainingCapacity < maxChatBookingVisitors
      ? remainingCapacity
      : maxChatBookingVisitors;
}
