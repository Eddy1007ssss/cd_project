import 'package:flutter/material.dart';

import '../models/chat_booking_models.dart';
import 'tourflow_widgets.dart';

class ChatBookingCopy {
  const ChatBookingCopy(this.language);

  final String language;

  String _text({
    required String english,
    required String mandarin,
    required String malay,
    required String japanese,
    required String korean,
  }) => switch (language) {
    'Mandarin' => mandarin,
    'Bahasa Malaysia' => malay,
    'Japanese' => japanese,
    'Korean' => korean,
    _ => english,
  };

  String get createBooking => _text(
    english: 'Book an attraction',
    mandarin: '预订景点',
    malay: 'Tempah tarikan',
    japanese: '観光地を予約',
    korean: '관광지 예약',
  );

  String get rescheduleBooking => _text(
    english: 'Change booking time',
    mandarin: '更改预订时间',
    malay: 'Tukar masa tempahan',
    japanese: '予約時間を変更',
    korean: '예약 시간 변경',
  );

  String get cancelBooking => _text(
    english: 'Cancel a booking',
    mandarin: '取消预订',
    malay: 'Batalkan tempahan',
    japanese: '予約をキャンセル',
    korean: '예약 취소',
  );

  String get chooseAttraction => _text(
    english: 'Choose an attraction',
    mandarin: '选择景点',
    malay: 'Pilih tarikan',
    japanese: '観光地を選択',
    korean: '관광지 선택',
  );

  String get chooseBooking => _text(
    english: 'Choose your booking',
    mandarin: '选择你的 Booking',
    malay: 'Pilih tempahan anda',
    japanese: '予約を選択',
    korean: '예약 선택',
  );

  String get chooseSlot => _text(
    english: 'Choose a time slot',
    mandarin: '选择时段',
    malay: 'Pilih slot masa',
    japanese: '時間枠を選択',
    korean: '시간대 선택',
  );

  String get chooseVisitors => _text(
    english: 'Choose visitor count',
    mandarin: '选择游客人数',
    malay: 'Pilih bilangan pelawat',
    japanese: '訪問者数を選択',
    korean: '방문 인원 선택',
  );

  String selectedVisitorCount(int count) => _text(
    english: '$count ${count == 1 ? 'visitor' : 'visitors'} selected',
    mandarin: '已选择 $count 位游客',
    malay: '$count pelawat dipilih',
    japanese: '$count 名を選択中',
    korean: '$count명 선택됨',
  );

  String get confirmVisitorCount => _text(
    english: 'Confirm visitors',
    mandarin: '确认人数',
    malay: 'Sahkan pelawat',
    japanese: '人数を確定',
    korean: '인원 확인',
  );

  String get noAvailableAttractions => _text(
    english: 'No approved attraction currently has an available future slot.',
    mandarin: '目前没有已审核景点提供可预订的未来时段。',
    malay: 'Tiada tarikan diluluskan dengan slot masa hadapan yang tersedia.',
    japanese: '現在、予約可能な時間枠がある承認済み観光地はありません。',
    korean: '현재 예약 가능한 시간대가 있는 승인된 관광지가 없습니다.',
  );

  String get noEligibleBookings => _text(
    english: 'No upcoming confirmed booking is available for this action.',
    mandarin: '目前没有可执行此操作的未来已确认预订。',
    malay: 'Tiada tempahan akan datang yang disahkan untuk tindakan ini.',
    japanese: 'この操作が可能な今後の確定予約はありません。',
    korean: '이 작업을 수행할 수 있는 예정된 확정 예약이 없습니다.',
  );

  String get noAvailableSlots => _text(
    english: 'No suitable future slot is available. Choose another attraction or try later.',
    mandarin: '目前没有合适的未来时段。请选择其他景点或稍后再试。',
    malay: 'Tiada slot masa hadapan yang sesuai. Pilih tarikan lain atau cuba lagi nanti.',
    japanese: '利用可能な時間枠がありません。別の観光地を選ぶか、後でもう一度お試しください。',
    korean: '이용 가능한 시간대가 없습니다. 다른 관광지를 선택하거나 나중에 다시 시도하세요.',
  );

