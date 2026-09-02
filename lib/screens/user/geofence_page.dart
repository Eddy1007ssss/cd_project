import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';

class GeofencePage extends StatelessWidget {
  const GeofencePage({super.key});

  static const String routeName = '/geofence';

  @override
  Widget build(BuildContext context) {
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
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geofence',
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
              16,
              18,
              16,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =========================
                // ATTRACTION
                // =========================
                const Text(
                  'National Museum',
                  style: TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Check whether you are within the attraction check-in area.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // GEOFENCE MAP
                // =========================
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EEE8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE1DDD5),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fake map lines
                      Positioned(
                        top: 45,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      Positioned(
                        bottom: 55,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 65,
                        child: Container(
                          width: 3,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 45,
                        child: Container(
                          width: 4,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      // Geofence radius
                      Container(
                        width: 185,
                        height: 185,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFCD84).withOpacity(0.20),
                          border: Border.all(
                            color: const Color(0xFFE1A23E),
                            width: 2,
                          ),
                        ),
                      ),

                      // Museum position
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFF79571E),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'National Museum',
                            style: TextStyle(
                              color: Color(0xFF131B2E),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      // Tourist position
                      Positioned(
                        right: 78,
                        bottom: 55,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // GEOFENCE STATUS
                // =========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geofence Status',
                        style: TextStyle(
                          color: Color(0xFF475467),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 9),

                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF16A34A),
                            size: 21,
                          ),

                          SizedBox(width: 7),

                          Text(
                            'INSIDE GEOFENCE',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // =========================
                // ALLOWED RADIUS
                // =========================
                const _InformationCard(
                  title: 'Allowed Radius',
                  value: '200 metres',
                  icon: Icons.radar_rounded,
                ),

                const SizedBox(height: 12),

                // =========================
                // CURRENT DISTANCE
                // =========================
                const _InformationCard(
                  title: 'Current Distance',
                  value: '85 metres from attraction',
                  icon: Icons.straighten_rounded,
                ),

                const SizedBox(height: 12),

                // =========================
                // CHECK-IN STATUS
                // =========================
                const _InformationCard(
                  title: 'Check-in Status',
                  value: 'You are within the check-in area.',
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 18),

                // =========================
                // INFORMATION
                // =========================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFB7791F),
                        size: 20,
                      ),

                      SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          'You are close enough to the attraction. '
                              'Present your booking QR code at the entrance to check in.',
                          style: TextStyle(
                            color: Color(0xFF79571E),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =========================
                // OPEN QR CODE
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
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
                      Icons.qr_code_2_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Open QR Code',
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
// INFORMATION CARD
// ============================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E2E8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF79571E),
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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