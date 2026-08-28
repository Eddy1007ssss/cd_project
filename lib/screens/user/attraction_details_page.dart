import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'smart_recommendations_page.dart';

class AttractionDetailsPage extends StatelessWidget {
  const AttractionDetailsPage({super.key});

  static const routeName = '/attraction-details';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 1,
        onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Attraction Details', style: TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border_rounded)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Stack(
                  children: [
                    Center(child: Icon(Icons.account_balance_rounded, size: 92, color: Color(0xFF79571E))),
                    Positioned(
                      left: 14,
                      bottom: 13,
                      child: _PhotoTag(label: '1 / 8 photos'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Old Town Square', style: TextStyle(color: Color(0xFF131B2E), fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Historical Landmark · Kuala Lumpur', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 19),
                  Text(' 4.9 ', style: TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
                  Text('(1,248 reviews)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Spacer(),
                  _CrowdBadge(),
                ],
              ),
              const SizedBox(height: 18),
              const _InfoCard(
                title: 'About this attraction',
                body: 'Explore Kuala Lumpur’s historic Old Town quarter, heritage buildings and vibrant cultural spaces at your own pace.',
              ),
              const SizedBox(height: 14),
              const _InfoCard(
                title: 'Opening hours',
                body: 'Open today · 08:00 AM – 08:00 PM\nLast entry at 07:30 PM',
                icon: Icons.schedule_outlined,
              ),
              const SizedBox(height: 14),
              const _InfoCard(
                title: 'Facilities',
                body: 'Restrooms · Prayer room · Wheelchair access · Parking',
                icon: Icons.accessible_forward_rounded,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available visit slots', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),
              const _SlotTile(time: '10:00 – 11:30', remaining: '12 spaces left', crowd: 'Moderate'),
              const SizedBox(height: 9),
              const _SlotTile(time: '12:00 – 01:30', remaining: '3 spaces left', crowd: 'High'),
              const SizedBox(height: 9),
              const _SlotTile(time: '04:00 – 05:30', remaining: '18 spaces left', crowd: 'Low'),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, SmartRecommendationsPage.routeName),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('View smarter alternatives'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.confirmation_num_outlined),
                  label: const Text('Choose a Visit Slot'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD08B), foregroundColor: const Color(0xFF79571E)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _PhotoTag extends StatelessWidget {
  const _PhotoTag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
  );
}

class _CrowdBadge extends StatelessWidget {
  const _CrowdBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFE8F7EE), borderRadius: BorderRadius.circular(999)),
    child: const Text('MODERATE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body, this.icon});
  final String title;
  final String body;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0x33D2C4B4)), borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [if (icon != null) ...[Icon(icon, size: 19, color: const Color(0xFF79571E)), const SizedBox(width: 7)], Text(title, style: const TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700))]),
      const SizedBox(height: 8),
      Text(body, style: const TextStyle(color: Color(0xFF4F4539), fontSize: 12, height: 1.45)),
    ]),
  );
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.time, required this.remaining, required this.crowd});
  final String time;
  final String remaining;
  final String crowd;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD2C4B4)), borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      const Icon(Icons.schedule_outlined, color: Color(0xFF79571E)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: const TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)), Text(remaining, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10))])),
      Text(crowd, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );
}