  String get noRemainingSpaces => _text(
    english: 'This time slot no longer has any spaces available. Please choose another time slot.',
    mandarin: '这个时段已经没有剩余位置，请选择其他时段。',
    malay: 'Slot masa ini sudah tiada tempat kosong. Sila pilih slot masa lain.',
    japanese: 'この時間枠には空きがありません。別の時間枠を選択してください。',
    korean: '이 시간대에는 남은 자리가 없습니다. 다른 시간대를 선택해 주세요.',
  );

  String get availableSpaces => _text(
    english: 'spaces left',
    mandarin: '个空位',
    malay: 'tempat lagi',
    japanese: '名分の空き',
    korean: '자리 남음',
  );

  String get visitors => _text(
    english: 'Visitors',
    mandarin: '游客人数',
    malay: 'Pelawat',
    japanese: '訪問者',
    korean: '방문 인원',
  );

  String get bookingId => _text(
    english: 'Booking ID',
    mandarin: '预订编号',
    malay: 'ID Tempahan',
    japanese: '予約ID',
    korean: '예약 ID',
  );

  String get attraction => _text(
    english: 'Attraction',
    mandarin: '景点',
    malay: 'Tarikan',
    japanese: '観光地',
    korean: '관광지',
  );

  String get currentTime => _text(
    english: 'Current time',
    mandarin: '当前时间',
    malay: 'Masa semasa',
    japanese: '現在の時間',
    korean: '현재 시간',
  );

  String get newTime => _text(
    english: 'New time',
    mandarin: '新时间',
    malay: 'Masa baharu',
    japanese: '新しい時間',
    korean: '새 시간',
  );

  String get bookingTime => _text(
    english: 'Booking time',
    mandarin: '预订时间',
    malay: 'Masa tempahan',
    japanese: '予約時間',
    korean: '예약 시간',
  );

  String get reviewTitle => _text(
    english: 'Review booking action',
    mandarin: '检查预订操作',
    malay: 'Semak tindakan tempahan',
    japanese: '予約操作を確認',
    korean: '예약 작업 확인',
  );

  String get capacityWarning => _text(
    english: 'Availability and booking status will be checked again when you confirm.',
    mandarin: '确认时系统会再次检查空位和预订状态。',
    malay: 'Ketersediaan dan status tempahan akan diperiksa semula semasa pengesahan.',
    japanese: '確定時に空き状況と予約ステータスを再確認します。',
    korean: '확정할 때 잔여 좌석과 예약 상태를 다시 확인합니다.',
  );

  String get cancellationWarning => _text(
    english: 'The reserved spaces will be released immediately. This cannot be undone.',
    mandarin: '预留空位会立即释放，而且无法撤销。',
    malay: 'Tempat yang ditempah akan dilepaskan serta-merta dan tidak boleh dipulihkan.',
    japanese: '確保された枠はすぐに解放され、この操作は元に戻せません。',
    korean: '예약 좌석이 즉시 해제되며 이 작업은 되돌릴 수 없습니다.',
  );

  String get confirmBooking => _text(
    english: 'Confirm Booking',
    mandarin: '确认预订',
    malay: 'Sahkan Tempahan',
    japanese: '予約を確定',
    korean: '예약 확정',
  );

  String get confirmReschedule => _text(
    english: 'Confirm Reschedule',
    mandarin: '确认改期',
    malay: 'Sahkan Pertukaran Masa',
    japanese: '時間変更を確定',
    korean: '시간 변경 확정',
  );

  String get confirmCancellation => _text(
    english: 'Confirm Cancellation',
    mandarin: '确认取消',
    malay: 'Sahkan Pembatalan',
    japanese: 'キャンセルを確定',
    korean: '취소 확정',
  );

  String get startOver => _text(
    english: 'Start over',
    mandarin: '重新选择',
    malay: 'Mula semula',
    japanese: '最初から',
    korean: '다시 시작',
  );

