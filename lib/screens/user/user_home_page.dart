import 'package:flutter/material.dart';

import '../../l10n/tourflow_localization.dart';
import '../../models/attraction.dart';
import '../../models/module3_models.dart';
import '../../models/recommendation_result.dart';
import '../../repositories/module3_repository.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import '../../widgets/attraction_image.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/navigation/navigation_scope.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'attraction_details_page.dart';
import 'itinerary_planner_page.dart';
import 'nearby_attractions_page.dart';
import 'smart_recommendations_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  static const routeName = TourFlowRoutes.userHome;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _attractionService = AttractionService();
  final _bookingRepository = Module3Repository();
  late Future<_HomeData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_HomeData> _load() async {
    final origin = await LocationService().currentLocation();
    final attractions = await _attractionService.getApprovedAttractions(
      origin: origin,
    );

    List<RecommendationResult> recommendations;
    try {
      recommendations = await _attractionService.getRecommendations(
        origin: origin,
      );
    } catch (_) {
      recommendations = attractions
          .map((item) => RecommendationResult(
                attraction: item,
                score: item.averageRating * 20,
                reasons: const ['Available to explore'],
              ))
          .toList();
    }

    TourBooking? upcoming;
    try {
      final bookings = (await _bookingRepository.fetchBookings())
          .where((item) => item.isUpcoming)
          .toList()
        ..sort((a, b) => a.slot.startsAt.compareTo(b.slot.startsAt));
      upcoming = bookings.isEmpty ? null : bookings.first;
    } catch (_) {
      upcoming = null;
    }

    final rated = attractions.where((item) => item.hasRatings).toList()
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    final quieter = attractions
        .where((item) =>
            item.availableSlots.isNotEmpty &&
            (item.crowdLevel == 'Low' || item.crowdLevel == 'Moderate'))
        .toList()
      ..sort((a, b) => _crowdRank(a).compareTo(_crowdRank(b)));

    return _HomeData(
      origin: origin,
      upcoming: upcoming,
      recommended: recommendations.map((item) => item.attraction).take(6).toList(),
      rated: rated.take(6).toList(),
      quieter: quieter.take(6).toList(),
    );
  }

  int _crowdRank(Attraction attraction) => switch (attraction.crowdLevel) {
    'Low' => 0,
    'Moderate' => 1,
    'High' => 2,
    'Critical' => 3,
    _ => 4,
  };

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  void _selectTab(int index) {
    TourFlowNavigationScope.maybeOf(context)?.onItemSelected(index);
  }

  void _open(Attraction attraction) {
    Navigator.pushNamed(
      context,
      AttractionDetailsPage.routeName,
      arguments: attraction.id,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F8),
    drawer: UserSidebar(
      displayName: '',
      email: '',
      selectedIndex: 0,
      onLogout: () async => signOutAndReturnToSignIn(context),
    ),
    appBar: AppBar(
      title: const TourFlowText('TourFlow'),
      actions: [
        IconButton(
          onPressed: () => _selectTab(1),
          icon: const Icon(Icons.search),
          tooltip: context.tr('Search attractions'),
        ),
      ],
    ),
    body: FutureBuilder<_HomeData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const TourFlowText('Retry loading home'),
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                color: const Color(0xFFFFF6E8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.origin.isFallback
                          ? 'Explore Penang'
                          : 'Near ${data.origin.label}',
                      style: const TextStyle(color: Color(0xFF79571E)),
                    ),
                    const TourFlowText(
                      'Where will you go next?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _selectTab(1),
                      icon: const Icon(Icons.search),
                      label: const TourFlowText('Search attractions and locations'),
                    ),
                  ],
                ),
              ),
              if (data.upcoming != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    color: const Color(0xFFFFD08B),
                    child: ListTile(
                      onTap: () => _selectTab(2),
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text(
                        data.upcoming!.slot.attractionName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${shortDate(data.upcoming!.slot.startsAt)} · '
                        '${slotTime(data.upcoming!.slot)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              _HomeSection(
                title: 'Recommended for you',
                subtitle: 'Based on your preferences, visits and budget',
                attractions: data.recommended,
                onTap: _open,
                onViewAll: () => Navigator.pushNamed(
                  context,
                  SmartRecommendationsPage.routeName,
                ),
              ),
              _HomeSection(
                title: 'Highly rated',
                subtitle: 'Aggregate ratings from completed visits',
                attractions: data.rated,
                onTap: _open,
                onViewAll: () => _selectTab(1),
              ),
              _HomeSection(
                title: 'Quieter choices',
                subtitle: 'Lower live crowd with future slots',
                attractions: data.quieter,
                onTap: _open,
                onViewAll: () => Navigator.pushNamed(
                  context,
                  NearbyAttractionsPage.routeName,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    ItineraryPlannerPage.routeName,
                  ),
                  icon: const Icon(Icons.route_outlined),
                  label: const TourFlowText('Plan or discover an itinerary'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _HomeData {
  const _HomeData({
    required this.origin,
    required this.upcoming,
    required this.recommended,
    required this.rated,
    required this.quieter,
  });

  final LocationPoint origin;
  final TourBooking? upcoming;
  final List<Attraction> recommended;
  final List<Attraction> rated;
  final List<Attraction> quieter;
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.subtitle,
    required this.attractions,
    required this.onTap,
    required this.onViewAll,
  });

  final String title;
  final String subtitle;
  final List<Attraction> attractions;
  final ValueChanged<Attraction> onTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TourFlowText(title, style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800,
                    )),
                    TourFlowText(subtitle, style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 12,
                    )),
                  ],
                ),
              ),
              TextButton(onPressed: onViewAll, child: const TourFlowText('View all')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (attractions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TourFlowText('No matching attractions available yet.'),
          )
        else
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: attractions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final attraction = attractions[index];
                return SizedBox(
                  width: 245,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onTap(attraction),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AttractionImageView(
                            attraction: attraction,
                            width: 245,
                            height: 140,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attraction.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '★ ${attraction.ratingLabel} · '
                                  '${attraction.crowdLevel} · '
                                  '${attraction.currentVisitors} inside',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
