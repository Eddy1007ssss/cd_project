import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  static const String routeName = '/booking-qr';

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;

    final booking = routeArguments is BookingQrArguments
        ? routeArguments
        : const BookingQrArguments(
      attraction: 'National Museum',
      date: '17 Sep 2026',
      time: '4:00 PM',
      code: 'NM-170926-1600-A1',
      visitors: 1,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      // =========================
      // SIDEBAR
      // =========================
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 2,
        onLogout: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sign-in',
                (route) => false,
          );
        },
      ),

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Booking (QR Code)',
              style: TextStyle(
                color: Color(0xFF131B2E),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 1),
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
            child: Center(
              child: _RoleBadge(),
            ),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              14,
              20,
              14,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =========================
                // BOOKING INFORMATION
                // =========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE0E2E8),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.attraction,
                        style: const TextStyle(
                          color: Color(0xFF131B2E),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _BookingInfoRow(
                        label: 'Date',
                        value: booking.date,
                      ),

                      const SizedBox(height: 8),

                      _BookingInfoRow(
                        label: 'Time',
                        value: booking.time,
                      ),

                      const SizedBox(height: 8),

                      _BookingInfoRow(
                        label: 'Booking ID',
                        value: booking.code,
                      ),

                      const SizedBox(height: 8),

                      const _BookingInfoRow(
                        label: 'Status',
                        value: 'Confirmed',
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Muzium Negara, Jabatan Muzium Malaysia, '
                            'Jalan Damansara, 50566 Kuala Lumpur, Malaysia.',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // =========================
                // QR CODE
                // =========================
                Center(
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Check-in QR Code',
                                    style: TextStyle(
                                      color: Color(0xFF131B2E),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  QrImageView(
                                    data: booking.code,
                                    version: QrVersions.auto,
                                    size: 260,
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),

                                  const SizedBox(height: 14),

                                  Text(
                                    booking.code,
                                    style: const TextStyle(
                                      color: Color(0xFF131B2E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFCD84),
                                        foregroundColor: const Color(0xFF79571E),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                      ),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF131B2E),
                          width: 1.7,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: QrImageView(
                        data: booking.code,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // =========================
                // BOOKING CODE
                // =========================
                Text(
                  booking.code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${booking.attraction} · '
                      '${booking.time} · '
                      '${booking.visitors} '
                      '${booking.visitors == 1 ? 'visitor' : 'visitors'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A8498),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // VIEW CAPACITY ALERT
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/capacity-alert',
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCD84),
                      foregroundColor: const Color(0xFF79571E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'View Capacity Alert',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

// =========================
// VIEW GEOFENCE
// =========================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/geofence',
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCD84),
                      foregroundColor: const Color(0xFF79571E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                    ),
                    label: const Text(
                      'View Geofence',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar:
      const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}

// ============================================================
// BOOKING INFO ROW
// ============================================================

class _BookingInfoRow extends StatelessWidget {
  const _BookingInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ROLE BADGE
// ============================================================

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        border: Border.all(
          color: const Color(0xFFE8D3B7),
        ),
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