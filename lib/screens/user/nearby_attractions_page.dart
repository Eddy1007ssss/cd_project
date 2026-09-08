import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import 'attraction_details_page.dart';

class NearbyAttractionsPage extends StatefulWidget {
  const NearbyAttractionsPage({super.key});

  static const routeName = '/nearby-attractions';

  @override
  State<NearbyAttractionsPage> createState() => _NearbyAttractionsPageState();
}

class _NearbyAttractionsPageState extends State<NearbyAttractionsPage> {
  final _service = AttractionService();
  final _locationService = LocationService();

  static const double _minimumRadiusKm = 1;
  static const double _maximumRadiusKm = 50;

  late Future<(LocationPoint, List<Attraction>, BookingLocationAnchor?)>
  _nearby;

  // ==============================================================
  // RADIUS
  // ==============================================================

  double _radiusKm = 10;
  double _savedRadiusKm = 10;

  bool _radiusLoaded = false;

  // ==============================================================
  // MANUAL LOCATION
  // ==============================================================

  LocationPoint? _manualLocation;

  @override
  void initState() {
    super.initState();

    _nearby = _load(loadSavedRadius: true);
  }

  // ==============================================================
  // LOAD NEARBY ATTRACTIONS
  // ==============================================================

  Future<(LocationPoint, List<Attraction>, BookingLocationAnchor?)> _load({
    bool loadSavedRadius = false,
  }) async {
    // ============================================================
    // UPCOMING BOOKING
    // ============================================================

    final anchor = await _service.getUpcomingBookingAnchor();

    // ============================================================
    // STARTING LOCATION
    // ============================================================

    late LocationPoint location;

    if (anchor != null) {
      location = anchor.location;
    } else if (_manualLocation != null) {
      location = _manualLocation!;
    } else {
      location = await _locationService.currentLocation();
    }

    // ============================================================
    // SAVED RADIUS
    // ============================================================

    if (loadSavedRadius || !_radiusLoaded) {
      final preferences = await _service.getPreferences(
        defaultOrigin: location,
      );

      _savedRadiusKm = preferences.travelRadiusKm
          .clamp(_minimumRadiusKm, _maximumRadiusKm)
          .toDouble();

      _radiusKm = _savedRadiusKm;

      _radiusLoaded = true;
    }

    // ============================================================
    // LOAD NEARBY
    // ============================================================

    var attractions = await _service.getNearby(location);

    // ============================================================
    // FILTER BY RADIUS
    // ============================================================

    attractions = attractions.where((attraction) {
      final distance = attraction.distanceKm;

      if (distance == null) {
        return false;
      }

      return distance <= _radiusKm;
    }).toList();

    // ============================================================
    // UPCOMING BOOKING FILTER
    // ============================================================

    if (anchor != null) {
      attractions = attractions.where((attraction) {
        return _service.fitsAfterBooking(attraction, anchor);
      }).toList();
    }

    return (location, attractions, anchor);
  }

  // ==============================================================
  // RELOAD
  // ==============================================================

  void _reload() {
    setState(() {
      _nearby = _load();
    });
  }

  // ==============================================================
  // RETRY GPS
  // ==============================================================

  void _retryGps() {
    setState(() {
      _manualLocation = null;

      _nearby = _load();
    });
  }

  // ==============================================================
  // RESET RADIUS
  // ==============================================================

  void _resetToSavedRadius() {
    setState(() {
      _radiusKm = _savedRadiusKm;

      _nearby = _load();
    });
  }

  // ==============================================================
  // OPEN ATTRACTION FROM MAP
  // ==============================================================

  void _showMapAttraction(Attraction attraction) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
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

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MapInfoChip(
                      icon: Icons.payments_outlined,
                      label: attraction.entrancePriceMyr == 0
                          ? 'Free'
                          : 'RM ${attraction.entrancePriceMyr.toStringAsFixed(0)}',
                    ),

                    if (attraction.distanceKm != null)
                      _MapInfoChip(
                        icon: Icons.location_on_outlined,
                        label:
                            '${attraction.distanceKm!.toStringAsFixed(1)} km away',
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF79571E),
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
  // REAL MAP
  // ==============================================================

  Widget _buildMap(LocationPoint location, List<Attraction> attractions) {
    final mappableAttractions = attractions.where((attraction) {
      return attraction.latitude != null && attraction.longitude != null;
    }).toList();

    final center = LatLng(location.latitude, location.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // ==================================================
              // OPENSTREETMAP
              // ==================================================
              FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 12),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cd_project',
                  ),

