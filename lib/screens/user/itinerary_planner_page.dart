import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';

class ItineraryPlannerPage extends StatelessWidget {
  const ItineraryPlannerPage({super.key});
  static const routeName = '/itinerary-planner';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8FF),
    drawer: UserSidebar(displayName: 'Alex Tan', email: 'alex@example.com', selectedIndex: 5, onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false)),
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, title: const Text('My Itinerary', style: TextStyle(fontWeight: FontWeight.w700))),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Thursday, 28 August', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const _PlanStop(time: '09:00', title: 'Old Town Square', subtitle: '09:00 – 10:30 · Confirmed', icon: Icons.account_balance_rounded),
      const _TravelInfo(time: '18 min', detail: '1.4 km by car'),
      const _PlanStop(time: '11:15', title: 'Heritage Walking Tour', subtitle: '11:15 – 12:45 · Confirmed', icon: Icons.directions_walk_rounded),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(14)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFF79571E)), SizedBox(width: 8), Text('Smart itinerary check', style: TextStyle(fontWeight: FontWeight.w800))]), SizedBox(height: 8), Text('Your schedule is achievable. You have 27 minutes between visits, including estimated travel time.', style: TextStyle(fontSize: 12, height: 1.45))])),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)), SizedBox(width: 9), Expanded(child: Text('If a new booking overlaps with an existing visit or maintenance day, TourFlow will show a conflict before confirmation.', style: TextStyle(fontSize: 12, height: 1.45)))])),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Add another booking'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
    ])),
    bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
  );
}

class _PlanStop extends StatelessWidget {
  const _PlanStop({required this.time, required this.title, required this.subtitle, required this.icon});
  final String time, title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 48, child: Text(time, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF79571E)))), Expanded(child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD2C4B4))), child: Row(children: [Icon(icon, color: const Color(0xFF79571E)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]))])))]);
}

class _TravelInfo extends StatelessWidget {
  const _TravelInfo({required this.time, required this.detail});
  final String time, detail;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8), child: Row(children: [const Icon(Icons.directions_car_outlined, size: 16, color: Color(0xFF64748B)), const SizedBox(width: 6), Text('$time · $detail', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]));
}
