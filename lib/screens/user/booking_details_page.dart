import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'booking_qr_page.dart';
import 'reschedule_booking_page.dart';

class BookingDetailsArguments {
  const BookingDetailsArguments({
    required this.attraction,
    required this.date,
    required this.time,
    required this.code,
    required this.visitors,
    required this.statusLabel,
    required this.qrAvailable,
    required this.canReschedule,
    required this.canCancel,
  });

  final String attraction;
  final String date;
  final String time;
  final String code;
  final int visitors;
  final String statusLabel;
  final bool qrAvailable;
  final bool canReschedule;
  final bool canCancel;
}

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key});

  static const routeName = '/booking-details';

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _cancellationRequested = false;

  Future<void> _requestCancellation(BookingDetailsArguments booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFBA1A1A),
          size: 34,
        ),
        title: const Text('Cancel this booking?'),
        content: Text(
          'Your reserved slot for ${booking.attraction} will be released. '
          'This action will be submitted as a cancellation request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            child: const Text('Request Cancellation'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancellationRequested = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cancellation request submitted.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final booking = routeArguments is BookingDetailsArguments
        ? routeArguments
        : const BookingDetailsArguments(
            attraction: 'National Museum',
            date: 'Sep 17, 2026',
            time: '16:00 – 16:30',
            code: 'TF-99210',
            visitors: 1,
            statusLabel: 'Confirmed',
            qrAvailable: true,
            canReschedule: true,
            canCancel: true,
          );

    final canUseQr = booking.qrAvailable && !_cancellationRequested;
    final canReschedule = booking.canReschedule && !_cancellationRequested;
    final canCancel = booking.canCancel && !_cancellationRequested;
    final visibleStatus =
        _cancellationRequested ? 'Cancellation requested' : booking.statusLabel;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 2,
        onLogout: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/sign-in',
          (route) => false,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: TextStyle(
                color: Color(0xFF131B2E),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'TourFlow',
              style: TextStyle(
                color: Color(0xFF79571E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: _RoleBadge()),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BookingSummaryCard(
                  booking: booking,
                  statusLabel: visibleStatus,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Check-in pass',
                  icon: Icons.qr_code_2_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canUseQr
                            ? 'Your QR code is ready. Show it to attraction staff when you arrive.'
                            : _qrUnavailableMessage(visibleStatus),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: canUseQr
                              ? () => Navigator.pushNamed(
                                    context,
                                    BookingQrPage.routeName,
                                    arguments: BookingQrArguments(
                                      attraction: booking.attraction,
                                      date: booking.date,
                                      time: booking.time,
                                      code: booking.code,
                                      visitors: booking.visitors,
                                    ),
                                  )
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF79571E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE7E2DA),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('View QR Code'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Manage booking',
                  icon: Icons.edit_calendar_outlined,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: canReschedule
                          ? () => Navigator.pushNamed(
                                context,
                                RescheduleBookingPage.routeName,
                                arguments: RescheduleBookingArguments(
                                  attraction: booking.attraction,
                                  date: booking.date,
                                  time: booking.time,
                                  code: booking.code,
                                  visitors: booking.visitors,
                                ),
                              )
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF79571E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD2C4B4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: const Text('Reschedule Booking'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBFA),
                    border: Border.all(color: const Color(0xFFFFC9C5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFFEE2E2),
                            foregroundColor: Color(0xFFBA1A1A),
                            child: Icon(Icons.warning_amber_rounded, size: 21),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Cancel booking',
                            style: TextStyle(
                              color: Color(0xFF131B2E),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _cancellationRequested
                            ? 'Your cancellation request is pending review.'
                            : 'Cancelling releases your reserved visitor slot immediately after approval.',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 13),
                      OutlinedButton(
                        onPressed:
                            canCancel ? () => _requestCancellation(booking) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBA1A1A),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _cancellationRequested
                              ? 'Cancellation Requested'
                              : 'Request Cancellation',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }

  String _qrUnavailableMessage(String status) {
    return switch (status.toLowerCase()) {
      'processing' =>
        'The QR code will become available after this booking is confirmed.',
      'completed' => 'This visit is completed, so its check-in QR has expired.',
      'cancelled' => 'This booking was cancelled and has no active QR code.',
      'cancellation requested' =>
        'The QR code is unavailable while cancellation is pending.',
      _ => 'A QR code is not available for this booking.',
    };
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.booking,
    required this.statusLabel,
  });

  final BookingDetailsArguments booking;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E2DA)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2B5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF79571E),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.attraction,
                      style: const TextStyle(
                        color: Color(0xFF131B2E),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _BookingStatusBadge(label: statusLabel),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: Color(0xFFE7E2DA)),
          ),
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Date',
            value: booking.date,
          ),
          const SizedBox(height: 11),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value: booking.time,
          ),
          const SizedBox(height: 11),
          _DetailRow(
            icon: Icons.people_outline_rounded,
            label: 'Visitors',
            value:
                '${booking.visitors} ${booking.visitors == 1 ? 'visitor' : 'visitors'}',
          ),
          const SizedBox(height: 11),
          _DetailRow(
            icon: Icons.confirmation_num_outlined,
            label: 'Registration code',
            value: booking.code,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E2DA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF79571E), size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF131B2E),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF79571E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF131B2E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final isDanger = normalized.contains('cancel');
    final isComplete = normalized == 'completed';
    final background = isDanger
        ? const Color(0xFFFEE2E2)
        : isComplete
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFFE2A8);
    final foreground = isDanger
        ? const Color(0xFFBA1A1A)
        : isComplete
            ? const Color(0xFF15803D)
            : const Color(0xFF79571E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .35,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        border: Border.all(color: const Color(0xFFE8D3B7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'TOURIST',
        style: TextStyle(
          color: Color(0xFF79571E),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
