import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'attraction_details_page.dart';
import 'nearby_attractions_page.dart';
import 'smart_recommendations_page.dart';

class AttractionDiscoveryPage extends StatefulWidget {
  const AttractionDiscoveryPage({super.key});

  static const routeName = '/attraction-discovery';

  @override
  State<AttractionDiscoveryPage> createState() =>
      _AttractionDiscoveryPageState();
}

class _AttractionDiscoveryPageState extends State<AttractionDiscoveryPage> {
  int _selectedCategory = 0;

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
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover Attractions',
              style: TextStyle(
                color: Color(0xFF131B2E),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'TOURFLOW · EXPLORE',
              style: TextStyle(
                color: Color(0xFF79571E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recommendations',
            onPressed: () => Navigator.pushNamed(
              context,
              SmartRecommendationsPage.routeName,
            ),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          IconButton(
            tooltip: 'Nearby attractions',
            onPressed: () => Navigator.pushNamed(
              context,
              NearbyAttractionsPage.routeName,
            ),
            icon: const Icon(Icons.near_me_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD2C4B4)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: Color(0xFF79571E)),
                    hintText: 'Search attraction, place or activity',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionFilter(
                      icon: Icons.tune_rounded,
                      label: 'Filters',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _ActionFilter(
                      icon: Icons.location_on_outlined,
                      label: 'Near me',
                      onTap: () => Navigator.pushNamed(
                        context,
                        NearbyAttractionsPage.routeName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _ActionFilter(
                      icon: Icons.schedule_outlined,
                      label: 'Open now',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Explore by category',
                style: TextStyle(
                  color: Color(0xFF131B2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == 0,
                      onTap: () => setState(() => _selectedCategory = 0),
                    ),
                    _CategoryChip(
                      label: 'History',
                      selected: _selectedCategory == 1,
                      onTap: () => setState(() => _selectedCategory = 1),
                    ),
                    _CategoryChip(
                      label: 'Nature',
                      selected: _selectedCategory == 2,
                      onTap: () => setState(() => _selectedCategory = 2),
                    ),
                    _CategoryChip(
                      label: 'Family',
                      selected: _selectedCategory == 3,
                      onTap: () => setState(() => _selectedCategory = 3),
                    ),
                    _CategoryChip(
                      label: 'Food & Culture',
                      selected: _selectedCategory == 4,
                      onTap: () => setState(() => _selectedCategory = 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _InsightBanner(),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular near Kuala Lumpur',
                    style: TextStyle(
                      color: Color(0xFF131B2E),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View map'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _AttractionCard(
                name: 'Old Town Square',
                category: 'Historical Landmark',
                location: 'Kuala Lumpur City Centre · 1.2 km',
                rating: '4.9',
                price: 'Free entry',
                crowd: 'Moderate crowd',
                crowdColor: const Color(0xFF65A30D),
                icon: Icons.account_balance_rounded,
                onTap: () => Navigator.pushNamed(
                  context,
                  AttractionDetailsPage.routeName,
                ),
              ),
              const SizedBox(height: 12),
              _AttractionCard(
                name: 'Lumina Botanical Gardens',
                category: 'Nature & Photography',
                location: 'Perdana Botanical Gardens · 2.8 km',
                rating: '4.8',
                price: 'From RM 12',
                crowd: 'Low crowd',
                crowdColor: const Color(0xFF16A34A),
                icon: Icons.local_florist_rounded,
                onTap: () => Navigator.pushNamed(
                  context,
                  AttractionDetailsPage.routeName,
                ),
              ),
              const SizedBox(height: 12),
              _AttractionCard(
                name: 'Heritage Walking Tour',
                category: 'Guided Cultural Tour',
                location: 'Merdeka Square · 3.1 km',
                rating: '4.8',
                price: 'From RM 35',
                crowd: 'High crowd',
                crowdColor: const Color(0xFFF59E0B),
                icon: Icons.directions_walk_rounded,
                onTap: () => Navigator.pushNamed(
                  context,
                  AttractionDetailsPage.routeName,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: UserBottomNavigationBar(
        selectedIndex: 1,
      ),
    );
  }
}

class _ActionFilter extends StatelessWidget {
  const _ActionFilter({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF79571E),
        side: const BorderSide(color: Color(0xFFD2C4B4)),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFFFCC87),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF79571E) : const Color(0xFF4F4539),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFD2C4B4)),
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFFFD08B),
            foregroundColor: Color(0xFF79571E),
            child: Icon(Icons.auto_awesome_rounded),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart suggestion', style: TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Nature attractions are quieter before 11:00 AM today.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttractionCard extends StatelessWidget {
  const _AttractionCard({
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.price,
    required this.crowd,
    required this.crowdColor,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String category;
  final String location;
  final String rating;
  final String price;
  final String crowd;
  final Color crowdColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x33D2C4B4)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 36, color: const Color(0xFF79571E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Color(0xFF131B2E), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(category, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    const SizedBox(height: 7),
                    Text(location, style: const TextStyle(color: Color(0xFF4F4539), fontSize: 10)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                        Text(' $rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(price, style: const TextStyle(color: Color(0xFF4F4539), fontSize: 10))),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(crowd, style: TextStyle(color: crowdColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}
