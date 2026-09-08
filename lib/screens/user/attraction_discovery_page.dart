import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'attraction_comparison_page.dart';
import 'attraction_details_page.dart';
import 'discovery_preferences_page.dart';
import 'nearby_attractions_page.dart';
import 'smart_recommendations_page.dart';

// ================================================================
// SORT OPTIONS
// ================================================================

enum _AttractionSort {
  nameAscending,
  priceLowToHigh,
  priceHighToLow,
  nearestFirst,
  crowdLowToHigh,
  mostAvailableSlots,
}

// ================================================================
// PAGE
// ================================================================

class AttractionDiscoveryPage extends StatefulWidget {
  const AttractionDiscoveryPage({super.key});

  static const routeName = TourFlowRoutes.attractionDiscovery;

  @override
  State<AttractionDiscoveryPage> createState() =>
      _AttractionDiscoveryPageState();
}

// ================================================================
// PAGE STATE
// ================================================================

class _AttractionDiscoveryPageState extends State<AttractionDiscoveryPage> {
  final _service = AttractionService();
  final _locationService = LocationService();
  final _search = TextEditingController();

  final Set<String> _selectedForComparison = {};

  Timer? _debounce;

  LocationPoint? _origin;

  AttractionFilters _filters = const AttractionFilters();

  _AttractionSort _sort = _AttractionSort.nameAscending;

  late Future<List<Attraction>> _results;

  // false = list
  // true = map
  bool _mapView = false;

  // ==============================================================
  // INITIALIZE
  // ==============================================================

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

