import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'attraction_details_page.dart';

class NearbyAttractionsPage extends StatelessWidget {
  const NearbyAttractionsPage({super.key});

  static const routeName = '/nearby-attractions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(displayName: 'Alex Tan', email: 'alex@example.com', selectedIndex: 1, onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false)),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Nearby Attractions', style: TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.my_location_rounded))],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 205,
              decoration: BoxDecoration(color: const Color(0xFFE7F0E4), borderRadius: BorderRadius.circular(18)),
              child: Stack(children: [
                const Center(child: Icon(Icons.map_rounded, size: 105, color: Color(0xFF8BA17E))),
                const Positioned(top: 44, left: 88, child: Icon(Icons.location_pin, color: Color(0xFFBA1A1A), size: 36)),
                const Positioned(top: 98, right: 78, child: Icon(Icons.location_pin, color: Color(0xFF79571E), size: 36)),
                const Positioned(bottom: 28, left: 172, child: Icon(Icons.location_pin, color: Color(0xFF16A34A), size: 36)),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(onPressed: () {}, backgroundColor: Colors.white, foregroundColor: const Color(0xFF79571E), child: const Icon(Icons.layers_outlined)),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('Around you', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Sorted by travel distance from your current location.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            const SizedBox(height: 13),
            _NearbyTile(
              title: 'Old Town Square',
              distance: '1.2 km · about 6 min',
              crowd: 'Moderate crowd',
              icon: Icons.account_balance_rounded,
              onTap: () => Navigator.pushNamed(context, AttractionDetailsPage.routeName),
            ),
            const SizedBox(height: 10),
            _NearbyTile(
              title: 'City Art Gallery',
              distance: '1.9 km · about 9 min',
              crowd: 'Low crowd',
              icon: Icons.palette_outlined,
              onTap: () => Navigator.pushNamed(context, AttractionDetailsPage.routeName),
            ),
            const SizedBox(height: 10),
            _NearbyTile(
              title: 'Lumina Botanical Gardens',
              distance: '2.8 km · about 14 min',
              crowd: 'Low crowd',
              icon: Icons.local_florist_rounded,
              onTap: () => Navigator.pushNamed(context, AttractionDetailsPage.routeName),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(15)),
              child: const Row(children: [
                Icon(Icons.directions_walk_rounded, color: Color(0xFF79571E)),
                SizedBox(width: 10),
                Expanded(child: Text('Travel times are estimates. Check your itinerary before registering for a slot.', style: TextStyle(color: Color(0xFF4F4539), fontSize: 11, height: 1.4))),
              ]),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.title, required this.distance, required this.crowd, required this.icon, required this.onTap});
  final String title;
  final String distance;
  final String crowd;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(border: Border.all(color: const Color(0x33D2C4B4)), borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF79571E))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(distance, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)), const SizedBox(height: 6), Text(crowd, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w700))])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
        ]),
      ),
    ),
  );
}
