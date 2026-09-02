import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import 'smart_recommendations_page.dart';
import 'time_slot_selection_page.dart';

class AttractionDetailsPage extends StatefulWidget {
  const AttractionDetailsPage({super.key});

  static const routeName = '/user/attraction-details';

  @override
  State<AttractionDetailsPage> createState() => _AttractionDetailsPageState();
}

class _AttractionDetailsPageState extends State<AttractionDetailsPage> {
  final AttractionService _attractionService = AttractionService();
  Future<Attraction?>? _attractionFuture;
  String? _loadedForId;

  Color _colorForCrowdLevel(String crowdLevel) {
    switch (crowdLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFF16A34A);
      case 'high':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return Icons.local_florist_rounded;
      case 'history':
        return Icons.account_balance_rounded;
      case 'food & culture':
        return Icons.directions_walk_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attractionId = ModalRoute.of(context)!.settings.arguments as String?;

    // Only refetch if the id actually changed (avoids refetching on every rebuild)
    if (attractionId != null && attractionId != _loadedForId) {
      _loadedForId = attractionId;
      _attractionFuture = _attractionService.getAttractionById(attractionId);
    }

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
        child: attractionId == null
            ? const Center(child: Text('No attraction selected.'))
            : FutureBuilder<Attraction?>(
          future: _attractionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final attraction = snapshot.data;
            if (attraction == null) {
              return const Center(child: Text('Attraction not found.'));
            }

            return SingleChildScrollView(
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
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _iconForCategory(attraction.category),
                            size: 92,
                            color: const Color(0xFF79571E),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 13,
                          child: _PhotoTag(
                            label: '${attraction.imageUrls.length} photos',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(attraction.name, style: const TextStyle(color: Color(0xFF131B2E), fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${attraction.category} · ${attraction.location}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 19),
                      Text(' ${attraction.rating} ', style: const TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
                      Text(
                        attraction.price == 0 ? 'Free entry' : 'From RM ${attraction.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                      const Spacer(),
                      _CrowdBadge(
                        label: attraction.crowdLevel.toUpperCase(),
                        color: _colorForCrowdLevel(attraction.crowdLevel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _InfoCard(
                    title: 'About this attraction',
                    body: attraction.description.isEmpty
                        ? 'No description available yet.'
                        : attraction.description,
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: 'Opening hours',
                    body: attraction.openingHours.isEmpty
                        ? 'Hours not specified'
                        : attraction.openingHours,
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: 'Facilities',
                    body: attraction.facilities.isEmpty
                        ? 'No facilities listed'
                        : attraction.facilities.join(' · '),
                    icon: Icons.accessible_forward_rounded,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available visit slots', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, TimeSlotSelectionPage.routeName),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  _SlotTile(
                    time: 'Slots managed in Module 3',
                    remaining: '${attraction.availableSlots} spaces left',
                    crowd: attraction.crowdLevel,
                  ),
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
                      onPressed: () => Navigator.pushNamed(context, TimeSlotSelectionPage.routeName),
                      icon: const Icon(Icons.confirmation_num_outlined),
                      label: const Text('Choose a Visit Slot'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD08B), foregroundColor: const Color(0xFF79571E)),
                    ),
                  ),
                ],
              ),
            );
          },
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
  const _CrowdBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
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