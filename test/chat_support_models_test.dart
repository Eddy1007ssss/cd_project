import 'package:cd_project/models/chat_booking_models.dart';
import 'package:cd_project/models/support_ticket_models.dart';
import 'package:cd_project/services/gemini_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('short multilingual issue labels satisfy ticket text limits', () {
    final draft = SupportTicketDraft.fromMap({
      'category': 'technical', 'issueType': 'app_error', 'issueLabel': '错误',
      'additionalDetailsComplete': true, 'missingFields': <String>[],
    });
    expect(draft.generatedSubject.runes.length, greaterThanOrEqualTo(5));
    expect(draft.generatedDescription.runes.length, greaterThanOrEqualTo(10));
    expect(draft.generatedDescription, contains('错误'));
  });
  test('guided complaint draft exposes the next required field', () {
    final draft = ComplaintDraft.fromMap({
      'attractionId': 'attraction-1',
      'attractionName': 'National Museum',
      'category': 'facility_damage',
      'bookingNotApplicable': true,
      'baseDescription': 'A handrail is damaged near the entrance.',
      'additionalDetailsComplete': true,
      'description': 'A handrail is damaged near the entrance.',
      'wantsPhoto': false,
      'missingFields': <String>[],
      'bookingOptions': <Map<String, dynamic>>[],
    });

    expect(draft.readyForConfirmation, isTrue);
    expect(draft.requiresPhoto, isFalse);
    expect(draft.generatedSubject, contains('National Museum'));
  });

  test('booking draft parses edge-function option shapes', () {
    final startsAt = DateTime.utc(2026, 9, 8, 2);
    final endsAt = startsAt.add(const Duration(hours: 1));
    final draft = ChatBookingDraft.fromMap({
      'operation': 'create',
      'attractionId': 'attraction-1',
      'attractionName': 'National Museum',
      'slotId': 'slot-1',
      'slotStartsAt': startsAt.toIso8601String(),
      'slotEndsAt': endsAt.toIso8601String(),
      'visitorCount': 2,
      'missingFields': <String>[],
      'attractionOptions': [
        {'id': 'attraction-1', 'name': 'National Museum'},
      ],
      'slotOptions': [
        {
          'id': 'slot-1',
          'attractionId': 'attraction-1',
          'attractionName': 'National Museum',
          'startsAt': startsAt.toIso8601String(),
          'endsAt': endsAt.toIso8601String(),
          'remainingCapacity': 12,
        },
      ],
      'bookingOptions': <Map<String, dynamic>>[],
    });

    expect(draft.operation, ChatBookingOperation.create);
    expect(draft.readyForConfirmation, isTrue);
    expect(draft.slotOptions.single.remainingCapacity, 12);
  });

  test('supported language names round-trip to profile codes', () {
    for (final code in const ['en', 'ms', 'zh', 'ja', 'ko']) {
      expect(languageCodeFromName(languageNameFromCode(code)), code);
    }
  });

  test('chat booking visitor limit respects capacity and server maximum', () {
    expect(chatBookingVisitorLimit(0), 0);
    expect(chatBookingVisitorLimit(1), 1);
    expect(chatBookingVisitorLimit(6), 6);
    expect(chatBookingVisitorLimit(12), 6);
  });

  test('unknown support submission language remains visible to staff', () {
    expect(supportTicketSubmissionLanguageLabel('French'), 'French');
    expect(supportTicketSubmissionLanguageLabel(null), 'Unknown');
  });
}
