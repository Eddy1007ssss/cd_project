import 'package:flutter/material.dart';

import '../models/support_ticket_models.dart';
import 'tourflow_widgets.dart';

class SupportGuideOption {
  const SupportGuideOption(this.value, this.label);
  final String value;
  final String label;
}

class SupportTicketGuideCopy {
  const SupportTicketGuideCopy(this.language);
  final String language;

  bool get _zh => language == 'Mandarin';
  String get title => _zh ? '建立客服工单' : 'Create Support Ticket';
  String get start => _zh ? '联系客服' : 'Contact support';
  String get back => _zh ? '上一步' : 'Previous step';
  String get restart => _zh ? '重新选择' : 'Start over';
  String get cancel => _zh ? '取消客服工单' : 'Cancel support request';
  String get noBooking => _zh ? '没有相关预订' : 'No related booking';
  String get addDetails => _zh ? '添加补充说明' : 'Add optional details';
  String get skipDetails => _zh ? '跳过' : 'Skip';
  String get submit => _zh ? '提交客服工单' : 'Submit Support Ticket';
  String get submitting => _zh ? '提交中…' : 'Submitting…';
  String get confirmTitle => _zh ? '确认客服工单' : 'Confirm Support Ticket';
  String get category => _zh ? '类别' : 'Category';
  String get issue => _zh ? '问题' : 'Issue';
  String get booking => _zh ? '相关预订' : 'Related booking';
  String get details => _zh ? '补充说明' : 'Additional details';
  String get routedTo => _zh ? '预计处理方' : 'Expected handler';
  String get admin => _zh ? 'TourFlow Admin' : 'TourFlow Admin';
  String get operator => _zh ? '景点 Operator' : 'Attraction Operator';
  String get otherIssueTitle => _zh ? '说明其他问题' : 'Describe another issue';
  String get detailsTitle => _zh ? '补充说明（可选）' : 'Additional details (optional)';
  String get inputHint => _zh ? '请说明遇到的 TourFlow App 问题' : 'Describe the TourFlow app problem';
  String get save => _zh ? '确认' : 'Confirm';
  String get close => _zh ? '取消' : 'Cancel';
  String get viewTickets => _zh ? '查看客服工单' : 'View Support Tickets';

  String prompt(String field) => switch (field) {
    'category' => _zh ? '你需要哪一类协助？' : 'What do you need help with?',
    'issue' => _zh ? '请选择最符合情况的问题。' : 'Choose the issue that best matches.',
    'booking' => _zh ? '请选择相关预订。' : 'Choose the related booking.',
    _ => _zh ? '需要添加补充说明吗？' : 'Would you like to add more details?',
  };

  List<SupportGuideOption> get categories => [
    SupportGuideOption('booking', _zh ? '预订问题' : 'Booking'),
    SupportGuideOption('account_profile', _zh ? '账户与个人资料' : 'Account & Profile'),
    SupportGuideOption('payment_refund', _zh ? '付款与退款' : 'Payment & Refund'),
    SupportGuideOption('qr_check_in', _zh ? '二维码与签到' : 'QR & Check-in'),
    SupportGuideOption('technical', _zh ? '技术问题' : 'Technical Problem'),
    SupportGuideOption('other', _zh ? '其他' : 'Other'),
  ];

  List<SupportGuideOption> issues(String? category) => switch (category) {
    'booking' => [
      SupportGuideOption('booking_missing', _zh ? '预订没有显示' : 'Booking is missing'),
      SupportGuideOption('booking_status_error', _zh ? '预订资料或状态错误' : 'Booking details/status incorrect'),
      SupportGuideOption('attraction_closed', _zh ? '景点临时关闭' : 'Attraction is closed'),
      SupportGuideOption('slot_cancelled', _zh ? '时段被取消' : 'Time slot was cancelled'),
      SupportGuideOption('operator_reschedule', _zh ? '需要景点协助改期' : 'Operator reschedule help'),
      SupportGuideOption('attraction_booking_support', _zh ? '其他景点预订协助' : 'Other attraction booking help'),
    ],
    'account_profile' => [
      SupportGuideOption('account_access', _zh ? '无法访问账户' : 'Cannot access account'),
      SupportGuideOption('profile_error', _zh ? '无法更新个人资料' : 'Cannot update profile'),
      SupportGuideOption('language_error', _zh ? '语言没有正确更新' : 'Language did not update'),
    ],
    'payment_refund' => [
      SupportGuideOption('payment_error', _zh ? '付款失败或扣款错误' : 'Payment failed/incorrect charge'),
      SupportGuideOption('refund_missing', _zh ? '尚未收到退款' : 'Refund has not arrived'),
    ],
    'qr_check_in' => [
      SupportGuideOption('qr_not_generated', _zh ? '二维码没有生成' : 'QR code not generated'),
      SupportGuideOption('entry_qr_rejected', _zh ? '景点拒绝有效二维码' : 'Valid QR rejected at attraction'),
      SupportGuideOption('check_in_error', _zh ? '签到功能错误' : 'Check-in feature error'),
    ],
    'technical' => [
      SupportGuideOption('app_error', _zh ? '页面或功能错误' : 'Page or feature error'),
      SupportGuideOption('data_not_loading', _zh ? '资料无法加载' : 'Data is not loading'),
      SupportGuideOption('notification_error', _zh ? '通知错误' : 'Notification problem'),
    ],
    'other' => [SupportGuideOption('other_support', _zh ? '填写其他问题' : 'Describe another issue')],
    _ => const [],
  };