                  MarkerLayer(
                    markers: [
                      // ===========================================
                      // CURRENT / MANUAL LOCATION
                      // ===========================================
                      Marker(
                        point: center,
                        width: 58,
                        height: 58,
                        child: Tooltip(
                          message: location.label,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .25),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),

                      // ===========================================
                      // ATTRACTION MARKERS
                      // ===========================================
                      ...mappableAttractions.map((attraction) {
                        return Marker(
                          point: LatLng(
                            attraction.latitude!,
                            attraction.longitude!,
                          ),
                          width: 55,
                          height: 55,
                          child: GestureDetector(
                            onTap: () {
                              _showMapAttraction(attraction);
                            },
                            child: Tooltip(
                              message: attraction.name,
                              child: const Icon(
                                Icons.location_pin,
                                size: 48,
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

              // ==================================================
              // LOCATION LABEL
              // ==================================================
              Positioned(
                left: 10,
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location_outlined,
                        size: 16,
                        color: Colors.blue,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Text(
                        '${attractions.length} nearby',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // OPENSTREETMAP ATTRIBUTION
              // ==================================================
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(Icons.my_location, size: 14, color: Colors.blue),

            const SizedBox(width: 4),

            const Text('Your location', style: TextStyle(fontSize: 10)),

            const SizedBox(width: 14),

            const Icon(Icons.location_pin, size: 17, color: Color(0xFF79571E)),

            const SizedBox(width: 2),

            const Text('Attraction', style: TextStyle(fontSize: 10)),

            const Spacer(),

            Text(
              'Tap a pin for details',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // MANUAL LOCATION
  // ==============================================================

  Future<void> _showManualLocation() async {
    final labelController = TextEditingController();

    final latitudeController = TextEditingController();

    final longitudeController = TextEditingController();

    String? validationMessage;

    final result = await showModalBottomSheet<LocationPoint>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Location Manually',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Enter a location name and its coordinates. '
                        'Nearby attractions will be calculated from '
                        'this location instead of your phone GPS.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: labelController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Location name',
                          hintText: 'Example: George Town',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'Example: 5.4141',
                          prefixIcon: Icon(Icons.north_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'Example: 100.3288',
                          prefixIcon: Icon(Icons.east_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      if (validationMessage != null) ...[
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDEA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            validationMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final latitude = double.tryParse(
                              latitudeController.text.trim(),
                            );

                            final longitude = double.tryParse(
                              longitudeController.text.trim(),
                            );

                            if (latitude == null ||
                                latitude < -90 ||
                                latitude > 90) {
                              setSheetState(() {
                                validationMessage =
                                    'Please enter a valid latitude between -90 and 90.';
                              });

                              return;
                            }

                            if (longitude == null ||
                                longitude < -180 ||
                                longitude > 180) {
                              setSheetState(() {
                                validationMessage =
                                    'Please enter a valid longitude between -180 and 180.';
                              });

                              return;
                            }

                            final enteredLabel = labelController.text.trim();

                            Navigator.pop(
                              sheetContext,
                              LocationPoint(
                                latitude: latitude,
                                longitude: longitude,
                                label: enteredLabel.isEmpty
                                    ? 'Manual location'
                                    : enteredLabel,
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Use This Location'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF79571E),
                            padding: const EdgeInsets.all(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              labelController.text = 'George Town, Penang';

                              latitudeController.text = '5.4141';

                              longitudeController.text = '100.3288';

                              validationMessage = null;
                            });
                          },
                          icon: const Icon(Icons.edit_location_alt_outlined),
                          label: const Text('Fill Penang Example'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    labelController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _manualLocation = result;

      _nearby = _load();
    });
  }

  // ==============================================================
  // PAGE
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Attractions'),
        actions: [
          IconButton(
            tooltip: 'Refresh GPS',
            onPressed: _retryGps,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _reload();

          await _nearby;
        },

        child:
            FutureBuilder<
              (LocationPoint, List<Attraction>, BookingLocationAnchor?)
            >(
              future: _nearby,

              builder: (context, snapshot) {
                // ====================================================
                // LOADING
                // ====================================================

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ====================================================
                // ERROR
                // ====================================================

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 120),

                      const Icon(Icons.location_off_outlined, size: 50),

                      const SizedBox(height: 12),

                      Text(
                        'Could not load nearby attractions.\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  );
                }

                final data = snapshot.data!;

                final location = data.$1;

                final attractions = data.$2;

                final anchor = data.$3;

                final usingManualLocation =
                    anchor == null && _manualLocation != null;

                final usingFallbackLocation =
                    anchor == null &&
                    _manualLocation == null &&
                    location.isFallback;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ==================================================
                    // REAL INTERACTIVE MAP
                    // ==================================================
                    _buildMap(location, attractions),

                    const SizedBox(height: 16),

                    // ==================================================
                    // LOCATION INFO
                    // ==================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          usingManualLocation
                              ? Icons.edit_location_alt_outlined
                              : Icons.my_location_outlined,
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anchor != null
                                    ? 'Starting Location'
                                    : usingManualLocation
                                    ? 'Manual Location'
                                    : usingFallbackLocation
                                    ? 'Demo Location'
                                    : 'Your Current Location',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                anchor != null
                                    ? 'After ${anchor.attractionName}'
                                    : location.label,
                              ),

                              const SizedBox(height: 3),

                              Text(
                                '${location.latitude.toStringAsFixed(5)}, '
                                '${location.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // GPS UNAVAILABLE
                    // ==================================================
                    if (usingFallbackLocation) ...[
                      const SizedBox(height: 12),

                      Card(
                        color: const Color(0xFFFFE7C2),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.location_off_outlined,
                                    color: Colors.orange,
                                  ),

                                  SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      'Current location unavailable',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'The app could not access your phone location. '
                                'You can enter another location manually.',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _showManualLocation,
                                  icon: const Icon(
                                    Icons.edit_location_alt_outlined,
                                  ),
                                  label: const Text('Enter Location Manually'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF79571E),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _retryGps,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('Try GPS Again'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ==================================================
                    // MANUAL LOCATION ACTIVE
                    // ==================================================
                    if (usingManualLocation) ...[
                      const SizedBox(height: 12),

                      Card(
                        color: const Color(0xFFE8F5E9),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),

                                  SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      'Using your manual location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Nearby attractions are being calculated '
                                'from ${location.label}.',
                                style: const TextStyle(fontSize: 12),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showManualLocation,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Change'),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _retryGps,
                                      icon: const Icon(Icons.my_location),
                                      label: const Text('Use GPS'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ==================================================
                    // SEARCH RADIUS
                    // ==================================================
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Search Radius',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Text(
                          '${_radiusKm.toStringAsFixed(0)} km',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF79571E),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Saved preference: '
                      '${_savedRadiusKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // RADIUS SLIDER
                    // ==================================================
                    Slider(
                      value: _radiusKm
                          .clamp(_minimumRadiusKm, _maximumRadiusKm)
                          .toDouble(),

                      min: _minimumRadiusKm,

                      max: _maximumRadiusKm,

                      divisions: 49,

                      label: '${_radiusKm.toStringAsFixed(0)} km',

                      onChanged: (value) {
                        setState(() {
                          _radiusKm = value;
                        });
                      },

                      onChangeEnd: (value) {
                        setState(() {
                          _radiusKm = value;

                          _nearby = _load();
                        });
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1 km', style: TextStyle(fontSize: 11)),

                        TextButton.icon(
                          onPressed: _radiusKm == _savedRadiusKm
                              ? null
                              : _resetToSavedRadius,
                          icon: const Icon(Icons.restore, size: 17),
                          label: const Text('Use Saved Radius'),
                        ),

                        const Text('50 km', style: TextStyle(fontSize: 11)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // RESULT COUNT
                    // ==================================================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_outlined, size: 20),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              '${attractions.length} attraction'
                              '${attractions.length == 1 ? '' : 's'} '
                              'found within '
                              '${_radiusKm.toStringAsFixed(0)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // BOOKING MESSAGE
                    // ==================================================
                    if (anchor != null) ...[
                      const SizedBox(height: 10),

                      Text(
                        'Your upcoming visit to '
                        '${anchor.attractionName} ends at '
                        '${_clock(anchor.endsAt)}. '
                        'Only attractions with a suitable same-day '
                        'slot are shown.',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ==================================================
                    // NO RESULTS
                    // ==================================================
                    if (attractions.isEmpty)
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.search_off_outlined, size: 42),

                              const SizedBox(height: 10),

                              Text(
                                'No attractions found within '
                                '${_radiusKm.toStringAsFixed(0)} km.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                'Try increasing the search radius '
                                'or changing your location.',
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 12),

                              OutlinedButton.icon(
                                onPressed: _showManualLocation,
                                icon: const Icon(
                                  Icons.edit_location_alt_outlined,
                                ),
                                label: const Text('Change Location'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ==================================================
                    // ATTRACTION LIST
                    // ==================================================
                    ...attractions.map((attraction) {
                      final distance = attraction.distanceKm!;

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AttractionDetailsPage.routeName,
                              arguments: attraction.id,
                            );
                          },

                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE7F0E4),
                            child: Icon(Icons.place_outlined),
                          ),

                          title: Text(
                            attraction.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),

                          subtitle: Text(
                            '${distance.toStringAsFixed(1)} km away\n'
                            'About '
                            '${LocationService.estimatedTravelMinutes(distance)} '
                            'minutes including buffer\n'
                            '${attraction.estimatedCrowdLevel} crowd · '
                            '${attraction.availableSlots.length} future slots',
                          ),

                          isThreeLine: true,

                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    }),

                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
      ),
    );
  }

  // ==============================================================
  // FORMAT TIME
  // ==============================================================

  String _clock(DateTime value) {
    final local = value.toLocal();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    return '${local.day}/${local.month} '
        '$hour:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.hour >= 12 ? 'PM' : 'AM'}';
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
