import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'attraction_details_page.dart';

class SmartRecommendationsPage extends StatelessWidget {
  const SmartRecommendationsPage({super.key});

  static const routeName = '/smart-recommendations';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(displayName: 'Alex Tan', email: 'alex@example.com', selectedIndex: 1, onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false)),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Smart Recommendations', style: TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(17)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [CircleAvatar(backgroundColor: Color(0xFFFFD08B), foregroundColor: Color(0xFF79571E), child: Icon(Icons.auto_awesome_rounded)), SizedBox(width: 10), Text('Picked for you, Alex', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w800))]),
                SizedBox(height: 10),
                Text('Based on your interest in history, nature, your budget and your current location.', style: TextStyle(color: Color(0xFF4F4539), fontSize: 12, height: 1.45)),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('Best matches today', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 11),
            _RecommendationCard(
              rank: '98%',
              name: 'Lumina Botanical Gardens',
              reason: 'Matches your nature interest and has low crowd levels now.',
              time: 'Best time: 09:00 – 11:00',
              icon: Icons.local_florist_rounded,
              onTap: () => Navigator.pushNamed(context, AttractionDetailsPage.routeName),
            ),
            const SizedBox(height: 12),
            _RecommendationCard(
              rank: '93%',
              name: 'Old Town Square',
              reason: 'Popular history stop near your current location.',
              time: 'Best time: 04:00 – 05:30',
              icon: Icons.account_balance_rounded,
              onTap: () => Navigator.pushNamed(context, AttractionDetailsPage.routeName),
            ),
            const SizedBox(height: 22),
            const Text('Avoid the crowd', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const _AlternativeTile(
              title: 'Heritage Walking Tour is busy at 12:00 PM',
              suggestion: 'Try the 04:00 PM slot — 18 spaces available.',
              icon: Icons.schedule_outlined,
            ),
            const SizedBox(height: 10),
            const _AlternativeTile(
              title: 'National Museum is at high crowd level',
              suggestion: 'Visit Old Town Square nearby instead.',
              icon: Icons.swap_horiz_rounded,
            ),
            const SizedBox(height: 22),
            const Text('Plan a better day', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x33D2C4B4))),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Suggested mini itinerary', style: TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('09:30  Lumina Botanical Gardens', style: TextStyle(color: Color(0xFF4F4539), fontSize: 12)),
                SizedBox(height: 7),
                Text('12:00  Lunch near Perdana Gardens', style: TextStyle(color: Color(0xFF4F4539), fontSize: 12)),
                SizedBox(height: 7),
                Text('04:00  Old Town Square', style: TextStyle(color: Color(0xFF4F4539), fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rank, required this.name, required this.reason, required this.time, required this.icon, required this.onTap});
  final String rank;
  final String name;
  final String reason;
  final String time;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: const Color(0x33D2C4B4)), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 66, height: 72, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF79571E), size: 34)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(name, style: const TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700))), Text(rank, style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800))]),
            const SizedBox(height: 5), Text(reason, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, height: 1.35)),
            const SizedBox(height: 8), Text(time, style: const TextStyle(color: Color(0xFF79571E), fontSize: 10, fontWeight: FontWeight.w700)),
          ])),
        ]),
      ),
    ),
  );
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.title, required this.suggestion, required this.icon});
  final String title;
  final String suggestion;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(13)),
    child: Row(children: [Icon(icon, color: const Color(0xFF79571E)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF131B2E), fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(suggestion, style: const TextStyle(color: Color(0xFF4F4539), fontSize: 10))]))]),
  );
}