  String submitted(String code) => _zh
      ? '客服工单已提交。\n工单编号：$code\n当前状态：待处理'
      : 'Support ticket submitted.\nTicket ID: $code\nStatus: Pending';
}

class SupportTicketGuideCard extends StatelessWidget {
  const SupportTicketGuideCard({
    required this.draft,
    required this.copy,
    required this.isBusy,
    required this.onSelectCategory,
    required this.onSelectIssue,
    required this.onSelectBooking,
    required this.onNoBooking,
    required this.onAddDetails,
    required this.onSkipDetails,
    required this.onBack,
    required this.onRestart,
    required this.onCancel,
    super.key,
  });

  final SupportTicketDraft draft;
  final SupportTicketGuideCopy copy;
  final bool isBusy;
  final ValueChanged<SupportGuideOption> onSelectCategory;
  final ValueChanged<SupportGuideOption> onSelectIssue;
  final ValueChanged<ComplaintBookingOption> onSelectBooking;
  final VoidCallback onNoBooking;
  final VoidCallback onAddDetails;
  final VoidCallback onSkipDetails;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final field = draft.missingFields.isEmpty
        ? 'category'
        : draft.missingFields.first;
    final step = const {
      'category': 1,
      'issue': 2,
      'booking': 3,
      'additionalDetails': 4,
    }[field] ?? 1;
    return ModuleCard(
      color: const Color(0xFFF0F9FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.support_agent_rounded, color: Color(0xFF1D4ED8)),
            ),
            const SizedBox(width: 10),
            Expanded(child: TourFlowText(copy.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            TourFlowText('$step / 4', style: const TextStyle(color: TourFlowColors.muted)),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: step / 4, minHeight: 6),
          const SizedBox(height: 14),
          TourFlowText(copy.prompt(field),
            style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _options(field),
          const Divider(height: 28),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (draft.canGoBack) TextButton.icon(
              onPressed: isBusy ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded), label: TourFlowText(copy.back)),
            TextButton.icon(onPressed: isBusy ? null : onRestart,
              icon: const Icon(Icons.restart_alt_rounded), label: TourFlowText(copy.restart)),
            TextButton.icon(onPressed: isBusy ? null : onCancel,
              icon: const Icon(Icons.close_rounded), label: TourFlowText(copy.cancel)),
          ]),
        ],
      ),
    );
  }

  Widget _options(String field) {
    if (field == 'booking') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...draft.bookingOptions.map((booking) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: isBusy ? null : () => onSelectBooking(booking),
              child: Align(alignment: Alignment.centerLeft,
                child: TourFlowText('${booking.code} · ${booking.attractionName}')),
            ),
          )),
          OutlinedButton.icon(onPressed: isBusy ? null : onNoBooking,
            icon: const Icon(Icons.link_off_rounded), label: TourFlowText(copy.noBooking)),
        ],
      );
    }
    if (field == 'additionalDetails') {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: isBusy ? null : onAddDetails,
          icon: const Icon(Icons.edit_note_rounded), label: TourFlowText(copy.addDetails)),
        OutlinedButton.icon(onPressed: isBusy ? null : onSkipDetails,
          icon: const Icon(Icons.skip_next_rounded), label: TourFlowText(copy.skipDetails)),
      ]);
    }
    final choices = field == 'category' ? copy.categories : copy.issues(draft.category);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((option) => OutlinedButton(
        onPressed: isBusy ? null : () =>
            (field == 'category' ? onSelectCategory : onSelectIssue)(option),
        child: TourFlowText(option.label),
      )).toList(),
    );
  }
}

class SupportTicketConfirmationCard extends StatelessWidget {
  const SupportTicketConfirmationCard({
    required this.draft,
    required this.copy,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
    required this.onCancel,
    super.key,
  });
  final SupportTicketDraft draft;
  final SupportTicketGuideCopy copy;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => ModuleCard(
    color: const Color(0xFFF0FDF4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TourFlowText(copy.confirmTitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      _row(copy.category, draft.categoryLabel),
      _row(copy.issue, draft.issueLabel ?? '-'),
      _row(copy.booking, draft.bookingCode ?? copy.noBooking),
      _row(copy.details, draft.additionalDetails ?? '-'),
      _row(copy.routedTo, _operatorIssue(draft.issueType) && draft.attractionId != null
        ? copy.operator : copy.admin),
      const Divider(height: 26),
      Row(children: [
        TextButton.icon(onPressed: isSubmitting ? null : onBack,
          icon: const Icon(Icons.arrow_back_rounded), label: TourFlowText(copy.back)),
        TextButton.icon(onPressed: isSubmitting ? null : onCancel,
          icon: const Icon(Icons.close_rounded), label: TourFlowText(copy.cancel)),
        const Spacer(),
        FilledButton.icon(onPressed: isSubmitting ? null : onSubmit,
          icon: isSubmitting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.send_rounded),
          label: TourFlowText(isSubmitting ? copy.submitting : copy.submit)),
      ]),
    ]),
  );

  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 125, child: TourFlowText(label,
        style: const TextStyle(color: TourFlowColors.muted, fontSize: 11))),
      Expanded(child: TourFlowText(value,
        style: const TextStyle(fontWeight: FontWeight.w700))),
    ]),
  );

  static bool _operatorIssue(String? value) => const {
    'attraction_closed', 'slot_cancelled', 'operator_reschedule',
    'entry_qr_rejected', 'attraction_booking_support',
  }.contains(value);
}