  String get stop => _text(
    english: 'Stop',
    mandarin: '停止',
    malay: 'Hentikan',
    japanese: '中止',
    korean: '중지',
  );

  String get processing => _text(
    english: 'Checking…',
    mandarin: '检查中……',
    malay: 'Memeriksa…',
    japanese: '確認中…',
    korean: '확인 중…',
  );

  String selectedAttraction(String name) => _text(
    english: 'Selected attraction: $name',
    mandarin: '已选择景点：$name',
    malay: 'Tarikan dipilih: $name',
    japanese: '選択した観光地：$name',
    korean: '선택한 관광지: $name',
  );

  String selectedBooking(String code) => _text(
    english: 'Selected booking: $code',
    mandarin: '已选择预订：$code',
    malay: 'Tempahan dipilih: $code',
    japanese: '選択した予約：$code',
    korean: '선택한 예약: $code',
  );

  String selectedSlot(DateTime value) => _text(
    english: 'Selected time: ${formatChatBookingDateTime(value)}',
    mandarin: '已选择时间：${formatChatBookingDateTime(value)}',
    malay: 'Masa dipilih: ${formatChatBookingDateTime(value)}',
    japanese: '選択した時間：${formatChatBookingDateTime(value)}',
    korean: '선택한 시간: ${formatChatBookingDateTime(value)}',
  );

  String selectedVisitors(int count) => _text(
    english: 'Visitors: $count',
    mandarin: '游客人数：$count',
    malay: 'Pelawat: $count',
    japanese: '訪問者数：$count',
    korean: '방문 인원: $count',
  );

  String get restartMessage => _text(
    english: 'Start this booking action again',
    mandarin: '重新开始这个预订操作',
    malay: 'Mulakan semula tindakan tempahan ini',
    japanese: 'この予約操作を最初からやり直す',
    korean: '이 예약 작업 다시 시작',
  );

  String get stopMessage => _text(
    english: 'Stop this booking action',
    mandarin: '停止这个预订操作',
    malay: 'Hentikan tindakan tempahan ini',
    japanese: 'この予約操作を中止する',
    korean: '이 예약 작업 중지',
  );

  String completionFallback(ChatBookingOperation operation, String code) {
    return switch (operation) {
      ChatBookingOperation.create => _text(
        english: 'Booking created. Booking ID: $code\nStatus: Confirmed',
        mandarin: '预订成功。预订编号：$code\n状态：已确认',
        malay: 'Tempahan berjaya. ID Tempahan: $code\nStatus: Disahkan',
        japanese: '予約が完了しました。予約ID：$code\nステータス：確定済み',
        korean: '예약이 완료되었습니다. 예약 ID: $code\n상태: 확정됨',
      ),
      ChatBookingOperation.reschedule => _text(
        english: 'Booking rescheduled. Booking ID: $code\nStatus: Confirmed',
        mandarin: '改期成功。预订编号：$code\n状态：已确认',
        malay: 'Masa tempahan berjaya diubah. ID Tempahan: $code\nStatus: Disahkan',
        japanese: '予約時間を変更しました。予約ID：$code\nステータス：確定済み',
        korean: '예약 시간이 변경되었습니다. 예약 ID: $code\n상태: 확정됨',
      ),
      ChatBookingOperation.cancel => _text(
        english: 'Booking cancelled. Booking ID: $code\nStatus: Cancelled',
        mandarin: '预订已取消。预订编号：$code\n状态：已取消',
        malay: 'Tempahan dibatalkan. ID Tempahan: $code\nStatus: Dibatalkan',
        japanese: '予約をキャンセルしました。予約ID：$code\nステータス：キャンセル済み',
        korean: '예약이 취소되었습니다. 예약 ID: $code\n상태: 취소됨',
      ),
    };
  }
}

