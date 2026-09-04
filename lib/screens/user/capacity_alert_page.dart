import 'package:flutter/material.dart';

import '../../widgets/navigation/user_sidebar.dart';
import '../../widgets/navigation/navigation_logout.dart';

class CapacityAlertPage extends StatelessWidget {
  const CapacityAlertPage({super.key});

  static const String routeName = '/capacity-alert';

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
        onLogout: () async => signOutAndReturnToSignIn(context),
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
              'Capacity Alert',
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
            child: Center(child: _RoleBadge()),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =========================
                // CURRENT CROWD LEVEL
                // =========================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Crowd Level',
                        style: TextStyle(
                          color: Color(0xFF475467),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'MODERATE',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // =========================
                // CURRENT VISITORS
                // =========================
                const _InformationCard(
                  title: 'Current Visitors',
                  value: '68 / 120',
                ),

                const SizedBox(height: 12),

                // =========================
                // WAITING TIME
                // =========================
                const _InformationCard(
                  title: 'Estimated Waiting Time',
                  value: '8 minutes',
                ),

                const SizedBox(height: 12),

                // =========================
                // RECOMMENDATION
                // =========================
                const _InformationCard(
                  title: 'Recommendation',
                  value: 'Normal waiting time.',
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
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text(
                      'Open QR Code',
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
                      Navigator.pushNamed(context, '/geofence');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCD84),
                      foregroundColor: const Color(0xFF79571E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(Icons.location_on_outlined, size: 20),
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
    );
  }
}

// ============================================================
// INFORMATION CARD
// ============================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E2E8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF131B2E),
              fontSize: 14,
              fontWeight: FontWeight.w800,
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
