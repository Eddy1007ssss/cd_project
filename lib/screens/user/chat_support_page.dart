import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat_booking_models.dart';
import '../../models/chat_models.dart';
import '../../models/module3_models.dart';
import '../../models/support_ticket_models.dart';
import '../../repositories/module3_repository.dart';
import '../../services/gemini_chat_service.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/chat_booking_cards.dart';
import '../../widgets/navigation/user_sidebar.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'attraction_discovery_page.dart';
import 'chat_history_page.dart';
import 'language_settings_page.dart';
import 'support_ticket_form_page.dart';
import 'support_ticket_list_page.dart';

class ChatSupportPage extends StatefulWidget {
  const ChatSupportPage({this.conversationId, super.key});

  static const routeName = TourFlowRoutes.userChat;

  final String? conversationId;

  @override
  State<ChatSupportPage> createState() => _ChatSupportPageState();
}

class _ChatSupportPageState extends State<ChatSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiChatService _chatService = GeminiChatService();
  final SupportTicketService _ticketService = SupportTicketService();
  final Module3Repository _bookingRepository = Module3Repository();
  final ImagePicker _imagePicker = ImagePicker();

  final List<_ChatMessage> _messages = [];

  String? _conversationId;
  String _displayName = 'Tourist';
  String _email = '';
  String _language = 'English';
  ComplaintDraft? _complaintDraft;
  ChatBookingDraft? _bookingDraft;
  ComplaintPhoto? _complaintPhoto;
  List<SupportAttractionOption> _complaintAttractions = const [];
  List<SupportBookingOption> _complaintBookings = const [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isChoosingComplaintDraft = false;
  bool _isLoadingComplaintOptions = false;
  bool _isSubmittingComplaint = false;
  bool _isSubmittingBookingAction = false;
  String? _loadError;
  String? _complaintOptionsError;

  static const _quickQuestions = [
    'Available attractions',
    'Live crowd status',
    'Opening hours',
    'Transportation help',
  ];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _loadConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final userContext = await _chatService.getCurrentUserContext();
      final storedMessages = _conversationId == null
          ? const <ChatMessage>[]
          : await _chatService.getMessages(_conversationId!);
      final complaintDraft = _conversationId == null
          ? null
          : await _chatService.getComplaintDraft(_conversationId!);
      final bookingDraft = _conversationId == null
          ? null
          : await _chatService.getBookingDraft(_conversationId!);

      if (!mounted) return;
      setState(() {
        _displayName = userContext.displayName;
        _email = userContext.email;
        _language = userContext.languageName;
        _complaintDraft = complaintDraft;
        _bookingDraft = bookingDraft;
        _complaintPhoto = null;
        _messages
          ..clear()
          ..addAll(
            storedMessages.map(
              (message) => _ChatMessage.fromStored(
                message,
                language: userContext.languageName,
              ),
            ),
          );
        if (_messages.isEmpty) {
          _messages.add(_welcomeMessage());
        }
        _isLoading = false;
      });
      if (complaintDraft != null) {
        await _loadComplaintOptions();
      }
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = _friendlyError(error);
      });
    }
  }

  Future<void> _loadComplaintOptions() async {
    if (_complaintDraft == null) return;
    setState(() {
      _isLoadingComplaintOptions = true;
      _complaintOptionsError = null;
    });

    try {
      final attractionsFuture = _ticketService.fetchApprovedAttractions();
      final bookingsFuture = _ticketService.fetchMyBookings();
      final attractions = await attractionsFuture;
      final bookings = await bookingsFuture;
      if (!mounted || _complaintDraft == null) return;
      setState(() {
        _complaintAttractions = attractions;
        _complaintBookings = bookings;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _complaintOptionsError = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoadingComplaintOptions = false);
    }
  }

  Future<void> _beginGuidedComplaint([String? displayText]) async {
    if (_isSending ||
        _isChoosingComplaintDraft ||
        _isSubmittingComplaint ||
        _isSubmittingBookingAction ||
        _isLoading) {
      return;
    }
    final shouldStart = await _chooseComplaintDraftOrNew();
    if (!mounted || !shouldStart) return;
    final copy = _ComplaintGuideCopy(_language);
    await _applyComplaintAction(
      type: 'start',
      displayText: displayText ?? copy.startComplaint,
    );
  }

  Future<bool> _applyComplaintAction({
    required String type,
    required String displayText,
    String? value,
  }) async {
    if (_isSending ||
        _isSubmittingComplaint ||
        _isSubmittingBookingAction ||
        _isLoading) {
      return false;
    }

    var succeeded = false;

    setState(() {
      _messages.add(
        _ChatMessage(text: displayText, isUser: true, time: _currentTime()),
      );
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final complaintAction = <String, dynamic>{'type': type};
      if (value != null) {
        complaintAction['value'] = value;
      }
      final response = await _chatService.sendMessage(
        message: displayText,
        language: _language,
        conversationId: _conversationId,
        complaintAction: complaintAction,
      );
      if (!mounted) return false;

      final needsOptions =
          response.complaintDraft != null &&
          _complaintAttractions.isEmpty &&
          !_isLoadingComplaintOptions;
      setState(() {
        _conversationId = response.conversationId;
        _complaintDraft = response.complaintDraft;
        _bookingDraft = null;
        if (response.complaintDraft?.requiresPhoto != true) {
          _complaintPhoto = null;
        }
        if (response.complaintDraft == null) {
          _complaintAttractions = const [];
          _complaintBookings = const [];
          _complaintOptionsError = null;
        }
        _messages.add(
          _ChatMessage(
            text: response.reply,
            isUser: false,
            time: _currentTime(),
          ),
        );
      });
      if (needsOptions) await _loadComplaintOptions();
      succeeded = true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: _friendlyError(error),
            isUser: false,
            time: _currentTime(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
    return succeeded;
  }

  Future<void> _beginBookingAction(
    ChatBookingOperation operation, [
    String? displayText,
  ]) async {
    if (_isSending ||
        _isChoosingComplaintDraft ||
        _isSubmittingComplaint ||
        _isSubmittingBookingAction ||
        _isLoading) {
      return;
    }
    final copy = ChatBookingCopy(_language);
    final actionType = switch (operation) {
      ChatBookingOperation.create => 'start_create',
      ChatBookingOperation.reschedule => 'start_reschedule',
      ChatBookingOperation.cancel => 'start_cancel',
    };
    final defaultText = switch (operation) {
      ChatBookingOperation.create => copy.createBooking,
      ChatBookingOperation.reschedule => copy.rescheduleBooking,
      ChatBookingOperation.cancel => copy.cancelBooking,
    };
    await _applyBookingAction(
      type: actionType,
      displayText: displayText ?? defaultText,
    );
  }

  Future<bool> _applyBookingAction({
    required String type,
    required String displayText,
    String? value,
    bool showError = true,
  }) async {
    if (_isSending || _isSubmittingComplaint || _isLoading) return false;

    var succeeded = false;
    setState(() {
      _messages.add(
        _ChatMessage(text: displayText, isUser: true, time: _currentTime()),
      );
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final bookingAction = <String, dynamic>{'type': type};
      if (value != null) bookingAction['value'] = value;
      final response = await _chatService.sendMessage(
        message: displayText,
        language: _language,
        conversationId: _conversationId,
        bookingAction: bookingAction,
      );
      if (!mounted) return false;

      setState(() {
        _conversationId = response.conversationId;
        _complaintDraft = null;
        _complaintPhoto = null;
        _complaintAttractions = const [];
        _complaintBookings = const [];
        _bookingDraft = response.bookingDraft;
        _messages.add(
          _ChatMessage(
            text: response.reply,
            isUser: false,
            time: _currentTime(),
          ),
        );
      });
      succeeded = true;
    } catch (error) {
      if (!mounted) return false;
      if (showError) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: _friendlyError(error),
              isUser: false,
              time: _currentTime(),
              isError: true,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
    return succeeded;
  }

  Future<void> _completeBookingAction() async {
    final draft = _bookingDraft;
    final conversationId = _conversationId;
    if (draft == null ||
        conversationId == null ||
        !draft.readyForConfirmation ||
        _isSubmittingBookingAction) {
      return;
    }

    setState(() => _isSubmittingBookingAction = true);
    try {
      final TourBooking booking = switch (draft.operation) {
        ChatBookingOperation.create => await _bookingRepository.createBooking(
          slotId: draft.slotId!,
          visitors: draft.visitorCount!,
        ),
        ChatBookingOperation.reschedule =>
          await _bookingRepository.rescheduleBooking(
            bookingId: draft.bookingId!,
            newSlotId: draft.slotId!,
          ),
        ChatBookingOperation.cancel => await _bookingRepository.cancelBooking(
          draft.bookingId!,
        ),
      };
      if (!mounted) return;

      final copy = ChatBookingCopy(_language);
      final confirmationLabel = switch (draft.operation) {
        ChatBookingOperation.create => copy.confirmBooking,
        ChatBookingOperation.reschedule => copy.confirmReschedule,
        ChatBookingOperation.cancel => copy.confirmCancellation,
      };
      final recorded = await _applyBookingAction(
        type: 'complete',
        value: booking.id,
        displayText: confirmationLabel,
        showError: false,
      );
      if (!mounted || recorded) return;

      // The booking RPC has already succeeded. Clear only the stale chat draft
      // and show a verified local confirmation instead of retrying the booking.
      try {
        await _chatService.clearBookingDraft(conversationId);
      } catch (_) {
        // Starting another booking action replaces a stale draft safely.
      }
      if (!mounted) return;
      setState(() {
        _bookingDraft = null;
        _messages.add(
          _ChatMessage(
            text: copy.completionFallback(draft.operation, booking.bookingCode),
            isUser: false,
            time: _currentTime(),
          ),
        );
      });
      _showMessage(
        'The booking succeeded, but the chat history confirmation could not be saved.',
      );
    } catch (error) {
      if (mounted) _showMessage(bookingErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmittingBookingAction = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _enterCustomComplaintIssue() async {
    final copy = _ComplaintGuideCopy(_language);
    final value = await _showComplaintTextDialog(
      title: copy.customIssueTitle,
      hint: copy.customIssueHint,
      minimumLength: 10,
      minimumLengthMessage: copy.customIssueMinimum,
    );
    if (!mounted || value == null) return;
    await _applyComplaintAction(
      type: 'set_custom_issue',
      value: value,
      displayText: copy.customIssueMessage(value),
    );
  }

  Future<void> _enterAdditionalComplaintDetails() async {
    final copy = _ComplaintGuideCopy(_language);
    final value = await _showComplaintTextDialog(
      title: copy.additionalDetailsTitle,
      hint: copy.additionalDetailsHint,
      minimumLength: 3,
      minimumLengthMessage: copy.additionalDetailsMinimum,
    );
    if (!mounted || value == null) return;
    await _applyComplaintAction(
      type: 'set_additional_details',
      value: value,
      displayText: copy.additionalDetailsMessage(value),
    );
  }

  Future<String?> _showComplaintTextDialog({
    required String title,
    required String hint,
    required int minimumLength,
    required String minimumLengthMessage,
  }) async {
    final copy = _ComplaintGuideCopy(_language);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ComplaintTextDialog(
        title: title,
        hint: hint,
        minimumLength: minimumLength,
        minimumLengthMessage: minimumLengthMessage,
        cancelLabel: copy.dialogCancel,
        saveLabel: copy.dialogSave,
      ),
    );
    if (!mounted) return null;

    // Let the dialog route finish the current teardown frame before the
    // complaint response replaces the guide card underneath it.
    await WidgetsBinding.instance.endOfFrame;
    return mounted ? result : null;
  }

  Future<void> _sendMessage([String? quickQuestion]) async {
    final value = (quickQuestion ?? _messageController.text).trim();
    if (value.isEmpty ||
        _isSending ||
        _isChoosingComplaintDraft ||
        _isSubmittingComplaint ||
        _isSubmittingBookingAction ||
        _isLoading) {
      return;
    }

    final startsComplaint = _isComplaintStartRequest(value);
    final bookingIntent = _bookingActionIntent(value);
    if (_shouldOfferComplaintDraftChoice(value)) {
      final shouldSend = await _chooseComplaintDraftOrNew();
      if (!mounted || !shouldSend) return;
    }

    if (startsComplaint) {
      await _applyComplaintAction(type: 'start', displayText: value);
      return;
    }
    if (bookingIntent != null) {
      await _beginBookingAction(bookingIntent, value);
      return;
    }

    final time = _currentTime();

    setState(() {
      _messages.add(_ChatMessage(text: value, isUser: true, time: time));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        message: value,
        language: _language,
        conversationId: _conversationId,
      );

      if (!mounted) return;

      setState(() {
        _conversationId = response.conversationId;
        _complaintDraft = response.complaintDraft;
        _bookingDraft = response.bookingDraft;
        if (response.complaintDraft?.requiresPhoto != true) {
          _complaintPhoto = null;
        }
        _messages.add(
          _ChatMessage(
            text: response.reply,
            isUser: false,
            time: _currentTime(),
          ),
        );
      });
      if (response.complaintDraft != null &&
          _complaintAttractions.isEmpty &&
          !_isLoadingComplaintOptions) {
        await _loadComplaintOptions();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: _friendlyError(error),
            isUser: false,
            time: _currentTime(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  Future<bool> _chooseComplaintDraftOrNew() async {
    setState(() => _isChoosingComplaintDraft = true);

    late final List<ComplaintDraftConversation> drafts;
    try {
      drafts = await _chatService.getComplaintDrafts();
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
      return false;
    } finally {
      if (mounted) setState(() => _isChoosingComplaintDraft = false);
    }

    if (!mounted) return false;
    if (drafts.isEmpty) return true;

    final copy = _ComplaintDraftPickerCopy.forLanguage(_language);
    final choice = await showDialog<_ComplaintDraftChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.edit_note_rounded,
          color: TourFlowColors.primaryText,
          size: 38,
        ),
        title: TourFlowText(copy.title),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TourFlowText(copy.description(drafts.length)),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = drafts[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: TourFlowColors.border),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF3C4),
                          child: Icon(
                            Icons.description_outlined,
                            color: TourFlowColors.primaryText,
                          ),
                        ),
                        title: TourFlowText(
                          item.draft.attractionName ?? copy.unnamedAttraction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: TourFlowText(
                          copy.draftSubtitle(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(
                          dialogContext,
                          _ComplaintDraftChoice.resume(item),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: TourFlowText(copy.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              const _ComplaintDraftChoice.newComplaint(),
            ),
            icon: const Icon(Icons.add_rounded),
            label: TourFlowText(copy.newComplaint),
          ),
        ],
      ),
    );

    if (!mounted || choice == null) return false;
    final selectedDraft = choice.draft;
    if (selectedDraft != null) {
      _messageController.clear();
      await _openComplaintDraft(selectedDraft, copy);
      return false;
    }

    _startNewConversation();
    return true;
  }

  Future<void> _openComplaintDraft(
    ComplaintDraftConversation selected,
    _ComplaintDraftPickerCopy copy,
  ) async {
    if (_conversationId == selected.conversationId) {
      setState(() {
        _complaintDraft = selected.draft;
        _complaintPhoto = null;
      });
      await _loadComplaintOptions();
      _scrollToBottom();
    } else {
      setState(() {
        _conversationId = selected.conversationId;
        _complaintDraft = selected.draft;
        _complaintPhoto = null;
      });
      await _loadConversation();
    }

    if (mounted) _showMessage(copy.draftOpened);
  }

  bool _isComplaintStartRequest(String message) {
    final value = message.trim().toLowerCase();
    if (const {
      'complaint',
      'complain',
      '投诉',
      '抱怨',
      'aduan',
      '苦情',
      '불만',
    }.contains(value)) {
      return true;
    }

    return RegExp(
      r'(i\s+(?:want|need|would\s+like)\s+to\s+(?:complain|make\s+a\s+complaint)|'
      r'i\s+have\s+a\s+complaint|(?:start|make|file|submit|create)\s+(?:a\s+)?(?:new\s+)?complaint|'
      r'new\s+complaint|我要投诉|我想投诉|想要投诉|需要投诉|我要抱怨|我想抱怨|'
      r'再投诉|新的投诉|新投诉|另一个投诉|开始投诉|'
      r'(?:mahu|nak|ingin)\s+(?:buat|membuat)?\s*aduan|aduan\s+baru|'
      r'苦情を申し立てたい|クレームしたい|新しい苦情|'
      r'불만을\s*(?:제기|신고)하고\s*싶|새로운\s*불만)',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(value);
  }

  ChatBookingOperation? _bookingActionIntent(String message) {
    final value = message.trim().toLowerCase();
    if (RegExp(
      r'(cancel\s+(?:my\s+|a\s+)?booking|cancel\s+(?:my\s+)?reservation|'
      r'取消(?:我的)?预订|取消(?:我的)?booking|取消预约|'
      r'batalkan\s+tempahan|予約をキャンセル|예약을?\s*취소)',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(value)) {
      return ChatBookingOperation.cancel;
    }
    if (RegExp(
      r'(reschedule\s+(?:my\s+|a\s+)?booking|change\s+(?:my\s+)?booking\s+(?:time|date|slot)|'
      r'(?:更改|修改|换|改)(?:我的)?(?:预订|booking)(?:时间|日期|时段)?|预订改期|'
      r'(?:tukar|ubah)\s+(?:masa\s+)?tempahan|予約(?:時間|日時)?を変更|예약\s*(?:시간|날짜|일정)?\s*변경)',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(value)) {
      return ChatBookingOperation.reschedule;
    }
    if (RegExp(
      r'(book\s+(?:an?\s+)?(?:attraction|slot|visit|ticket)|make\s+(?:a\s+)?booking|'
      r'i\s+(?:want|need|would\s+like)\s+to\s+book|'
      r'(?:我要|我想|想要|帮我)(?:做|建立|新建)?\s*(?:booking|预订|预约|订票)(?:景点|时段)?|新(?:建|增)?预订|'
      r'(?:mahu|nak|ingin)\s+tempah|buat\s+tempahan|'
      r'予約(?:したい|を作成)|예약(?:하고\s*싶|하기))',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(value)) {
      return ChatBookingOperation.create;
    }
    return null;
  }

  bool _shouldOfferComplaintDraftChoice(String message) {
    if (_isComplaintStartRequest(message)) return true;

    // While a draft is already open, issue details such as "too crowded" are
    // treated as answers for that draft. In a normal chat, the same phrases
    // can begin a complaint, so existing drafts must be offered first.
    if (_complaintDraft != null) return false;
    return RegExp(
      r'(bad\s+experience|not\s+satisfied|terrible|too\s+crowded|overcrowd|'
      r'queue\s+(?:is\s+)?too\s+long|broken|damaged|not\s+working|dirty|unsafe|rude\s+staff|'
      r'不满意|体验很差|服务很差|态度很差|太拥挤|太挤|拥挤|排队太久|损坏|坏了|故障|很脏|安全问题|'
      r'tidak\s+puas|pengalaman\s+buruk|terlalu\s+sesak|sesak|barisan\s+panjang|rosak|kotor|tidak\s+selamat|'
      r'不満|対応が悪|混雑|行列|壊れ|汚い|危険|'
      r'만족하지|서비스가\s+나쁘|혼잡|줄이\s+너무\s+길|고장|더럽|위험)',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(message);
  }

  Future<void> _openLanguageSettings() async {
    final result = await Navigator.pushNamed(
      context,
      LanguageSettingsPage.routeName,
    );
    if (!mounted || result is! String || result.isEmpty) return;

    if (result == _language) return;

    setState(() {
      _language = result;
      _messages.add(
        _ChatMessage(
          text: _languageChangedMessage(result),
          isUser: false,
          time: _currentTime(),
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _pickComplaintPhoto() async {
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        requestFullMetadata: false,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        _showMessage('Choose an image that is 5 MB or smaller.');
        return;
      }
      final mimeType = selected.mimeType ?? _imageMimeType(selected.name);
      if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
        _showMessage('Only JPEG, PNG, and WebP images are supported.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _complaintPhoto = ComplaintPhoto(
          bytes: Uint8List.fromList(bytes),
          fileName: selected.name,
          mimeType: mimeType,
        );
      });
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    }
  }

  String _imageMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _submitComplaint() async {
    final draft = _complaintDraft;
    final conversationId = _conversationId;
    final copy = _ComplaintGuideCopy(_language);
    if (draft == null || conversationId == null || _isSubmittingComplaint) {
      return;
    }
    if (draft.requiresPhoto && _complaintPhoto == null) {
      _showMessage(
        'Choose a photo, or restart the complaint and select No Photo.',
      );
      return;
    }

    setState(() => _isSubmittingComplaint = true);
    try {
      final result = await _ticketService.createFromComplaint(
        draft: draft,
        conversationId: conversationId,
        photo: _complaintPhoto,
      );
      if (!mounted) return;
      setState(() {
        _complaintDraft = null;
        _complaintPhoto = null;
        _complaintAttractions = const [];
        _complaintBookings = const [];
        _complaintOptionsError = null;
        _messages.add(
          _ChatMessage(
            text: copy.submittedMessage(result.code),
            isUser: false,
            time: _currentTime(),
          ),
        );
      });
      _scrollToBottom();
      if (result.attachmentWarning != null) {
        _showMessage(result.attachmentWarning!);
      }
      final viewTickets = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: TourFlowColors.success,
            size: 42,
          ),
          title: const TourFlowText('Complaint submitted'),
          content: TourFlowText(copy.submittedDetails(result.code)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const TourFlowText('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const TourFlowText('View Tickets'),
            ),
          ],
        ),
      );
      if (viewTickets == true && mounted) {
        await Navigator.pushNamed(context, SupportTicketListPage.routeName);
      }
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmittingComplaint = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: TourFlowText(message)));
  }

  String _languageChangedMessage(String language) {
    return switch (language) {
      'Bahasa Malaysia' =>
        'Bahasa telah ditukar kepada Bahasa Malaysia. Semua balasan baharu akan menggunakan Bahasa Malaysia.',
      'Mandarin' => '语言已切换为中文。接下来的新回复都会使用中文。',
      'Japanese' => '言語を日本語に変更しました。これからの新しい返信は日本語で表示されます。',
      'Korean' => '언어가 한국어로 변경되었습니다. 이제부터 새로운 답변은 한국어로 표시됩니다.',
      _ => 'Language changed to English. All new replies will now use English.',
    };
  }

  Future<void> _openChatHistory() async {
    await Navigator.pushNamed(context, ChatHistoryPage.routeName);

    if (!mounted || _conversationId == null) return;

    try {
      final exists = await _chatService.conversationExists(_conversationId!);
      if (!mounted || exists) return;

      _startNewConversation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TourFlowText(
            'The previous conversation was deleted. A new conversation has been started.',
          ),
        ),
      );
    } catch (_) {
      // Keep the current page unchanged if the database check temporarily fails.
    }
  }

  void _startNewConversation() {
    if (_isSending ||
        _isChoosingComplaintDraft ||
        _isSubmittingComplaint ||
        _isSubmittingBookingAction) {
      return;
    }
    setState(() {
      _conversationId = null;
      _complaintDraft = null;
      _bookingDraft = null;
      _complaintPhoto = null;
      _complaintAttractions = const [];
      _complaintBookings = const [];
      _complaintOptionsError = null;
      _messages
        ..clear()
        ..add(_welcomeMessage());
      _loadError = null;
    });
  }

  _ChatMessage _welcomeMessage() {
    final greeting = switch (_language) {
      'Bahasa Malaysia' =>
        'Hai $_displayName! Saya pembantu TourFlow anda. Saya boleh membantu dengan tarikan, slot, tempahan, pertukaran masa, pembatalan dan tahap kesesakan.',
      'Mandarin' =>
        '你好，$_displayName！我是你的 TourFlow 助手。我可以协助查询景点和时段，也可以帮你建立、改期或取消预订。',
      'Japanese' =>
        'こんにちは、$_displayNameさん！観光地や時間枠の案内、予約の作成・時間変更・キャンセルをお手伝いします。',
      'Korean' =>
        '안녕하세요, $_displayName님! 관광지와 시간대를 안내하고 예약 생성, 시간 변경 및 취소를 도와드릴 수 있습니다.',
      _ =>
        'Hello $_displayName! I can help with attractions and available slots, and create, reschedule or cancel your bookings.',
    };

    return _ChatMessage(text: greeting, isUser: false, time: _currentTime());
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('FunctionsFetchException') ||
        message.contains('ClientFailed to fetch')) {
      return 'I could not reach the chatbot service. Check your internet connection and Supabase URL, then try again.';
    }
    return message.isEmpty
        ? 'The chatbot is temporarily unavailable. Please try again.'
        : message;
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintCopy = _ComplaintGuideCopy(_language);
    final bookingCopy = ChatBookingCopy(_language);
    return Scaffold(
      backgroundColor: TourFlowColors.background,
      drawer: UserSidebar(
        displayName: _displayName,
        email: _email,
        selectedIndex: 3,
        onLogout: () async => signOutAndReturnToSignIn(context),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TourFlowText(
              'Chatbot & Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            TourFlowText(
              'Online · $_language',
              style: const TextStyle(
                color: TourFlowColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.tr('New conversation'),
            onPressed:
                _isSending ||
                    _isChoosingComplaintDraft ||
                    _isSubmittingComplaint ||
                    _isSubmittingBookingAction
                ? null
                : _startNewConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: context.tr('Language'),
            onPressed: _openLanguageSettings,
            icon: const Icon(Icons.translate_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: context.tr('Support menu'),
            onSelected: (value) {
              if (value == 'history') {
                _openChatHistory();
              } else if (value == 'tickets') {
                Navigator.pushNamed(context, SupportTicketListPage.routeName);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded),
                  title: TourFlowText('Chat history'),
                ),
              ),
              PopupMenuItem(
                value: 'tickets',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.support_agent_rounded),
                  title: TourFlowText('My support tickets'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? _ChatLoadError(
                    message: _loadError!,
                    onRetry: _loadConversation,
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                    children: [
                      const _AssistantInfoCard(),
                      const SizedBox(height: 14),
                      ..._messages.map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MessageBubble(message: message),
                        ),
                      ),
                      if (_complaintDraft != null &&
                          !_complaintDraft!.readyForConfirmation) ...[
                        _ComplaintGuideCard(
                          draft: _complaintDraft!,
                          attractions: _complaintAttractions,
                          bookings: _complaintBookings,
                          copy: complaintCopy,
                          isLoadingOptions: _isLoadingComplaintOptions,
                          isBusy: _isSending,
                          optionsError: _complaintOptionsError,
                          onRetryOptions: _loadComplaintOptions,
                          onSelectAttraction: (option) => _applyComplaintAction(
                            type: 'select_attraction',
                            value: option.id,
                            displayText: complaintCopy.selectedAttraction(
                              option.name,
                            ),
                          ),
                          onSelectCategory: (option) => _applyComplaintAction(
                            type: 'select_category',
                            value: option.value,
                            displayText: complaintCopy.selectedCategory(
                              option.label,
                            ),
                          ),
                          onSelectBooking: (option) => _applyComplaintAction(
                            type: 'select_booking',
                            value: option.id,
                            displayText: complaintCopy.selectedBooking(
                              option.code,
                            ),
                          ),
                          onNoBooking: () => _applyComplaintAction(
                            type: 'no_booking',
                            displayText: complaintCopy.noRelatedBooking,
                          ),
                          onSelectIssue: (option) {
                            if (option.value == 'other_issue') {
                              _enterCustomComplaintIssue();
                              return;
                            }
                            _applyComplaintAction(
                              type: 'select_issue',
                              value: option.value,
                              displayText: complaintCopy.selectedIssue(
                                option.label,
                              ),
                            );
                          },
                          onAddAdditionalDetails:
                              _enterAdditionalComplaintDetails,
                          onSkipAdditionalDetails: () => _applyComplaintAction(
                            type: 'skip_additional_details',
                            displayText: complaintCopy.skipAdditionalDetails,
                          ),
                          onPhotoChoice: (wantsPhoto) async {
                            final updated = await _applyComplaintAction(
                              type: wantsPhoto ? 'photo_yes' : 'photo_no',
                              displayText: wantsPhoto
                                  ? complaintCopy.attachPhoto
                                  : complaintCopy.noPhoto,
                            );
                            if (wantsPhoto && updated && mounted) {
                              await _pickComplaintPhoto();
                            }
                          },
                          onBack: () => _applyComplaintAction(
                            type: 'back',
                            displayText: complaintCopy.backMessage,
                          ),
                          onStartOver: () => _applyComplaintAction(
                            type: 'start',
                            displayText: complaintCopy.startOver,
                          ),
                          onCancel: () => _applyComplaintAction(
                            type: 'cancel',
                            displayText: complaintCopy.cancelComplaint,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_complaintDraft?.readyForConfirmation == true) ...[
                        _ComplaintConfirmationCard(
                          draft: _complaintDraft!,
                          copy: complaintCopy,
                          photoName: _complaintPhoto?.fileName,
                          isSubmitting: _isSubmittingComplaint,
                          onPickPhoto: _pickComplaintPhoto,
                          onRemovePhoto: () =>
                              setState(() => _complaintPhoto = null),
                          onSkipPhoto: () => _applyComplaintAction(
                            type: 'photo_no',
                            displayText: complaintCopy.noPhoto,
                          ),
                          onBack: () => _applyComplaintAction(
                            type: 'back',
                            displayText: complaintCopy.backMessage,
                          ),
                          onStartOver: () => _applyComplaintAction(
                            type: 'start',
                            displayText: complaintCopy.startOver,
                          ),
                          onCancel: () => _applyComplaintAction(
                            type: 'cancel',
                            displayText: complaintCopy.cancelComplaint,
                          ),
                          onSubmit: _submitComplaint,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_bookingDraft != null &&
                          !_bookingDraft!.readyForConfirmation) ...[
                        ChatBookingGuideCard(
                          draft: _bookingDraft!,
                          copy: bookingCopy,
                          isBusy: _isSending || _isSubmittingBookingAction,
                          onSelectAttraction: (option) => _applyBookingAction(
                            type: 'select_attraction',
                            value: option.id,
                            displayText: bookingCopy.selectedAttraction(
                              option.name,
                            ),
                          ),
                          onSelectBooking: (option) => _applyBookingAction(
                            type: 'select_booking',
                            value: option.id,
                            displayText: bookingCopy.selectedBooking(
                              option.code,
                            ),
                          ),
                          onSelectSlot: (option) => _applyBookingAction(
                            type: 'select_slot',
                            value: option.id,
                            displayText: bookingCopy.selectedSlot(
                              option.startsAt,
                            ),
                          ),
                          onSelectVisitors: (count) => _applyBookingAction(
                            type: 'set_visitors',
                            value: '$count',
                            displayText: bookingCopy.selectedVisitors(count),
                          ),
                          onBack: () => _applyBookingAction(
                            type: 'back',
                            displayText: bookingCopy.backMessage,
                          ),
                          onRestart: () => _applyBookingAction(
                            type: 'restart',
                            displayText: bookingCopy.restartMessage,
                          ),
                          onCancel: () => _applyBookingAction(
                            type: 'cancel',
                            displayText: bookingCopy.stopMessage,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_bookingDraft?.readyForConfirmation == true) ...[
                        ChatBookingConfirmationCard(
                          draft: _bookingDraft!,
                          copy: bookingCopy,
                          isSubmitting: _isSubmittingBookingAction,
                          onConfirm: _completeBookingAction,
                          onBack: () => _applyBookingAction(
                            type: 'back',
                            displayText: bookingCopy.backMessage,
                          ),
                          onRestart: () => _applyBookingAction(
                            type: 'restart',
                            displayText: bookingCopy.restartMessage,
                          ),
                          onCancel: () => _applyBookingAction(
                            type: 'cancel',
                            displayText: bookingCopy.stopMessage,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_isSending ||
                          _isChoosingComplaintDraft ||
                          _isSubmittingBookingAction) ...[
                        const _TypingIndicator(),
                        const SizedBox(height: 10),
                      ],
                      if (_complaintDraft == null && _bookingDraft == null) ...[
                        const SizedBox(height: 4),
                        const TourFlowText(
                          'Quick actions',
                          style: TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              onPressed:
                                  _isSending ||
                                      _isChoosingComplaintDraft ||
                                      _isSubmittingComplaint ||
                                      _isSubmittingBookingAction
                                  ? null
                                  : _beginGuidedComplaint,
                              avatar: const Icon(
                                Icons.report_problem_outlined,
                                size: 16,
                                color: TourFlowColors.primaryText,
                              ),
                              label: TourFlowText(complaintCopy.startComplaint),
                              backgroundColor: const Color(0xFFFFF3C4),
                              side: const BorderSide(
                                color: TourFlowColors.border,
                              ),
                            ),
                            ActionChip(
                              onPressed:
                                  _isSending ||
                                      _isChoosingComplaintDraft ||
                                      _isSubmittingComplaint ||
                                      _isSubmittingBookingAction
                                  ? null
                                  : () => _beginBookingAction(
                                      ChatBookingOperation.create,
                                    ),
                              avatar: const Icon(
                                Icons.add_card_rounded,
                                size: 16,
                                color: TourFlowColors.primaryText,
                              ),
                              label: TourFlowText(bookingCopy.createBooking),
                              backgroundColor: const Color(0xFFEFF6FF),
                              side: const BorderSide(
                                color: TourFlowColors.border,
                              ),
                            ),
                            ActionChip(
                              onPressed:
                                  _isSending ||
                                      _isChoosingComplaintDraft ||
                                      _isSubmittingComplaint ||
                                      _isSubmittingBookingAction
                                  ? null
                                  : () => _beginBookingAction(
                                      ChatBookingOperation.reschedule,
                                    ),
                              avatar: const Icon(
                                Icons.edit_calendar_outlined,
                                size: 16,
                                color: TourFlowColors.primaryText,
                              ),
                              label: TourFlowText(
                                bookingCopy.rescheduleBooking,
                              ),
                              backgroundColor: const Color(0xFFEFF6FF),
                              side: const BorderSide(
                                color: TourFlowColors.border,
                              ),
                            ),
                            ActionChip(
                              onPressed:
                                  _isSending ||
                                      _isChoosingComplaintDraft ||
                                      _isSubmittingComplaint ||
                                      _isSubmittingBookingAction
                                  ? null
                                  : () => _beginBookingAction(
                                      ChatBookingOperation.cancel,
                                    ),
                              avatar: const Icon(
                                Icons.event_busy_outlined,
                                size: 16,
                                color: TourFlowColors.primaryText,
                              ),
                              label: TourFlowText(bookingCopy.cancelBooking),
                              backgroundColor: const Color(0xFFFFF1F2),
                              side: const BorderSide(
                                color: TourFlowColors.border,
                              ),
                            ),
                            ..._quickQuestions.map(
                              (question) => ActionChip(
                                onPressed:
                                    _isSending ||
                                        _isChoosingComplaintDraft ||
                                        _isSubmittingComplaint ||
                                        _isSubmittingBookingAction
                                    ? null
                                    : () => _sendMessage(question),
                                avatar: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: TourFlowColors.primaryText,
                                ),
                                label: TourFlowText(question),
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: TourFlowColors.border,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _RecommendationCard(
                          onBrowse: () => Navigator.pushNamed(
                            context,
                            AttractionDiscoveryPage.routeName,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            SupportTicketFormPage.routeName,
                          ),
                          icon: const Icon(Icons.contact_support_outlined),
                          label: const TourFlowText(
                            'Still need help? Create a support ticket',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TourFlowColors.primaryText,
                            side: const BorderSide(
                              color: TourFlowColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          _MessageComposer(
            controller: _messageController,
            onSend: _sendMessage,
            guidedComplaintActive:
                _complaintDraft != null || _bookingDraft != null,
            isSending:
                _isSending ||
                _isChoosingComplaintDraft ||
                _isSubmittingComplaint ||
                _isSubmittingBookingAction ||
                _isLoading ||
                _loadError != null,
          ),
        ],
      ),
    );
  }
}

class _ComplaintGuideCard extends StatelessWidget {
  const _ComplaintGuideCard({
    required this.draft,
    required this.attractions,
    required this.bookings,
    required this.copy,
    required this.isLoadingOptions,
    required this.isBusy,
    required this.optionsError,
    required this.onRetryOptions,
    required this.onSelectAttraction,
    required this.onSelectCategory,
    required this.onSelectBooking,
    required this.onNoBooking,
    required this.onSelectIssue,
    required this.onAddAdditionalDetails,
    required this.onSkipAdditionalDetails,
    required this.onPhotoChoice,
    required this.onBack,
    required this.onStartOver,
    required this.onCancel,
  });

  final ComplaintDraft draft;
  final List<SupportAttractionOption> attractions;
  final List<SupportBookingOption> bookings;
  final _ComplaintGuideCopy copy;
  final bool isLoadingOptions;
  final bool isBusy;
  final String? optionsError;
  final VoidCallback onRetryOptions;
  final ValueChanged<SupportAttractionOption> onSelectAttraction;
  final ValueChanged<_ComplaintGuideOption> onSelectCategory;
  final ValueChanged<SupportBookingOption> onSelectBooking;
  final VoidCallback onNoBooking;
  final ValueChanged<_ComplaintGuideOption> onSelectIssue;
  final VoidCallback onAddAdditionalDetails;
  final VoidCallback onSkipAdditionalDetails;
  final ValueChanged<bool> onPhotoChoice;
  final VoidCallback onBack;
  final VoidCallback onStartOver;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final nextField = draft.missingFields.isEmpty
        ? ''
        : draft.missingFields.first;
    final step =
        const {
          'attraction': 1,
          'category': 2,
          'booking': 3,
          'description': 4,
          'additionalDetails': 5,
          'photoChoice': 6,
        }[nextField] ??
        1;

    return ModuleCard(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFF3C4),
                foregroundColor: TourFlowColors.primaryText,
                child: Icon(Icons.report_problem_outlined, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TourFlowText(
                      copy.title,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TourFlowText(
                      copy.step(step),
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: step / 6,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: TourFlowColors.border,
            color: TourFlowColors.primary,
          ),
          const SizedBox(height: 14),
          TourFlowText(
            copy.prompt(nextField),
            style: const TextStyle(
              color: TourFlowColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildOptions(nextField),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (draft.canGoBack)
                TextButton.icon(
                  onPressed: isBusy ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: TourFlowText(copy.previousStep),
                ),
              TextButton.icon(
                onPressed: isBusy ? null : onStartOver,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: TourFlowText(copy.startOver),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : onCancel,
                icon: const Icon(Icons.close_rounded, size: 17),
                label: TourFlowText(copy.cancelComplaint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(String field) {
    if ((field == 'attraction' || field == 'booking') && isLoadingOptions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if ((field == 'attraction' || field == 'booking') && optionsError != null) {
      return _ComplaintOptionsError(
        message: optionsError!,
        retryLabel: copy.tryAgain,
        onRetry: onRetryOptions,
      );
    }

    return switch (field) {
      'attraction' => _attractionOptions(),
      'category' => _choiceWrap(copy.categoryOptions, onSelectCategory),
      'booking' => _bookingOptions(),
      'description' => _choiceWrap(
        copy.issueOptions(draft.category),
        onSelectIssue,
      ),
      'additionalDetails' => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : onAddAdditionalDetails,
            icon: const Icon(Icons.edit_note_rounded),
            label: TourFlowText(copy.addAdditionalDetails),
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onSkipAdditionalDetails,
            icon: const Icon(Icons.skip_next_rounded),
            label: TourFlowText(copy.skipAdditionalDetails),
          ),
        ],
      ),
      'photoChoice' => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: isBusy ? null : () => onPhotoChoice(true),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: TourFlowText(copy.attachPhoto),
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : () => onPhotoChoice(false),
            icon: const Icon(Icons.no_photography_outlined),
            label: TourFlowText(copy.noPhoto),
          ),
        ],
      ),
      _ => TourFlowText(copy.unavailable),
    };
  }

  Widget _attractionOptions() {
    if (attractions.isEmpty) return TourFlowText(copy.noAttractions);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: copy.attractionLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: attractions
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: TourFlowText(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isBusy
          ? null
          : (id) {
              if (id == null) return;
              final selected = attractions.firstWhere(
                (option) => option.id == id,
              );
              onSelectAttraction(selected);
            },
    );
  }

  Widget _choiceWrap(
    List<_ComplaintGuideOption> options,
    ValueChanged<_ComplaintGuideOption> onSelected,
  ) {
    if (options.isEmpty) return TourFlowText(copy.unavailable);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => OutlinedButton(
              onPressed: isBusy ? null : () => onSelected(option),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: TourFlowColors.primaryText,
                side: const BorderSide(color: TourFlowColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
              ),
              child: TourFlowText(option.label),
            ),
          )
          .toList(),
    );
  }

  Widget _bookingOptions() {
    final matching = bookings
        .where(
          (booking) =>
              draft.attractionId == null ||
              booking.attractionId == draft.attractionId,
        )
        .take(8)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...matching.map(
          (booking) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: isBusy ? null : () => onSelectBooking(booking),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                backgroundColor: Colors.white,
                foregroundColor: TourFlowColors.primaryText,
                side: const BorderSide(color: TourFlowColors.border),
                padding: const EdgeInsets.all(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TourFlowText(
                    booking.code,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  TourFlowText(
                    '${booking.attractionName} · ${_dateTime(booking.startsAt)}',
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onNoBooking,
          icon: const Icon(Icons.link_off_rounded),
          label: TourFlowText(copy.noRelatedBooking),
        ),
      ],
    );
  }

  String _dateTime(DateTime value) {
    final date =
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _ComplaintTextDialog extends StatefulWidget {
  const _ComplaintTextDialog({
    required this.title,
    required this.hint,
    required this.minimumLength,
    required this.minimumLengthMessage,
    required this.cancelLabel,
    required this.saveLabel,
  });

  final String title;
  final String hint;
  final int minimumLength;
  final String minimumLengthMessage;
  final String cancelLabel;
  final String saveLabel;

  @override
  State<_ComplaintTextDialog> createState() => _ComplaintTextDialogState();
}

class _ComplaintTextDialogState extends State<_ComplaintTextDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop();
  }

  void _save() {
    if (_isClosing || _formKey.currentState?.validate() != true) return;
    _isClosing = true;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TourFlowText(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 7,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.hint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
            validator: (rawValue) {
              final value = rawValue?.trim() ?? '';
              if (value.runes.length < widget.minimumLength) {
                return widget.minimumLengthMessage;
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: TourFlowText(widget.cancelLabel)),
        FilledButton(onPressed: _save, child: TourFlowText(widget.saveLabel)),
      ],
    );
  }
}

class _ComplaintOptionsError extends StatelessWidget {
  const _ComplaintOptionsError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TourFlowText(
        message,
        style: const TextStyle(color: TourFlowColors.danger),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: TourFlowText(retryLabel),
      ),
    ],
  );
}

class _ComplaintGuideOption {
  const _ComplaintGuideOption(this.value, this.label);

  final String value;
  final String label;
}

class _ComplaintGuideCopy {
  const _ComplaintGuideCopy(this.language);

  final String language;

  String _text({
    required String english,
    required String mandarin,
    required String bahasa,
    required String japanese,
    required String korean,
  }) => switch (language) {
    'Mandarin' => mandarin,
    'Bahasa Malaysia' => bahasa,
    'Japanese' => japanese,
    'Korean' => korean,
    _ => english,
  };

  String get title => _text(
    english: 'Create a Complaint',
    mandarin: '建立投诉',
    bahasa: 'Buat Aduan',
    japanese: '苦情を作成',
    korean: '불만 접수',
  );

  String step(int value) => _text(
    english: 'Step $value of 6',
    mandarin: '第 $value 步，共 6 步',
    bahasa: 'Langkah $value daripada 6',
    japanese: '6ステップ中$value',
    korean: '6단계 중 $value단계',
  );

  String prompt(String field) => switch (field) {
    'attraction' => _text(
      english: 'Which attraction is this complaint about?',
      mandarin: '你要投诉哪个景点？',
      bahasa: 'Aduan ini berkaitan tarikan yang mana?',
      japanese: 'どの観光地についての苦情ですか？',
      korean: '어느 관광지에 대한 불만인가요?',
    ),
    'category' => _text(
      english: 'Choose the complaint category.',
      mandarin: '请选择投诉类别。',
      bahasa: 'Pilih kategori aduan.',
      japanese: '苦情カテゴリーを選んでください。',
      korean: '불만 유형을 선택하세요.',
    ),
    'booking' => _text(
      english: 'Is there a related booking?',
      mandarin: '是否有相关的预订？',
      bahasa: 'Adakah terdapat tempahan berkaitan?',
      japanese: '関連する予約はありますか？',
      korean: '관련 예약이 있나요?',
    ),
    'description' => _text(
      english: 'Choose the issue that best matches what happened.',
      mandarin: '请选择最符合实际情况的问题。',
      bahasa: 'Pilih isu yang paling sesuai dengan perkara yang berlaku.',
      japanese: '発生した内容に最も近い問題を選んでください。',
      korean: '발생한 상황과 가장 가까운 문제를 선택하세요.',
    ),
    'additionalDetails' => _text(
      english: 'Would you like to add more details?',
      mandarin: '你需要添加补充说明吗？',
      bahasa: 'Adakah anda mahu menambah butiran lanjut?',
      japanese: '補足情報を追加しますか？',
      korean: '추가 설명을 입력하시겠습니까?',
    ),
    'photoChoice' => _text(
      english: 'Would you like to attach a photo?',
      mandarin: '你需要上传照片吗？',
      bahasa: 'Adakah anda mahu melampirkan foto?',
      japanese: '写真を添付しますか？',
      korean: '사진을 첨부하시겠습니까?',
    ),
    _ => unavailable,
  };

  String get startComplaint => _text(
    english: 'Make a Complaint',
    mandarin: '我要投诉',
    bahasa: 'Buat Aduan',
    japanese: '苦情を申し立てる',
    korean: '불만 접수',
  );
  String get attractionLabel => _text(
    english: 'Select attraction',
    mandarin: '选择景点',
    bahasa: 'Pilih tarikan',
    japanese: '観光地を選択',
    korean: '관광지 선택',
  );
  String get noRelatedBooking => _text(
    english: 'No Related Booking',
    mandarin: '没有相关预订',
    bahasa: 'Tiada Tempahan Berkaitan',
    japanese: '関連予約なし',
    korean: '관련 예약 없음',
  );
  String get attachPhoto => _text(
    english: 'Attach Photo',
    mandarin: '上传照片',
    bahasa: 'Lampirkan Foto',
    japanese: '写真を添付',
    korean: '사진 첨부',
  );
  String get noPhoto => _text(
    english: 'No Photo',
    mandarin: '不上传照片',
    bahasa: 'Tanpa Foto',
    japanese: '写真なし',
    korean: '사진 없음',
  );
  String get addAdditionalDetails => _text(
    english: 'Add Details',
    mandarin: '添加补充说明',
    bahasa: 'Tambah Butiran',
    japanese: '補足情報を追加',
    korean: '추가 설명 입력',
  );
  String get skipAdditionalDetails => _text(
    english: 'Skip',
    mandarin: '跳过',
    bahasa: 'Langkau',
    japanese: 'スキップ',
    korean: '건너뛰기',
  );
  String get customIssueTitle => _text(
    english: 'Describe the Other Issue',
    mandarin: '说明其他问题',
    bahasa: 'Terangkan Isu Lain',
    japanese: 'その他の問題を説明',
    korean: '기타 문제 설명',
  );
  String get customIssueHint => _text(
    english: 'Explain what happened...',
    mandarin: '请说明发生了什么事情……',
    bahasa: 'Terangkan perkara yang berlaku...',
    japanese: '発生した内容を説明してください…',
    korean: '발생한 상황을 설명해 주세요...',
  );
  String get customIssueMinimum => _text(
    english: 'Enter at least 10 characters.',
    mandarin: '请至少输入 10 个字符。',
    bahasa: 'Masukkan sekurang-kurangnya 10 aksara.',
    japanese: '10文字以上入力してください。',
    korean: '10자 이상 입력해 주세요.',
  );
  String get additionalDetailsTitle => _text(
    english: 'Additional Details (Optional)',
    mandarin: '补充说明（可选）',
    bahasa: 'Butiran Tambahan (Pilihan)',
    japanese: '補足情報（任意）',
    korean: '추가 설명(선택 사항)',
  );
  String get additionalDetailsHint => _text(
    english: 'Add useful information such as the time or exact location...',
    mandarin: '可补充发生时间、具体位置等资料……',
    bahasa: 'Tambah maklumat seperti masa atau lokasi tepat...',
    japanese: '時間や詳しい場所などを追加してください…',
    korean: '시간이나 정확한 위치 등의 정보를 입력하세요...',
  );
  String get additionalDetailsMinimum => _text(
    english: 'Enter at least 3 characters.',
    mandarin: '请至少输入 3 个字符。',
    bahasa: 'Masukkan sekurang-kurangnya 3 aksara.',
    japanese: '3文字以上入力してください。',
    korean: '3자 이상 입력해 주세요.',
  );
  String get dialogCancel => _text(
    english: 'Cancel',
    mandarin: '取消',
    bahasa: 'Batal',
    japanese: 'キャンセル',
    korean: '취소',
  );
  String get dialogSave => _text(
    english: 'Save',
    mandarin: '保存',
    bahasa: 'Simpan',
    japanese: '保存',
    korean: '저장',
  );
  String get cancelComplaint => _text(
    english: 'Cancel Complaint',
    mandarin: '取消投诉',
    bahasa: 'Batalkan Aduan',
    japanese: '苦情をキャンセル',
    korean: '불만 취소',
  );
  String get previousStep => _text(
    english: 'Back',
    mandarin: '返回上一步',
    bahasa: 'Kembali',
    japanese: '前のステップ',
    korean: '이전 단계',
  );
  String get backMessage => _text(
    english: 'Go back to the previous complaint step',
    mandarin: '返回上一个投诉步骤',
    bahasa: 'Kembali ke langkah aduan sebelumnya',
    japanese: '前の苦情ステップに戻る',
    korean: '이전 불만 접수 단계로 돌아가기',
  );
  String get startOver => _text(
    english: 'Start over with new selections',
    mandarin: '重新选择投诉资料',
    bahasa: 'Mulakan semula pilihan aduan',
    japanese: '選択を最初からやり直す',
    korean: '선택 다시 시작',
  );
  String get tryAgain => _text(
    english: 'Try Again',
    mandarin: '重试',
    bahasa: 'Cuba Lagi',
    japanese: '再試行',
    korean: '다시 시도',
  );
  String get noAttractions => _text(
    english: 'No approved attractions are available.',
    mandarin: '目前没有可选择的已审核景点。',
    bahasa: 'Tiada tarikan yang diluluskan tersedia.',
    japanese: '選択できる承認済み観光地がありません。',
    korean: '선택할 수 있는 승인된 관광지가 없습니다.',
  );
  String get unavailable => _text(
    english: 'This option is temporarily unavailable.',
    mandarin: '此选项暂时不可用。',
    bahasa: 'Pilihan ini tidak tersedia buat sementara waktu.',
    japanese: 'この選択肢は一時的に利用できません。',
    korean: '이 옵션은 일시적으로 사용할 수 없습니다.',
  );

  String submittedMessage(String code) => _text(
    english: 'Complaint submitted.\nTicket ID: $code\nCurrent status: Pending',
    mandarin: '投诉已提交。\n工单编号：$code\n当前状态：待处理',
    bahasa: 'Aduan telah dihantar.\nID Tiket: $code\nStatus semasa: Menunggu',
    japanese: '苦情を送信しました。\nチケットID：$code\n現在のステータス：保留中',
    korean: '불만이 제출되었습니다.\n티켓 ID: $code\n현재 상태: 대기 중',
  );

  String submittedDetails(String code) => _text(
    english: 'Ticket ID: $code\nCurrent status: Pending',
    mandarin: '工单编号：$code\n当前状态：待处理',
    bahasa: 'ID Tiket: $code\nStatus semasa: Menunggu',
    japanese: 'チケットID：$code\n現在のステータス：保留中',
    korean: '티켓 ID: $code\n현재 상태: 대기 중',
  );

  String selectedAttraction(String value) => _text(
    english: 'Attraction: $value',
    mandarin: '景点：$value',
    bahasa: 'Tarikan: $value',
    japanese: '観光地：$value',
    korean: '관광지: $value',
  );
  String selectedCategory(String value) => _text(
    english: 'Category: $value',
    mandarin: '类别：$value',
    bahasa: 'Kategori: $value',
    japanese: 'カテゴリー：$value',
    korean: '유형: $value',
  );
  String selectedBooking(String value) => _text(
    english: 'Booking: $value',
    mandarin: '预订：$value',
    bahasa: 'Tempahan: $value',
    japanese: '予約：$value',
    korean: '예약: $value',
  );
  String selectedIssue(String value) => _text(
    english: 'Issue: $value',
    mandarin: '问题：$value',
    bahasa: 'Isu: $value',
    japanese: '問題：$value',
    korean: '문제: $value',
  );
  String customIssueMessage(String value) => _text(
    english: 'Other issue: $value',
    mandarin: '其他问题：$value',
    bahasa: 'Isu lain: $value',
    japanese: 'その他の問題：$value',
    korean: '기타 문제: $value',
  );
  String additionalDetailsMessage(String value) => _text(
    english: 'Additional details: $value',
    mandarin: '补充说明：$value',
    bahasa: 'Butiran tambahan: $value',
    japanese: '補足情報：$value',
    korean: '추가 설명: $value',
  );

  List<_ComplaintGuideOption> get categoryOptions => [
    _ComplaintGuideOption(
      'overcrowding',
      _text(
        english: 'Overcrowding',
        mandarin: '过度拥挤',
        bahasa: 'Terlalu Sesak',
        japanese: '混雑',
        korean: '과밀',
      ),
    ),
    _ComplaintGuideOption(
      'facility_damage',
      _text(
        english: 'Facility Damage',
        mandarin: '设施问题',
        bahasa: 'Kerosakan Kemudahan',
        japanese: '施設の問題',
        korean: '시설 문제',
      ),
    ),
    _ComplaintGuideOption(
      'safety',
      _text(
        english: 'Safety Issue',
        mandarin: '安全问题',
        bahasa: 'Isu Keselamatan',
        japanese: '安全上の問題',
        korean: '안전 문제',
      ),
    ),
    _ComplaintGuideOption(
      'staff_service',
      _text(
        english: 'Staff Service',
        mandarin: '员工服务',
        bahasa: 'Perkhidmatan Kakitangan',
        japanese: 'スタッフ対応',
        korean: '직원 서비스',
      ),
    ),
    _ComplaintGuideOption(
      'other',
      _text(
        english: 'Other',
        mandarin: '其他',
        bahasa: 'Lain-lain',
        japanese: 'その他',
        korean: '기타',
      ),
    ),
  ];

  List<_ComplaintGuideOption> issueOptions(String? category) =>
      switch (category) {
        'overcrowding' => [
          _issue(
            'too_crowded',
            'Too crowded',
            '现场过度拥挤',
            'Terlalu sesak',
            '非常に混雑',
            '너무 혼잡함',
          ),
          _issue(
            'long_wait',
            'Long waiting time',
            '等候时间过长',
            'Masa menunggu lama',
            '待ち時間が長い',
            '대기 시간이 김',
          ),
          _issue(
            'inaccurate_crowd',
            'Inaccurate crowd information',
            '人流信息不准确',
            'Maklumat kesesakan tidak tepat',
            '混雑情報が不正確',
            '혼잡 정보가 부정확함',
          ),
          _issue(
            'poor_crowd_control',
            'Poor crowd control',
            '人流管控不足',
            'Kawalan orang ramai lemah',
            '混雑管理が不十分',
            '인파 관리 부족',
          ),
        ],
        'facility_damage' => [
          _issue(
            'damaged_facility',
            'Damaged or unusable facility',
            '设施损坏或无法使用',
            'Kemudahan rosak',
            '設備が破損・使用不可',
            '시설 파손 또는 사용 불가',
          ),
          _issue(
            'restroom_issue',
            'Restroom problem',
            '洗手间问题',
            'Masalah tandas',
            'トイレの問題',
            '화장실 문제',
          ),
          _issue(
            'cleanliness',
            'Cleanliness or maintenance problem',
            '清洁或维护问题',
            'Masalah kebersihan',
            '清掃・管理の問題',
            '청결 또는 관리 문제',
          ),
          _issue(
            'accessibility_facility',
            'Accessibility facility problem',
            '无障碍设施问题',
            'Masalah kemudahan aksesibiliti',
            'バリアフリー設備の問題',
            '접근성 시설 문제',
          ),
        ],
        'safety' => [
          _issue(
            'unsafe_environment',
            'Unsafe environment',
            '环境不安全',
            'Persekitaran tidak selamat',
            '危険な環境',
            '안전하지 않은 환경',
          ),
          _issue(
            'hazard_not_addressed',
            'Hazard not handled by staff',
            '安全隐患未被处理',
            'Bahaya tidak ditangani',
            '危険が未対応',
            '위험 요소 미처리',
          ),
          _issue(
            'emergency_exit',
            'Emergency exit or route problem',
            '紧急出口或路线问题',
            'Masalah laluan kecemasan',
            '非常口・避難経路の問題',
            '비상구 또는 대피 경로 문제',
          ),
          _issue(
            'injury_risk',
            'Possible injury risk',
            '可能导致受伤',
            'Risiko kecederaan',
            'けがの危険',
            '부상 위험',
          ),
        ],
        'staff_service' => [
          _issue(
            'unhelpful_staff',
            'Staff was not helpful',
            '工作人员没有提供帮助',
            'Kakitangan tidak membantu',
            'スタッフが非協力的',
            '직원이 도움이 되지 않음',
          ),
          _issue(
            'rude_staff',
            'Rude or unprofessional staff',
            '工作人员态度差',
            'Kakitangan kasar',
            '失礼・不適切な対応',
            '무례하거나 비전문적인 직원',
          ),
          _issue(
            'slow_service',
            'Service was too slow',
            '服务速度太慢',
            'Perkhidmatan terlalu lambat',
            '対応が遅い',
            '서비스가 너무 느림',
          ),
          _issue(
            'incorrect_information',
            'Incorrect or unclear information',
            '提供错误或不清楚的信息',
            'Maklumat salah atau tidak jelas',
            '誤った・不明確な案内',
            '부정확하거나 불명확한 정보',
          ),
        ],
        'other' => [
          _issue(
            'booking_problem',
            'Booking problem',
            '预订问题',
            'Masalah tempahan',
            '予約の問題',
            '예약 문제',
          ),
          _issue(
            'check_in_problem',
            'Check-in or QR code problem',
            '签到或二维码问题',
            'Masalah daftar masuk atau QR',
            'チェックイン・QRの問題',
            '체크인 또는 QR 문제',
          ),
          _issue(
            'inaccurate_attraction_info',
            'Inaccurate attraction information',
            '景点资料不准确',
            'Maklumat tarikan tidak tepat',
            '観光地情報が不正確',
            '관광지 정보가 부정확함',
          ),
          _issue(
            'other_issue',
            'Other — describe it',
            '其他——请自行说明',
            'Lain-lain — terangkan',
            'その他 — 内容を入力',
            '기타 — 직접 설명',
          ),
        ],
        _ => const [],
      };

  _ComplaintGuideOption _issue(
    String value,
    String english,
    String mandarin,
    String bahasa,
    String japanese,
    String korean,
  ) => _ComplaintGuideOption(
    value,
    _text(
      english: english,
      mandarin: mandarin,
      bahasa: bahasa,
      japanese: japanese,
      korean: korean,
    ),
  );
}

class _ComplaintConfirmationCard extends StatelessWidget {
  const _ComplaintConfirmationCard({
    required this.draft,
    required this.copy,
    required this.photoName,
    required this.isSubmitting,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onSkipPhoto,
    required this.onBack,
    required this.onStartOver,
    required this.onCancel,
    required this.onSubmit,
  });

  final ComplaintDraft draft;
  final _ComplaintGuideCopy copy;
  final String? photoName;
  final bool isSubmitting;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onSkipPhoto;
  final VoidCallback onBack;
  final VoidCallback onStartOver;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !isSubmitting && (!draft.requiresPhoto || photoName != null);
    return ModuleCard(
      color: const Color(0xFFFFFBEB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: TourFlowColors.primaryText,
              ),
              SizedBox(width: 9),
              Expanded(
                child: TourFlowText(
                  'Confirm your complaint',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ComplaintDetail(
            label: 'Attraction',
            value: draft.attractionName ?? 'Not selected',
          ),
          _ComplaintDetail(label: 'Category', value: draft.categoryLabel),
          _ComplaintDetail(
            label: 'Booking',
            value: draft.bookingNotApplicable
                ? 'No related booking'
                : draft.bookingCode ?? 'Not selected',
          ),
          _ComplaintDetail(
            label: 'Description',
            value: draft.description ?? '',
          ),
          _ComplaintDetail(
            label: 'Photo',
            value: draft.requiresPhoto
                ? photoName ?? 'Photo requested — please select one'
                : 'No photo required',
          ),
          if (draft.requiresPhoto) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onPickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: TourFlowText(
                    photoName == null ? 'Choose Photo' : 'Change Photo',
                  ),
                ),
                if (photoName != null)
                  TextButton.icon(
                    onPressed: isSubmitting ? null : onRemovePhoto,
                    icon: const Icon(Icons.close_rounded),
                    label: const TourFlowText('Remove'),
                  ),
                TextButton.icon(
                  onPressed: isSubmitting ? null : onSkipPhoto,
                  icon: const Icon(Icons.no_photography_outlined),
                  label: const TourFlowText('Continue Without Photo'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const TourFlowText(
            'Nothing is submitted until you press the button below.',
            style: TextStyle(color: TourFlowColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (draft.canGoBack)
                TextButton.icon(
                  onPressed: isSubmitting ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: TourFlowText(copy.previousStep),
                ),
              TextButton.icon(
                onPressed: isSubmitting ? null : onStartOver,
                icon: const Icon(Icons.restart_alt_rounded),
                label: TourFlowText(copy.startOver),
              ),
              TextButton.icon(
                onPressed: isSubmitting ? null : onCancel,
                icon: const Icon(Icons.delete_outline_rounded),
                label: TourFlowText(copy.cancelComplaint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: TourFlowText(
                isSubmitting ? 'Submitting…' : 'Submit Complaint',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintDetail extends StatelessWidget {
  const _ComplaintDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Row(
            children: [
              Flexible(
                child: TourFlowText(
                  label,
                  style: const TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Text(
                ':',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TourFlowText(
            value,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: TourFlowColors.primary,
            foregroundColor: TourFlowColors.primaryText,
            child: Icon(Icons.smart_toy_outlined, size: 16),
          ),
          SizedBox(width: 7),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  const _ChatLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: TourFlowColors.muted,
            ),
            const SizedBox(height: 12),
            TourFlowText(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const TourFlowText('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantInfoCard extends StatelessWidget {
  const _AssistantInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D3B7)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: TourFlowColors.primary,
            foregroundColor: TourFlowColors.primaryText,
            child: Icon(Icons.smart_toy_outlined),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TourFlowText(
                  'TourFlow Assistant',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                TourFlowText(
                  'Ask for general TourFlow guidance. Check the relevant page '
                  'for verified bookings, availability, prices, and live crowd data.',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 15,
              backgroundColor: TourFlowColors.primary,
              foregroundColor: TourFlowColors.primaryText,
              child: Icon(Icons.smart_toy_outlined, size: 16),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
              decoration: BoxDecoration(
                color: message.isError
                    ? const Color(0xFFFFE9E7)
                    : message.isUser
                    ? TourFlowColors.primary
                    : Colors.white,
                border: Border.all(
                  color: message.isError
                      ? TourFlowColors.danger.withValues(alpha: .35)
                      : message.isUser
                      ? TourFlowColors.primary
                      : TourFlowColors.border.withValues(alpha: .65),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: Radius.circular(message.isUser ? 15 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TourFlowText(
                    message.text,
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TourFlowText(
                    message.time,
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TourFlowColors.border.withValues(alpha: .65)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: TourFlowColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: TourFlowColors.primaryText,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TourFlowText(
                  'Need attraction suggestions?',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                TourFlowText(
                  'Browse available attractions and time slots.',
                  style: TextStyle(color: TourFlowColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onBrowse, child: const TourFlowText('Browse')),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.guidedComplaintActive,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final bool guidedComplaintActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7E2DA))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending && !guidedComplaintActive,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: context.tr(
                    guidedComplaintActive
                        ? 'Use the guided options above...'
                        : 'Ask TourFlow anything...',
                  ),
                  filled: true,
                  fillColor: TourFlowColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending || guidedComplaintActive ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
              ),
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final String time;
  final bool isError;

  factory _ChatMessage.fromStored(
    ChatMessage message, {
    required String language,
  }) {
    final hour = message.createdAt.hour.toString().padLeft(2, '0');
    final minute = message.createdAt.minute.toString().padLeft(2, '0');
    final normalized = message.content.replaceAll(r'\n', '\n');
    final ticketCode = RegExp(r'TF-\d{4}-\d+').firstMatch(normalized)?.group(0);
    final isComplaintConfirmation =
        !message.isUser &&
        ticketCode != null &&
        (normalized.contains('Complaint submitted') ||
            normalized.contains('投诉已提交') ||
            normalized.contains('Aduan telah dihantar') ||
            normalized.contains('苦情を送信しました') ||
            normalized.contains('불만이 제출되었습니다'));
    return _ChatMessage(
      text: isComplaintConfirmation
          ? _ComplaintGuideCopy(language).submittedMessage(ticketCode)
          : normalized,
      isUser: message.isUser,
      time: '$hour:$minute',
    );
  }
}

class _ComplaintDraftChoice {
  const _ComplaintDraftChoice.newComplaint() : draft = null;

  const _ComplaintDraftChoice.resume(this.draft);

  final ComplaintDraftConversation? draft;
}

class _ComplaintDraftPickerCopy {
  const _ComplaintDraftPickerCopy(this.language);

  final String language;

  factory _ComplaintDraftPickerCopy.forLanguage(String language) =>
      _ComplaintDraftPickerCopy(language);

  String get title => switch (language) {
    'Bahasa Malaysia' => 'Draf aduan ditemui',
    'Mandarin' => '发现未完成的投诉草稿',
    'Japanese' => '未完了の苦情下書きがあります',
    'Korean' => '완료되지 않은 불만 초안이 있습니다',
    _ => 'Complaint draft found',
  };

  String description(int count) => switch (language) {
    'Bahasa Malaysia' =>
      'Anda mempunyai $count draf aduan yang belum dihantar. Teruskan satu draf atau mulakan aduan baharu.',
    'Mandarin' => '你有 $count 个尚未提交的投诉草稿。请选择一个继续填写，或新建投诉。',
    'Japanese' => '未送信の苦情下書きが$count件あります。下書きを続けるか、新しい苦情を作成してください。',
    'Korean' => '제출하지 않은 불만 초안이 $count개 있습니다. 초안을 계속하거나 새 불만을 시작하세요.',
    _ =>
      'You have $count unsubmitted complaint draft${count == 1 ? '' : 's'}. Continue one or start a new complaint.',
  };

  String get cancel => switch (language) {
    'Bahasa Malaysia' => 'Batal',
    'Mandarin' => '取消',
    'Japanese' => 'キャンセル',
    'Korean' => '취소',
    _ => 'Cancel',
  };

  String get newComplaint => switch (language) {
    'Bahasa Malaysia' => 'Aduan Baharu',
    'Mandarin' => '新建投诉',
    'Japanese' => '新しい苦情',
    'Korean' => '새 불만',
    _ => 'New Complaint',
  };

  String get unnamedAttraction => switch (language) {
    'Bahasa Malaysia' => 'Tarikan belum dipilih',
    'Mandarin' => '尚未选择景点',
    'Japanese' => '観光地は未選択です',
    'Korean' => '관광지가 선택되지 않음',
    _ => 'Attraction not selected',
  };

  String get draftOpened => switch (language) {
    'Bahasa Malaysia' => 'Draf aduan dibuka. Anda boleh teruskan dari sini.',
    'Mandarin' => '已打开投诉草稿，你可以从这里继续。',
    'Japanese' => '苦情の下書きを開きました。ここから続けられます。',
    'Korean' => '불만 초안을 열었습니다. 여기에서 계속할 수 있습니다.',
    _ => 'Complaint draft opened. You can continue from here.',
  };

  String draftSubtitle(ComplaintDraftConversation item) {
    final draft = item.draft;
    final status = draft.readyForConfirmation
        ? switch (language) {
            'Bahasa Malaysia' => 'Sedia untuk disahkan',
            'Mandarin' => '可以确认提交',
            'Japanese' => '確認できます',
            'Korean' => '확인 준비 완료',
            _ => 'Ready for confirmation',
          }
        : switch (language) {
            'Bahasa Malaysia' =>
              '${draft.missingFields.length} maklumat belum lengkap',
            'Mandarin' => '还缺少 ${draft.missingFields.length} 项资料',
            'Japanese' => '${draft.missingFields.length}項目が未入力です',
            'Korean' => '${draft.missingFields.length}개 항목이 필요합니다',
            _ => '${draft.missingFields.length} item(s) still needed',
          };
    final updatedAt = item.lastMessageAt;
    final date = updatedAt == null
        ? ''
        : ' · ${updatedAt.year.toString().padLeft(4, '0')}-'
              '${updatedAt.month.toString().padLeft(2, '0')}-'
              '${updatedAt.day.toString().padLeft(2, '0')} '
              '${updatedAt.hour.toString().padLeft(2, '0')}:'
              '${updatedAt.minute.toString().padLeft(2, '0')}';
    return '${draft.categoryLabel} · $status$date';
  }
}