    return _query();
  }

  // ==============================================================
  // SEARCH + FILTER + SORT
  // ==============================================================

  Future<List<Attraction>> _query() async {
    final attractions = await _service.searchAndFilter(
      keyword: _search.text.trim(),
      filters: _filters,
      origin: _origin,
    );

    return _sortAttractions(attractions);
  }

  // ==============================================================
  // SORT ATTRACTIONS
  // ==============================================================

  List<Attraction> _sortAttractions(List<Attraction> attractions) {
    final sorted = List<Attraction>.from(attractions);

    switch (_sort) {
      // ----------------------------------------------------------
      // NAME A-Z
      // ----------------------------------------------------------

      case _AttractionSort.nameAscending:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;

      // ----------------------------------------------------------
      // PRICE LOW-HIGH
      // ----------------------------------------------------------

      case _AttractionSort.priceLowToHigh:
        sorted.sort((a, b) => a.entrancePriceMyr.compareTo(b.entrancePriceMyr));
        break;

      // ----------------------------------------------------------
      // PRICE HIGH-LOW
      // ----------------------------------------------------------

      case _AttractionSort.priceHighToLow:
        sorted.sort((a, b) => b.entrancePriceMyr.compareTo(a.entrancePriceMyr));
        break;

      // ----------------------------------------------------------
      // NEAREST FIRST
      // ----------------------------------------------------------

      case _AttractionSort.nearestFirst:
        sorted.sort((a, b) {
          final aDistance = a.distanceKm;
          final bDistance = b.distanceKm;

          if (aDistance == null && bDistance == null) {
            return 0;
          }

          if (aDistance == null) {
            return 1;
          }

          if (bDistance == null) {
            return -1;
          }

          return aDistance.compareTo(bDistance);
        });
        break;

      // ----------------------------------------------------------
      // CROWD LOW-HIGH
      // ----------------------------------------------------------

      case _AttractionSort.crowdLowToHigh:
        sorted.sort(
          (a, b) => _crowdRank(
            a.estimatedCrowdLevel,
          ).compareTo(_crowdRank(b.estimatedCrowdLevel)),
        );
        break;

      // ----------------------------------------------------------
      // MOST SLOTS
      // ----------------------------------------------------------

      case _AttractionSort.mostAvailableSlots:
        sorted.sort(
          (a, b) => b.availableSlots.length.compareTo(a.availableSlots.length),
        );
        break;
    }

    return sorted;
  }

  int _crowdRank(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return 0;

      case 'moderate':
        return 1;

      case 'high':
        return 2;

      case 'critical':
        return 3;

      default:
        return 4;
    }
  }

  String get _sortLabel {
    switch (_sort) {
      case _AttractionSort.nameAscending:
        return 'Name A → Z';

      case _AttractionSort.priceLowToHigh:
        return 'Price Low → High';

      case _AttractionSort.priceHighToLow:
        return 'Price High → Low';

      case _AttractionSort.nearestFirst:
        return 'Nearest First';

      case _AttractionSort.crowdLowToHigh:
        return 'Low Crowd';

      case _AttractionSort.mostAvailableSlots:
        return 'Most Slots';
    }
  }

  // ==============================================================
  // RELOAD
  // ==============================================================

  void _reload() {
    setState(() {
      _results = _query();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _results = _query();
    });

    await _results;
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  void _onSearch(String value) {
    setState(() {});

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  // ==============================================================
  // FILTER BOTTOM SHEET
  // ==============================================================

  Future<void> _showFilters() async {
    var price = _filters.maximumPrice;

    var distance = _filters.maximumDistanceKm;

    var crowd = _filters.crowdLevel;

    var openNow = _filters.openNow;

    final result = await showModalBottomSheet<AttractionFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Discovery Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setSheetState) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // ======================================
                          // PRICE
                          // ======================================
                          DropdownButtonFormField<double?>(
                            initialValue: price,
                            decoration: const InputDecoration(
                              labelText: 'Maximum price',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem<double?>(
                                value: null,
                                child: Text('Any price'),
                              ),
                              DropdownMenuItem<double?>(
                                value: 10,
                                child: Text('Up to RM10'),
                              ),
                              DropdownMenuItem<double?>(
                                value: 25,
                                child: Text('Up to RM25'),
                              ),
                              DropdownMenuItem<double?>(
                                value: 50,
                                child: Text('Up to RM50'),
                              ),
                            ],
                            onChanged: (value) {
                              setSheetState(() {
                                price = value;
                              });
                            },
                          ),

                          const SizedBox(height: 14),

                          // ======================================
                          // DISTANCE
                          // ======================================
                          DropdownButtonFormField<double?>(
                            initialValue: distance,
                            decoration: const InputDecoration(
                              labelText: 'Maximum distance',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem<double?>(
                                value: null,
                                child: Text('Any distance'),
                              ),
                              DropdownMenuItem<double?>(
                                value: 3,
                                child: Text('Within 3 km'),
                              ),
                              DropdownMenuItem<double?>(
                                value: 10,
                                child: Text('Within 10 km'),
                              ),
                              DropdownMenuItem<double?>(
                                value: 25,
                                child: Text('Within 25 km'),
                              ),
                            ],
                            onChanged: (value) {
                              setSheetState(() {
                                distance = value;
                              });
                            },
                          ),

                          const SizedBox(height: 14),

                          // ======================================
                          // CROWD
                          // ======================================
                          DropdownButtonFormField<String?>(
                            initialValue: crowd,
                            decoration: const InputDecoration(
                              labelText: 'Estimated crowd',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Any crowd level'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'Low',
                                child: Text('Low'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'Moderate',
                                child: Text('Moderate'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'High',
                                child: Text('High'),
                              ),
                            ],
                            onChanged: (value) {
                              setSheetState(() {
                                crowd = value;
                              });
                            },
                          ),

                          const SizedBox(height: 8),

                          // ======================================
                          // OPEN NOW
                          // ======================================
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: openNow,
                            title: const Text('Open now'),
                            subtitle: const Text(
                              'Only show attractions currently open',
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                openNow = value;
                              });
                            },
                          ),

                          const SizedBox(height: 14),

                          // ======================================
                          // APPLY
                          // ======================================
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  AttractionFilters(
                                    maximumPrice: price,
                                    maximumDistanceKm: distance,
                                    crowdLevel: crowd,
                                    openNow: openNow,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Apply Filters'),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ======================================
                          // CLEAR
                          // ======================================
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  const AttractionFilters(),
                                );
                              },
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Clear Filters'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _filters = result;
        _results = _query();
      });
    }
  }

  // ==============================================================
  // SORT BOTTOM SHEET
  // ==============================================================

  Future<void> _showSort() async {
    final selected = await showModalBottomSheet<_AttractionSort>(
      context: context,

      // Important:
      // Allows the sheet to use more vertical space.
      isScrollControlled: true,

      showDragHandle: true,

      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================================================
                // TITLE
                // ================================================
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Sort Attractions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),

                const Divider(height: 1),

                // ================================================
                // SCROLLABLE OPTIONS
                // ================================================
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    children: [
                      _SortTile(
                        title: 'Name A → Z',
                        subtitle: 'Sort attractions alphabetically',
                        icon: Icons.sort_by_alpha,
                        selected: _sort == _AttractionSort.nameAscending,
                        onTap: () {
                          Navigator.pop(context, _AttractionSort.nameAscending);
                        },
                      ),

                      _SortTile(
                        title: 'Price: Low → High',
                        subtitle: 'Show cheaper attractions first',
                        icon: Icons.arrow_upward,
                        selected: _sort == _AttractionSort.priceLowToHigh,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _AttractionSort.priceLowToHigh,
                          );
                        },
                      ),

                      _SortTile(
                        title: 'Price: High → Low',
                        subtitle: 'Show higher-priced attractions first',
                        icon: Icons.arrow_downward,
                        selected: _sort == _AttractionSort.priceHighToLow,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _AttractionSort.priceHighToLow,
                          );
                        },
                      ),

                      _SortTile(
                        title: 'Distance: Nearest First',
                        subtitle: 'Show the closest attractions first',
                        icon: Icons.near_me_outlined,
                        selected: _sort == _AttractionSort.nearestFirst,
                        onTap: () {
                          Navigator.pop(context, _AttractionSort.nearestFirst);
                        },
                      ),

                      _SortTile(
                        title: 'Crowd: Low → High',
                        subtitle: 'Show quieter attractions first',
                        icon: Icons.groups_outlined,
                        selected: _sort == _AttractionSort.crowdLowToHigh,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _AttractionSort.crowdLowToHigh,
                          );
                        },
                      ),

                      _SortTile(
                        title: 'Most Available Slots',
                        subtitle:
                            'Show attractions with more available slots first',
                        icon: Icons.calendar_month_outlined,
                        selected: _sort == _AttractionSort.mostAvailableSlots,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _AttractionSort.mostAvailableSlots,
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _sort = selected;
        _results = _query();
      });
    }
  }

  // ==============================================================
  // COMPARISON
  // ==============================================================

  void _changeComparison(Attraction attraction, bool selected) {
    if (selected && _selectedForComparison.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can compare up to three attractions.'),
        ),
      );

      return;
    }

    setState(() {
      if (selected) {
        _selectedForComparison.add(attraction.id);
      } else {
        _selectedForComparison.remove(attraction.id);
      }
    });
  }

  // ==============================================================
  // MAP ATTRACTION BOTTOM SHEET
  // ==============================================================

  void _showMapAttraction(Attraction attraction) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final selected = _selectedForComparison.contains(attraction.id);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attraction.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${attraction.category} · '
                  '${attraction.locationName}',
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MapInfoChip(
                      icon: Icons.payments_outlined,
                      label: attraction.entrancePriceMyr == 0
                          ? 'Free'
                          : 'RM${attraction.entrancePriceMyr.toStringAsFixed(0)}',
                    ),

                    if (attraction.distanceKm != null)
                      _MapInfoChip(
                        icon: Icons.location_on_outlined,
                        label:
                            '${attraction.distanceKm!.toStringAsFixed(1)} km',
                      ),

                    _MapInfoChip(
                      icon: Icons.groups_outlined,
                      label: '${attraction.estimatedCrowdLevel} crowd',
                    ),

                    _MapInfoChip(
                      icon: Icons.calendar_month_outlined,
                      label: '${attraction.availableSlots.length} slots',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      Navigator.pushNamed(
                        context,
                        AttractionDetailsPage.routeName,
                        arguments: attraction.id,
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Attraction Details'),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      _changeComparison(attraction, !selected);
                    },
                    icon: Icon(
                      selected
                          ? Icons.remove_circle_outline
                          : Icons.compare_arrows,
                    ),
                    label: Text(
                      selected ? 'Remove from Comparison' : 'Add to Comparison',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // MAP
  // ==============================================================

  Widget _buildMap(List<Attraction> attractions) {
    final mappableAttractions = attractions.where((attraction) {
      return attraction.latitude != null && attraction.longitude != null;
    }).toList();

    if (mappableAttractions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.map_outlined, size: 44),
              SizedBox(height: 10),
              Text(
                'No map locations are available for these attractions.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    LatLng initialCenter;

    // If current location is available, use it.
    if (_origin != null) {
      initialCenter = LatLng(_origin!.latitude, _origin!.longitude);
    } else {
      final first = mappableAttractions.first;

      initialCenter = LatLng(first.latitude!, first.longitude!);
    }

    return Column(
      children: [
        SizedBox(
          height: 520,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.cd_project',
                    ),

                    MarkerLayer(
                      markers: [
                        // =========================================
                        // CURRENT LOCATION
                        // =========================================
                        if (_origin != null)
                          Marker(
                            point: LatLng(
                              _origin!.latitude,
                              _origin!.longitude,
                            ),
                            width: 50,
                            height: 50,
                            child: const Tooltip(
                              message: 'Your location',
                              child: Icon(
                                Icons.my_location,
                                size: 30,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                        // =========================================
                        // ATTRACTION MARKERS
                        // =========================================
                        ...mappableAttractions.map((attraction) {
                          return Marker(
                            point: LatLng(
                              attraction.latitude!,
                              attraction.longitude!,
                            ),
                            width: 54,
                            height: 54,
                            child: GestureDetector(
                              onTap: () {
                                _showMapAttraction(attraction);
                              },
                              child: Tooltip(
                                message: attraction.name,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 46,
                                  color: Color(0xFF79571E),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // ===============================================
                // OPENSTREETMAP CREDIT
                // ===============================================
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Tap an attraction marker to view more information.',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ==============================================================
  // BUILD PAGE
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 1,
        onLogout: () async => signOutAndReturnToSignIn(context),
      ),

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: const Text('Discover Attractions'),

        actions: [
          // ------------------------------------------------------
          // PREFERENCES
          // ------------------------------------------------------
          IconButton(
            tooltip: 'Discovery Preferences',
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                DiscoveryPreferencesPage.routeName,
              );

              if (mounted) {
                _reload();
              }
            },
            icon: const Icon(Icons.tune_rounded),
          ),

          // ------------------------------------------------------
          // SMART RECOMMENDATIONS
          // ------------------------------------------------------
          IconButton(
            tooltip: 'Smart Recommendations',
            onPressed: () {
              Navigator.pushNamed(context, SmartRecommendationsPage.routeName);
            },
            icon: const Icon(Icons.auto_awesome_outlined),
          ),

          // ------------------------------------------------------
          // NEARBY
          // ------------------------------------------------------
          IconButton(
            tooltip: 'Nearby Attractions',
            onPressed: () {
              Navigator.pushNamed(context, NearbyAttractionsPage.routeName);
            },
            icon: const Icon(Icons.near_me_outlined),
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ====================================================
            // DEMO MODE
            // ====================================================
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
                    'No login is required. '
                    'Preference changes last until the app restarts.',
                  ),
                ),
              ),

            // ====================================================
            // SEARCH
            // ====================================================
            TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search name, category or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();

                          setState(() {});

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

            // ====================================================
            // FILTER + SORT
            // ====================================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.filter_list),
                    label: Text(
                      _filters.isActive ? 'Filters active' : 'Filters',
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSort,
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ====================================================
            // NEARBY BUTTON
            // ====================================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, NearbyAttractionsPage.routeName);
                },
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Nearby Attractions'),
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // ACTIVE SORT
            // ====================================================
            Row(
              children: [
                const Icon(Icons.sort, size: 15, color: Color(0xFF64748B)),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    'Sorted by: $_sortLabel',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ====================================================
            // LOCATION
            // ====================================================
            if (_origin != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.my_location_outlined,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      _origin!.isFallback
                          ? 'Distance origin: ${_origin!.label}'
                          : 'Using ${_origin!.label}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 14),

            // ====================================================
            // CROWD INFO
            // ====================================================
            const Card(
              color: Color(0xFFF2F3FF),
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Color(0xFF79571E)),
                title: Text('Crowd labels are slot occupancy estimates'),
                subtitle: Text('Live visitor counts will come from Module 4.'),
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // RESULTS
            // ====================================================
            FutureBuilder<List<Attraction>>(
              future: _results,
              builder: (context, snapshot) {
                // ===============================================
                // LOADING
                // ===============================================

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // ===============================================
                // ERROR
                // ===============================================

                if (snapshot.hasError) {
                  return _ErrorCard(
                    message: '${snapshot.error}',
                    onRetry: _reload,
                  );
                }

                final attractions = snapshot.data ?? const <Attraction>[];

                // ===============================================
                // NO RESULTS
                // ===============================================

                if (attractions.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No approved attractions match your current search or filters.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // =============================================
                    // LIST / MAP VIEW
                    // =============================================
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.view_list),
                            label: Text('List View'),
                          ),

                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.map_outlined),
                            label: Text('Map View'),
                          ),
                        ],
                        selected: {_mapView},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _mapView = selection.first;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =============================================
                    // RESULT COUNT
                    // =============================================
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${attractions.length} attraction'
                            '${attractions.length == 1 ? '' : 's'} found',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),

                        Text(
                          _sortLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // =============================================
                    // MAP
                    // =============================================
                    if (_mapView)
                      _buildMap(attractions)
                    // =============================================
                    // LIST
                    // =============================================
                    else
                      Column(
                        children: attractions.map((attraction) {
                          return _AttractionCard(
                            attraction: attraction,
                            selected: _selectedForComparison.contains(
                              attraction.id,
                            ),
                            imageUrl: attraction.coverImageUrl,
                            onCompare: (selected) {
                              _changeComparison(attraction, selected);
                            },
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AttractionDetailsPage.routeName,
                                arguments: attraction.id,
                              );
                            },
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // ==========================================================
      // COMPARE FLOATING BUTTON
      // ==========================================================
      floatingActionButton: _selectedForComparison.length < 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final all = await _results;

                if (!context.mounted) {
                  return;
                }

                final selected = all.where((attraction) {
                  return _selectedForComparison.contains(attraction.id);
                }).toList();

                if (selected.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select at least two visible attractions to compare.',
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pushNamed(
                  context,
                  AttractionComparisonPage.routeName,
                  arguments: selected,
                );
              },
              icon: const Icon(Icons.compare_arrows),
              label: Text('Compare ${_selectedForComparison.length}'),
            ),
    );
  }
}

// ================================================================
// SORT TILE
// ================================================================

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? const Color(0xFF79571E) : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF79571E))
          : null,
    );
  }
}

// ================================================================
// ATTRACTION CARD
// ================================================================

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

  Color get crowdColor {
    switch (attraction.estimatedCrowdLevel) {
      case 'Low':
        return Colors.green;

      case 'Moderate':
        return Colors.amber.shade800;

      case 'High':
        return Colors.orange.shade800;

      case 'Critical':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // IMAGE
              // ==================================================
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
                        errorBuilder: (_, _, _) {
                          return Container(
                            width: 82,
                            height: 100,
                            color: const Color(0xFFFFE2B5),
                            child: const Icon(Icons.place_outlined),
                          );
                        },
                      ),
              ),

              const SizedBox(width: 12),

              // ==================================================
              // INFORMATION
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    Text(
                      '${attraction.category} · '
                      '${attraction.locationName}',
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
                      runSpacing: 4,
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
                  ],
                ),
              ),

              // ==================================================
              // COMPARE CHECKBOX
              // ==================================================
              Checkbox(
                value: selected,
                onChanged: (value) {
                  onCompare(value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MAP INFO CHIP
// ================================================================

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),

          const SizedBox(width: 4),

          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ERROR CARD
// ================================================================

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEDEA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Could not load approved attractions.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 6),

            Text(
              message,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