class ChatBookingGuideCard extends StatelessWidget {
  const ChatBookingGuideCard({
    required this.draft,
    required this.copy,
    required this.isBusy,
    required this.onSelectAttraction,
    required this.onSelectBooking,
    required this.onSelectSlot,
    required this.onSelectVisitors,
    required this.onRestart,
    required this.onCancel,
    super.key,
  });

  final ChatBookingDraft draft;
  final ChatBookingCopy copy;
  final bool isBusy;
  final ValueChanged<ChatBookingAttractionOption> onSelectAttraction;
  final ValueChanged<ChatBookingOption> onSelectBooking;
  final ValueChanged<ChatBookingSlotOption> onSelectSlot;
  final ValueChanged<int> onSelectVisitors;
  final VoidCallback onRestart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final next = draft.missingFields.firstOrNull;
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TourFlowColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: TourFlowText(
                    _title(next),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _options(next),
            const Divider(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: isBusy ? null : onRestart,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: TourFlowText(copy.startOver),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: TourFlowText(copy.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title(String? field) => switch (field) {
    'attraction' => copy.chooseAttraction,
    'booking' => copy.chooseBooking,
    'slot' => copy.chooseSlot,
    'visitors' => copy.chooseVisitors,
    _ => copy.reviewTitle,
  };

  Widget _options(String? field) {
    if (field == 'attraction') {
      if (draft.attractionOptions.isEmpty) {
        return _EmptyState(copy.noAvailableAttractions);
      }
      return Column(
        children: draft.attractionOptions
            .map(
              (option) => _ChoiceTile(
                icon: Icons.place_outlined,
                title: option.name,
                onTap: isBusy ? null : () => onSelectAttraction(option),
              ),
            )
            .toList(),
      );
    }
    if (field == 'booking') {
      if (draft.bookingOptions.isEmpty) {
        return _EmptyState(copy.noEligibleBookings);
      }
      return Column(
        children: draft.bookingOptions
            .map(
              (option) => _ChoiceTile(
                icon: Icons.confirmation_number_outlined,
                title: '${option.code} · ${option.attractionName}',
                subtitle:
                    '${formatChatBookingDateTime(option.startsAt)} · ${option.visitorCount} ${copy.visitors.toLowerCase()}',
                onTap: isBusy ? null : () => onSelectBooking(option),
              ),
            )
            .toList(),
      );
    }
    if (field == 'slot') {
      if (draft.slotOptions.isEmpty) {
        return _EmptyState(copy.noAvailableSlots);
      }
      return Column(
        children: draft.slotOptions
            .map(
              (option) => _ChoiceTile(
                icon: Icons.schedule_rounded,
                title: formatChatBookingDateTime(option.startsAt),
                subtitle:
                    '${formatChatBookingTime(option.startsAt, option.endsAt)} · ${option.remainingCapacity} ${copy.availableSpaces}',
                onTap: isBusy ? null : () => onSelectSlot(option),
              ),
            )
            .toList(),
      );
    }
    if (field == 'visitors') {
      final selectedSlot = draft.slotOptions
          .where((option) => option.id == draft.slotId)
          .firstOrNull;
      final maximum = selectedSlot?.remainingCapacity ?? 0;
      if (maximum < 1) {
        return _EmptyState(copy.noRemainingSpaces);
      }
      return _VisitorCountSlider(
        key: ValueKey('booking-visitors-${draft.slotId}-$maximum'),
        maximum: maximum,
        initialValue: draft.visitorCount ?? 1,
        copy: copy,
        isBusy: isBusy,
        onConfirm: onSelectVisitors,
      );
    }
    return const SizedBox.shrink();
  }
}

class _VisitorCountSlider extends StatefulWidget {
  const _VisitorCountSlider({
    required this.maximum,
    required this.initialValue,
    required this.copy,
    required this.isBusy,
    required this.onConfirm,
    super.key,
  });

  final int maximum;
  final int initialValue;
  final ChatBookingCopy copy;
  final bool isBusy;
  final ValueChanged<int> onConfirm;

  @override
  State<_VisitorCountSlider> createState() => _VisitorCountSliderState();
}

class _VisitorCountSliderState extends State<_VisitorCountSlider> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(1, widget.maximum).toInt();
  }

  @override
  void didUpdateWidget(covariant _VisitorCountSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maximum != widget.maximum ||
        oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue.clamp(1, widget.maximum).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSlide = widget.maximum > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TourFlowColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE2A8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_value',
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.copy.selectedVisitorCount(_value),
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Slider(
          value: _value.toDouble(),
          min: 1,
          max: widget.maximum.toDouble(),
          divisions: canSlide ? widget.maximum - 1 : null,
          label: '$_value',
          onChanged: widget.isBusy || !canSlide
              ? null
              : (value) => setState(() => _value = value.round()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1'),
              Text('${widget.maximum}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: widget.isBusy ? null : () => widget.onConfirm(_value),
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.copy.confirmVisitorCount),
          ),
        ),
      ],
    );
  }
}

