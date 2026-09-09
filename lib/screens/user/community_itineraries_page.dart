import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../models/published_itinerary.dart';
import '../../repositories/module3_repository.dart';
import '../../services/attraction_service.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'attraction_details_page.dart';

class CommunityItinerariesPage extends StatefulWidget {
  const CommunityItinerariesPage({super.key});

  static const routeName = TourFlowRoutes.communityItineraries;

  @override
  State<CommunityItinerariesPage> createState() =>
      _CommunityItinerariesPageState();
}

class _CommunityItinerariesPageState
    extends State<CommunityItinerariesPage> {
  final _repository = Module3Repository();
  final _search = TextEditingController();
  late Future<List<PublishedItinerary>> _results;

  @override
  void initState() {
    super.initState();
    _results = _repository.fetchPublishedItineraries();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _repository.fetchPublishedItineraries();
    setState(() => _results = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: UserSidebar(
      displayName: '',
      email: '',
      selectedIndex: 7,
      onLogout: () async => signOutAndReturnToSignIn(context),
    ),
    appBar: AppBar(title: const Text('Discover Itineraries')),
    body: FutureBuilder<List<PublishedItinerary>>(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading itineraries'),
            ),
          );
        }
        final query = _search.text.trim().toLowerCase();
        final rows = (snapshot.data ?? const <PublishedItinerary>[])
            .where((item) => query.isEmpty ||
                item.title.toLowerCase().contains(query) ||
                item.stops.any((stop) =>
                    stop.attractionName.toLowerCase().contains(query)))
            .toList();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                color: Color(0xFFFFF6E8),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Only an itinerary title, optional author name, visit times '
                    'and attractions are shared. Booking codes, QR tickets and '
                    'contact details are never published.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search itinerary or attraction',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No shared itineraries found.')),
                )
              else
                ...rows.map((item) => _ItineraryCard(itinerary: item)),
            ],
          ),
        );
      },
    ),
  );
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({required this.itinerary});

  final PublishedItinerary itinerary;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      leading: const CircleAvatar(child: Icon(Icons.route_outlined)),
      title: Text(
        itinerary.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_date(itinerary.date)} · ${itinerary.stops.length} stops'
        '${itinerary.authorName == null ? '' : ' · by ${itinerary.authorName}'}',
      ),
      children: [
        if (itinerary.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(itinerary.description),
            ),
          ),
        ...List.generate(itinerary.stops.length, (index) {
          final stop = itinerary.stops[index];
          return Column(
            children: [
              if (index > 0)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.directions_car_outlined),
                  title: Text(
                    stop.travelMinutesFromPrevious == null
                        ? 'Travel time unavailable'
                        : '${stop.travelMinutesFromPrevious} min travel',
                  ),
                  subtitle: stop.distanceKmFromPrevious == null
                      ? null
                      : Text('${stop.distanceKmFromPrevious!.toStringAsFixed(1)} km'),
                ),
              ListTile(
                leading: _StopImage(stop: stop),
                title: Text(stop.attractionName),
                subtitle: Text(
                  '${_time(stop.startsAt)}–${_time(stop.endsAt)} · '
                  '${stop.category} · ${stop.locationName}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AttractionDetailsPage.routeName,
                  arguments: stop.attractionId,
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _StopImage extends StatelessWidget {
  const _StopImage({required this.stop});

  final PublishedItineraryStop stop;

  @override
  Widget build(BuildContext context) {
    final service = AttractionService();
    final url = stop.coverImageUrl?.trim().isNotEmpty == true
        ? stop.coverImageUrl
        : stop.storageImagePath == null
            ? null
            : service.publicImageUrl(stop.storageImagePath!);
    final fallback = attractionFallbackAsset(stop.attractionName);
    Widget placeholder() => const ColoredBox(
      color: Color(0xFFFFE2B5),
      child: SizedBox.square(dimension: 46, child: Icon(Icons.place_outlined)),
    );
    Widget local() => fallback == null
        ? placeholder()
        : Image.asset(fallback, width: 46, height: 46, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? local()
          : Image.network(
              url,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => local(),
            ),
    );
  }
}

String _time(String value) {
  final parts = value.split(':');
  return parts.length < 2 ? value : '${parts[0]}:${parts[1]}';
}

String _date(DateTime value) =>
    '${value.day}/${value.month}/${value.year}';
