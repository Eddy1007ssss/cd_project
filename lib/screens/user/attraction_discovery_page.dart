import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import 'attraction_comparison_page.dart';
import 'attraction_details_page.dart';
import 'discovery_preferences_page.dart';
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
  final _service = AttractionService();
  final _locationService = LocationService();
  final _search = TextEditingController();
  final _selectedForComparison = <String>{};
  Timer? _debounce;
  LocationPoint? _origin;
  AttractionFilters _filters = const AttractionFilters();
  late Future<List<Attraction>> _results;

  @override
  void initState() {
    super.initState();
    _results = _initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<List<Attraction>> _initialize() async {
    _origin = await _locationService.currentLocation();
    return _service.searchAndFilter(origin: _origin);
  }

  Future<List<Attraction>> _query() => _service.searchAndFilter(
    keyword: _search.text,
    filters: _filters,
    origin: _origin,
  );

  void _reload() => setState(() => _results = _query());

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  Future<void> _showFilters() async {
    var price = _filters.maximumPrice;
    var distance = _filters.maximumDistanceKm;
    var crowd = _filters.crowdLevel;
    var openNow = _filters.openNow;
    final result = await showModalBottomSheet<AttractionFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discovery filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<double?>(
                  initialValue: price,
                  decoration: const InputDecoration(
                    labelText: 'Maximum price',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any price')),
                    DropdownMenuItem(value: 10, child: Text('Up to RM10')),
                    DropdownMenuItem(value: 25, child: Text('Up to RM25')),
                    DropdownMenuItem(value: 50, child: Text('Up to RM50')),
                  ],
                  onChanged: (value) => setSheetState(() => price = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<double?>(
                  initialValue: distance,
                  decoration: const InputDecoration(
                    labelText: 'Maximum distance',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any distance')),
                    DropdownMenuItem(value: 3, child: Text('Within 3 km')),
                    DropdownMenuItem(value: 10, child: Text('Within 10 km')),
                    DropdownMenuItem(value: 25, child: Text('Within 25 km')),
                  ],
                  onChanged: (value) => setSheetState(() => distance = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: crowd,
                  decoration: const InputDecoration(
                    labelText: 'Estimated crowd',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Any crowd level'),
                    ),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(
                      value: 'Moderate',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) => setSheetState(() => crowd = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: openNow,
                  onChanged: (value) => setSheetState(() => openNow = value),
                  title: const Text('Open now'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      AttractionFilters(
                        maximumPrice: price,
                        maximumDistanceKm: distance,
                        crowdLevel: crowd,
                        openNow: openNow,
                      ),
                    ),
                    child: const Text('Apply filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      _filters = result;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Discover Attractions'),
      actions: [
        IconButton(
          tooltip: 'Preferences',
          onPressed: () =>
              Navigator.pushNamed(context, DiscoveryPreferencesPage.routeName),
          icon: const Icon(Icons.tune_rounded),
        ),
        IconButton(
          tooltip: 'Recommendations',
          onPressed: () =>
              Navigator.pushNamed(context, SmartRecommendationsPage.routeName),
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        IconButton(
          tooltip: 'Nearby',
          onPressed: () =>
              Navigator.pushNamed(context, NearbyAttractionsPage.routeName),
          icon: const Icon(Icons.near_me_outlined),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_service.isDemoMode)
            const Card(
              color: Color(0xFFFFE7C2),
              child: ListTile(
                leading: Icon(Icons.science_outlined),
                title: Text(
                  'Module 2 demo mode',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'No login is required. Preference changes last until the app restarts.',
                ),
              ),
            ),
          TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search name, category or location',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        _reload();
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.filter_list),
                  label: Text(_filters.isActive ? 'Filters active' : 'Filters'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    NearbyAttractionsPage.routeName,
                  ),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Near me'),
                ),
              ),
            ],
          ),
          if (_origin != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _origin!.isFallback
                    ? 'Distance origin: ${_origin!.label}'
                    : 'Using ${_origin!.label}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          const SizedBox(height: 14),
          const Card(
            color: Color(0xFFF2F3FF),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Color(0xFF79571E)),
              title: Text('Crowd labels are slot occupancy estimates'),
              subtitle: Text(
                'Live visitor counts will come from Module 4. Ratings are not fabricated.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Attraction>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _ErrorCard(
                  message: '${snapshot.error}',
                  onRetry: _reload,
                );
              }
              final attractions = snapshot.data ?? const [];
              if (attractions.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No approved attractions match these filters.',
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: attractions
                    .map(
                      (attraction) => _AttractionCard(
                        attraction: attraction,
                        selected: _selectedForComparison.contains(
                          attraction.id,
                        ),
                        imageUrl: attraction.coverImageUrl,
                        onCompare: (selected) {
                          if (selected && _selectedForComparison.length >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Compare up to three attractions.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(
                            () => selected
                                ? _selectedForComparison.add(attraction.id)
                                : _selectedForComparison.remove(attraction.id),
                          );
                        },
                        onTap: () => Navigator.pushNamed(
                          context,
                          AttractionDetailsPage.routeName,
                          arguments: attraction.id,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    ),
    floatingActionButton: _selectedForComparison.length < 2
        ? null
        : FloatingActionButton.extended(
            onPressed: () async {
              final all = await _results;
              if (!context.mounted) return;
              Navigator.pushNamed(
                context,
                AttractionComparisonPage.routeName,
                arguments: all
                    .where((item) => _selectedForComparison.contains(item.id))
                    .toList(),
              );
            },
            icon: const Icon(Icons.compare_arrows),
            label: Text('Compare ${_selectedForComparison.length}'),
          ),
    bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
  );
}

class _AttractionCard extends StatelessWidget {
  const _AttractionCard({
    required this.attraction,
    required this.selected,
    required this.imageUrl,
    required this.onCompare,
    required this.onTap,
  });
  final Attraction attraction;
  final bool selected;
  final String? imageUrl;
  final ValueChanged<bool> onCompare;
  final VoidCallback onTap;

  Color get crowdColor => switch (attraction.estimatedCrowdLevel) {
    'Low' => Colors.green,
    'Moderate' => Colors.amber.shade800,
    'High' => Colors.orange.shade800,
    'Critical' => Colors.red,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl == null
                  ? Container(
                      width: 82,
                      height: 100,
                      color: const Color(0xFFFFE2B5),
                      child: const Icon(Icons.place_outlined),
                    )
                  : Image.network(
                      imageUrl!,
                      width: 82,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 82,
                        height: 100,
                        color: const Color(0xFFFFE2B5),
                        child: const Icon(Icons.place_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attraction.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${attraction.category} · ${attraction.locationName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    attraction.entrancePriceMyr == 0
                        ? 'Free entry'
                        : 'RM ${attraction.entrancePriceMyr.toStringAsFixed(2)}',
                  ),
                  Text(
                    attraction.distanceKm == null
                        ? 'Distance unavailable'
                        : '${attraction.distanceKm!.toStringAsFixed(1)} km away',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          '${attraction.estimatedCrowdLevel} estimate',
                          style: TextStyle(color: crowdColor, fontSize: 10),
                        ),
                        side: BorderSide.none,
                        backgroundColor: crowdColor.withValues(alpha: .1),
                      ),
                      Chip(
                        label: Text(
                          '${attraction.availableSlots.length} slots',
                          style: const TextStyle(fontSize: 10),
                        ),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const Text(
                    'No ratings yet',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (value) => onCompare(value ?? false),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFEDEA),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Could not load approved attractions.'),
          Text(message, style: const TextStyle(fontSize: 11)),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