class ChatBookingConfirmationCard extends StatelessWidget {
  const ChatBookingConfirmationCard({
    required this.draft,
    required this.copy,
    required this.isSubmitting,
    required this.onConfirm,
    required this.onRestart,
    required this.onCancel,
    super.key,
  });

  final ChatBookingDraft draft;
  final ChatBookingCopy copy;
  final bool isSubmitting;
  final VoidCallback onConfirm;
  final VoidCallback onRestart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final selectedBooking = draft.bookingOptions
        .where((option) => option.id == draft.bookingId)
        .firstOrNull;
    final rows = <MapEntry<String, String>>[
      if (draft.bookingCode != null)
        MapEntry(copy.bookingId, draft.bookingCode!),
      MapEntry(copy.attraction, draft.attractionName ?? 'TourFlow'),
      if (draft.operation == ChatBookingOperation.reschedule &&
          selectedBooking != null)
        MapEntry(
          copy.currentTime,
          formatChatBookingDateTime(selectedBooking.startsAt),
        ),
      if (draft.slotStartsAt != null)
        MapEntry(
          draft.operation == ChatBookingOperation.reschedule
              ? copy.newTime
              : copy.bookingTime,
          formatChatBookingDateTime(draft.slotStartsAt!),
        ),
      if (draft.visitorCount != null)
        MapEntry(copy.visitors, '${draft.visitorCount}'),
    ];
    final destructive = draft.operation == ChatBookingOperation.cancel;

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: destructive ? const Color(0xFFFCA5A5) : TourFlowColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  destructive
                      ? Icons.warning_amber_rounded
                      : Icons.fact_check_outlined,
                  color: destructive ? Colors.red.shade700 : TourFlowColors.primaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TourFlowText(
                    copy.reviewTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: TourFlowText(
                        row.key,
                        style: const TextStyle(color: TourFlowColors.muted),
                      ),
                    ),
                    Expanded(
                      child: TourFlowText(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: destructive
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TourFlowText(
                destructive ? copy.cancellationWarning : copy.capacityWarning,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: destructive ? Colors.red.shade700 : null,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        destructive
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline_rounded,
                      ),
                label: TourFlowText(
                  isSubmitting ? copy.processing : _confirmLabel,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSubmitting ? null : onRestart,
                  child: TourFlowText(copy.startOver),
                ),
                TextButton(
                  onPressed: isSubmitting ? null : onCancel,
                  child: TourFlowText(copy.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _confirmLabel => switch (draft.operation) {
    ChatBookingOperation.create => copy.confirmBooking,
    ChatBookingOperation.reschedule => copy.confirmReschedule,
    ChatBookingOperation.cancel => copy.confirmCancellation,
  };
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: TourFlowColors.primaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TourFlowText(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      TourFlowText(
                        subtitle!,
                        style: const TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TourFlowText(message),
  );
}

String formatChatBookingDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year} ${_clock(value)}';
}

String formatChatBookingTime(DateTime start, DateTime end) =>
    '${_clock(start)} – ${_clock(end)}';

String _clock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
