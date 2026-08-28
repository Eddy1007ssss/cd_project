import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';

/// Static tourist home page.
///
/// This file contains no Supabase or API calls. Register the route names in
/// main.dart and replace the static values with database values later.
class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  static const String routeName = '/user/home';

  static const List<String> _navigationRoutes = [
    '/user/home',
    '/attraction-discovery',
    '/user/trips',
    '/user/chat',
    '/profile-security',
  ];

  void _changePage(BuildContext context, int index) {
    if (index == 0) {
      return;
    }

    Navigator.pushReplacementNamed(context, _navigationRoutes[index]);
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 0,
        onItemSelected: (index) => _changePage(context, index),
        onLogout: () => _logout(context),
      ),
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        shadowColor: const Color(0x140F172A),
        backgroundColor: const Color(0xFFFAF8FF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF7A581F),
        title: const Text(
          'TourFlow',
          style: TextStyle(
            color: Color(0xFF7A581F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => _changePage(context, 1),
            icon: const Icon(Icons.search_rounded, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchAndCategories(
                onSearchPressed: () => _changePage(context, 1),
              ),
              const SizedBox(height: 30),
              _SectionHeader(
                eyebrow: "EDITOR'S CHOICE",
                title: 'Recommended for You',
                onViewAll: () => _changePage(context, 1),
              ),
              const SizedBox(height: 14),
              const _RecommendedAttractions(),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(
                  eyebrow: 'TRENDING NOW',
                  title: 'Popular in Kuala Lumpur',
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _FeaturedAttractionCard(),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _CompactAttractionCard(
                  name: 'Jalan Alor Food Street',
                  location: 'Bukit Bintang',
                  rating: '4.5',
                  crowdText: 'BUSY',
                  crowdColor: Color(0xFFF59E0B),
                  icon: Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _CompactAttractionCard(
                  name: 'Pavilion Shopping Mall',
                  location: 'City Center',
                  rating: '4.6',
                  crowdText: 'LIGHT',
                  crowdColor: Color(0xFF16A34A),
                  icon: Icons.shopping_bag_rounded,
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _CrowdLevelGuide(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: UserBottomNavigationBar(
        selectedIndex: 0,
        onItemSelected: (index) => _changePage(context, index),
      ),
    );
  }
}

class _SearchAndCategories extends StatelessWidget {
  const _SearchAndCategories({required this.onSearchPressed});

  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All Categories',
      'Landmarks',
      'Food & Dining',
      'Shopping',
      'Nature',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: onSearchPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD2C4B4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: Color(0xFF6B7280)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search Kuala Lumpur attractions...',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      ),
                    ),
                    Icon(Icons.tune_rounded, size: 20, color: Color(0xFF4F4539)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFD08B)
                        : const Color(0xFFEAEDFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF79571E)
                          : const Color(0xFF4F4539),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.onViewAll,
  });

  final String eyebrow;
  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: onViewAll == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xFF7A581F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'View all',
                style: TextStyle(color: Color(0xFF7A581F), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendedAttractions extends StatelessWidget {
  const _RecommendedAttractions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: const [
          _RecommendedCard(
            name: 'Petronas Twin Towers',
            distance: '1.2 km away',
            category: 'Landmark',
            rating: '4.9',
            crowdText: 'LOW CROWD',
            crowdColor: Color(0xFF16A34A),
            backgroundColors: [Color(0xFF0B315E), Color(0xFF3795C9)],
            icon: Icons.apartment_rounded,
          ),
          SizedBox(width: 16),
          _RecommendedCard(
            name: 'Batu Caves',
            distance: '12.5 km away',
            category: 'Nature',
            rating: '4.7',
            crowdText: 'MODERATE',
            crowdColor: Color(0xFFF97316),
            backgroundColors: [Color(0xFF315B31), Color(0xFFA6C76A)],
            icon: Icons.landscape_rounded,
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.name,
    required this.distance,
    required this.category,
    required this.rating,
    required this.crowdText,
    required this.crowdColor,
    required this.backgroundColors,
    required this.icon,
  });

  final String name;
  final String distance;
  final String category;
  final String rating;
  final String crowdText;
  final Color crowdColor;
  final List<Color> backgroundColors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundColors,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, size: 92, color: Colors.white.withOpacity(0.88))),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _RatingBadge(rating: rating),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _CrowdBadge(text: crowdText, color: crowdColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(color: Color(0xFF131B2E), fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF4F4539)),
              const SizedBox(width: 4),
              Text(
                '$distance  •  $category',
                style: const TextStyle(color: Color(0xFF4F4539), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedAttractionCard extends StatelessWidget {
  const _FeaturedAttractionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF76B6DA), Color(0xFF173F2C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 28,
            child: Icon(Icons.park_rounded, size: 130, color: Colors.white.withOpacity(0.28)),
          ),
          const Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CrowdBadge(text: 'VERY BUSY', color: Color(0xFFDC2626)),
                SizedBox(height: 8),
                Text(
                  'KL Tower & Eco Park',
                  style: TextStyle(color: Colors.white, fontSize: 25, height: 1.05, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Expanded(child: Text('Bukit Nanas, KL', style: TextStyle(color: Colors.white, fontSize: 12))),
                    Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFD166)),
                    SizedBox(width: 3),
                    Text('4.8', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAttractionCard extends StatelessWidget {
  const _CompactAttractionCard({
    required this.name,
    required this.location,
    required this.rating,
    required this.crowdText,
    required this.crowdColor,
    required this.icon,
  });

  final String name;
  final String location;
  final String rating;
  final String crowdText;
  final Color crowdColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x4DD2C4B4)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x120F172A), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 38, color: const Color(0xFF7A581F)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFF131B2E), fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_city_rounded, size: 13, color: Color(0xFF4F4539)),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(color: Color(0xFF4F4539), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CrowdBadge(text: crowdText, color: crowdColor),
                    _RatingBadge(rating: rating),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFACC15)),
          const SizedBox(width: 2),
          Text(rating, style: const TextStyle(color: Color(0xFF131B2E), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CrowdBadge extends StatelessWidget {
  const _CrowdBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CrowdLevelGuide extends StatelessWidget {
  const _CrowdLevelGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33D2C4B4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF4F4539)),
              SizedBox(width: 8),
              Text('CROWD LEVEL GUIDE', style: TextStyle(color: Color(0xFF4F4539), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _GuideItem(color: Color(0xFF16A34A), text: 'Low: < 25%')),
              Expanded(child: _GuideItem(color: Color(0xFFF97316), text: 'Mod: 25-60%')),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _GuideItem(color: Color(0xFFF59E0B), text: 'Busy: 60-85%')),
              Expanded(child: _GuideItem(color: Color(0xFFDC2626), text: 'Peak: > 85%')),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: Color(0xFF131B2E), fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
