import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';

class BookingQrArguments {
  const BookingQrArguments({
    required this.attraction,
    required this.date,
    required this.time,
    required this.code,
    required this.visitors,
  });

  final String attraction;
  final String date;
  final String time;
  final String code;
  final int visitors;
}

class BookingQrPage extends StatelessWidget {
  const BookingQrPage({super.key});

  static const routeName = '/booking-qr';

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final booking = routeArguments is BookingQrArguments
        ? routeArguments
        : const BookingQrArguments(
            attraction: 'National Museum',
            date: 'Sep 17, 2026',
            time: '16:00 – 16:30',
            code: 'TF-99210',
            visitors: 1,
          );

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
        title: const Text(
          'Booking QR Code',
          style: TextStyle(
            color: Color(0xFF131B2E),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFDCFCE7),
                  foregroundColor: Color(0xFF15803D),
                  child: Icon(Icons.verified_rounded, size: 34),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ready for check-in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Show this QR code to attraction staff when you arrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD2C4B4)),
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
                    children: [
                      Text(
                        booking.code,
                        style: const TextStyle(
                          color: Color(0xFF79571E),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 210,
                        height: 210,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE7E2DA)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 190,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Static QR preview',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFE7E2DA)),
                      ),
                      _QrDetailRow(
                        icon: Icons.account_balance_rounded,
                        title: booking.attraction,
                        subtitle: '${booking.date} · ${booking.time}',
                      ),
                      const SizedBox(height: 12),
                      _QrDetailRow(
                        icon: Icons.people_outline_rounded,
                        title:
                            '${booking.visitors} ${booking.visitors == 1 ? 'visitor' : 'visitors'}',
                        subtitle: 'Please arrive 10 minutes before your slot.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF79571E),
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Keep the screen visible and increase brightness if staff have difficulty scanning it.',
                          style: TextStyle(
                            color: Color(0xFF4F4539),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF79571E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFD2C4B4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Booking Details'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}

class _QrDetailRow extends StatelessWidget {
  const _QrDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFFFE2B5),
          foregroundColor: const Color(0xFF79571E),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF131B2E),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
