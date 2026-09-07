import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import 'attraction_details_page.dart';

class NearbyAttractionsPage extends StatefulWidget {
  const NearbyAttractionsPage({super.key});

  static const routeName = '/nearby-attractions';

  @override
  State<NearbyAttractionsPage> createState() =>
      _NearbyAttractionsPageState();
}

class _NearbyAttractionsPageState
    extends State<NearbyAttractionsPage> {
  final _service = AttractionService();
  final _locationService = LocationService();

  late Future<
      (
      LocationPoint,
      List<Attraction>,
      BookingLocationAnchor?,
      )> _nearby;

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

    _nearby = _load(
      loadSavedRadius: true,
    );
  }

  // ==============================================================
  // LOAD NEARBY ATTRACTIONS
  // ==============================================================

  Future<
      (
      LocationPoint,
      List<Attraction>,
      BookingLocationAnchor?,
      )> _load({
    bool loadSavedRadius = false,
  }) async {
    // ============================================================
    // CHECK UPCOMING BOOKING
    // ============================================================

    final anchor =
    await _service.getUpcomingBookingAnchor();

    // ============================================================
    // SELECT STARTING LOCATION
    // ============================================================

    late LocationPoint location;

    if (anchor != null) {
      // If there is an upcoming booking, use the booked
      // attraction as the starting point.
      location = anchor.location;
    } else if (_manualLocation != null) {
      // User manually entered a location.
      location = _manualLocation!;
    } else {
      // Otherwise try to obtain phone GPS location.
      location =
      await _locationService.currentLocation();
    }

    // ============================================================
    // LOAD SAVED TRAVEL RADIUS
    // ============================================================

    if (loadSavedRadius || !_radiusLoaded) {
      final preferences =
      await _service.getPreferences(
        defaultOrigin: location,
      );

      _savedRadiusKm =
          preferences.travelRadiusKm;

      _radiusKm =
          preferences.travelRadiusKm;

      _radiusLoaded = true;
    }

    // ============================================================
    // GET NEARBY ATTRACTIONS
    // ============================================================

    var attractions =
    await _service.getNearby(
      location,
    );

    // ============================================================
    // FILTER BY SEARCH RADIUS
    // ============================================================

    attractions = attractions.where(
          (attraction) {
        final distance =
            attraction.distanceKm;

        if (distance == null) {
          return false;
        }

        return distance <= _radiusKm;
      },
    ).toList();

    // ============================================================
    // FILTER AFTER UPCOMING BOOKING
    // ============================================================

    if (anchor != null) {
      attractions = attractions.where(
            (attraction) {
          return _service.fitsAfterBooking(
            attraction,
            anchor,
          );
        },
      ).toList();
    }

    return (
    location,
    attractions,
    anchor,
    );
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
      // Stop using manual location.
      _manualLocation = null;

      // LocationService will request/check GPS again.
      _nearby = _load();
    });
  }

  // ==============================================================
  // RESET TO SAVED RADIUS
  // ==============================================================

  void _resetToSavedRadius() {
    setState(() {
      _radiusKm = _savedRadiusKm;

      _nearby = _load();
    });
  }

  // ==============================================================
  // MANUAL LOCATION BOTTOM SHEET
  // ==============================================================

  Future<void> _showManualLocation() async {
    final labelController =
    TextEditingController();

    final latitudeController =
    TextEditingController();

    final longitudeController =
    TextEditingController();

    String? validationMessage;

    final result =
    await showModalBottomSheet<LocationPoint>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  20 +
                      MediaQuery.of(context)
                          .viewInsets
                          .bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // TITLE
                      // ==========================================

                      const Text(
                        'Enter Location Manually',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Enter a location name and its coordinates. '
                            'Nearby attractions will be calculated from '
                            'this location instead of your phone GPS.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(
                            0xFF64748B,
                          ),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==========================================
                      // LOCATION NAME
                      // ==========================================

                      TextField(
                        controller:
                        labelController,
                        textCapitalization:
                        TextCapitalization.words,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Location name',
                          hintText:
                          'Example: Kuala Lumpur City Centre',
                          prefixIcon: Icon(
                            Icons
                                .location_city_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==========================================
                      // LATITUDE
                      // ==========================================

                      TextField(
                        controller:
                        latitudeController,
                        keyboardType:
                        const TextInputType
                            .numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText: 'Latitude',
                          hintText:
                          'Example: 3.1390',
                          prefixIcon: Icon(
                            Icons
                                .north_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==========================================
                      // LONGITUDE
                      // ==========================================

                      TextField(
                        controller:
                        longitudeController,
                        keyboardType:
                        const TextInputType
                            .numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Longitude',
                          hintText:
                          'Example: 101.6869',
                          prefixIcon: Icon(
                            Icons
                                .east_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      // ==========================================
                      // ERROR
                      // ==========================================

                      if (validationMessage !=
                          null) ...[
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                          BoxDecoration(
                            color: const Color(
                              0xFFFFEDEA,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                          ),
                          child: Text(
                            validationMessage!,
                            style:
                            const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ==========================================
                      // CONFIRM
                      // ==========================================

                      SizedBox(
                        width: double.infinity,
                        child:
                        FilledButton.icon(
                          onPressed: () {
                            final latitude =
                            double.tryParse(
                              latitudeController
                                  .text
                                  .trim(),
                            );

                            final longitude =
                            double.tryParse(
                              longitudeController
                                  .text
                                  .trim(),
                            );

                            // Latitude validation.
                            if (latitude == null ||
                                latitude < -90 ||
                                latitude > 90) {
                              setSheetState(() {
                                validationMessage =
                                'Please enter a valid latitude between -90 and 90.';
                              });

                              return;
                            }

                            // Longitude validation.
                            if (longitude ==
                                null ||
                                longitude <
                                    -180 ||
                                longitude >
                                    180) {
                              setSheetState(() {
                                validationMessage =
                                'Please enter a valid longitude between -180 and 180.';
                              });

                              return;
                            }

                            final enteredLabel =
                            labelController
                                .text
                                .trim();

                            Navigator.pop(
                              sheetContext,
                              LocationPoint(
                                latitude:
                                latitude,
                                longitude:
                                longitude,
                                label:
                                enteredLabel
                                    .isEmpty
                                    ? 'Manual location'
                                    : enteredLabel,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons
                                .location_on_outlined,
                          ),
                          label: const Text(
                            'Use This Location',
                          ),
                          style:
                          FilledButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xFF79571E,
                            ),
                            padding:
                            const EdgeInsets
                                .all(
                              15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==========================================
                      // EXAMPLE
                      // ==========================================

                      SizedBox(
                        width: double.infinity,
                        child:
                        OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              labelController
                                  .text =
                              'Kuala Lumpur City Centre';

                              latitudeController
                                  .text =
                              '3.1390';

                              longitudeController
                                  .text =
                              '101.6869';

                              validationMessage =
                              null;
                            });
                          },
                          icon: const Icon(
                            Icons
                                .edit_location_alt_outlined,
                          ),
                          label: const Text(
                            'Fill Kuala Lumpur Example',
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'The Kuala Lumpur button only fills an example. '
                            'You can replace it with any coordinates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(
                            0xFF64748B,
                          ),
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nearby Attractions',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh GPS',
            onPressed: _retryGps,
            icon: const Icon(
              Icons.my_location,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _reload();

          await _nearby;
        },
        child: FutureBuilder<
            (
            LocationPoint,
            List<Attraction>,
            BookingLocationAnchor?,
            )>(
          future: _nearby,
          builder: (
              context,
              snapshot,
              ) {
            // ====================================================
            // LOADING
            // ====================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            // ====================================================
            // ERROR
            // ====================================================

            if (snapshot.hasError) {
              return ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding:
                const EdgeInsets.all(
                  20,
                ),
                children: [
                  const SizedBox(
                    height: 120,
                  ),

                  const Icon(
                    Icons.location_off_outlined,
                    size: 50,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    'Could not load nearby attractions.\n\n'
                        '${snapshot.error}',
                    textAlign:
                    TextAlign.center,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Try Again',
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;

            final location = data.$1;
            final attractions = data.$2;
            final anchor = data.$3;

            final usingManualLocation =
                anchor == null &&
                    _manualLocation != null;

            final usingFallbackLocation =
                anchor == null &&
                    _manualLocation == null &&
                    location.isFallback;

            return ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.all(
                16,
              ),
              children: [
                // ==================================================
                // MAP PREVIEW
                // ==================================================

                Container(
                  height: 170,
                  decoration:
                  BoxDecoration(
                    color: const Color(
                      0xFFE7F0E4,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.map_rounded,
                          size: 100,
                          color: Color(
                            0xFF8BA17E,
                          ),
                        ),
                      ),

                      const Positioned(
                        top: 38,
                        left: 75,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),

                      const Positioned(
                        bottom: 32,
                        right: 80,
                        child: Icon(
                          Icons.location_pin,
                          color: Color(
                            0xFF79571E,
                          ),
                          size: 36,
                        ),
                      ),

                      // ============================================
                      // LOCATION SOURCE LABEL
                      // ============================================

                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration:
                          BoxDecoration(
                            color: Colors.white
                                .withValues(
                              alpha: .90,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons
                                    .my_location_outlined,
                                size: 15,
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Expanded(
                                child: Text(
                                  location.label,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // LOCATION INFORMATION
                // ==================================================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      usingManualLocation
                          ? Icons
                          .edit_location_alt_outlined
                          : Icons
                          .my_location_outlined,
                      size: 20,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            anchor != null
                                ? 'Starting Location'
                                : usingManualLocation
                                ? 'Manual Location'
                                : usingFallbackLocation
                                ? 'Demo Location'
                                : 'Your Current Location',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            anchor != null
                                ? 'After ${anchor.attractionName}'
                                : location.label,
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            '${location.latitude.toStringAsFixed(5)}, '
                                '${location.longitude.toStringAsFixed(5)}',
                            style:
                            const TextStyle(
                              fontSize: 11,
                              color: Color(
                                0xFF64748B,
                              ),
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
                    color: const Color(
                      0xFFFFE7C2,
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons
                                    .location_off_outlined,
                                color:
                                Colors.orange,
                              ),

                              SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  'Current location unavailable',
                                  style:
                                  TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'The app could not access your phone location. '
                                'A temporary Kuala Lumpur demo location is being '
                                'used for the results below.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          SizedBox(
                            width:
                            double.infinity,
                            child:
                            FilledButton.icon(
                              onPressed:
                              _showManualLocation,
                              icon: const Icon(
                                Icons
                                    .edit_location_alt_outlined,
                              ),
                              label: const Text(
                                'Enter Location Manually',
                              ),
                              style:
                              FilledButton
                                  .styleFrom(
                                backgroundColor:
                                const Color(
                                  0xFF79571E,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          SizedBox(
                            width:
                            double.infinity,
                            child:
                            OutlinedButton.icon(
                              onPressed:
                              _retryGps,
                              icon: const Icon(
                                Icons
                                    .my_location,
                              ),
                              label: const Text(
                                'Try GPS Again',
                              ),
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
                    color: const Color(
                      0xFFE8F5E9,
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .check_circle_outline,
                                color: Colors.green,
                              ),

                              SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  'Using your manual location',
                                  style:
                                  TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Nearby attractions are being calculated '
                                'from ${location.label}.',
                            style:
                            const TextStyle(
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                OutlinedButton.icon(
                                  onPressed:
                                  _showManualLocation,
                                  icon:
                                  const Icon(
                                    Icons.edit,
                                  ),
                                  label:
                                  const Text(
                                    'Change',
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Expanded(
                                child:
                                OutlinedButton.icon(
                                  onPressed:
                                  _retryGps,
                                  icon:
                                  const Icon(
                                    Icons
                                        .my_location,
                                  ),
                                  label:
                                  const Text(
                                    'Use GPS',
                                  ),
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
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),

                    Text(
                      '${_radiusKm.toStringAsFixed(0)} km',
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color: Color(
                          0xFF79571E,
                        ),
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
                    color:
                    Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // RADIUS SLIDER
                // ==================================================

                Slider(
                  value: _radiusKm
                      .clamp(
                    1,
                    500,
                  )
                      .toDouble(),
                  min: 1,
                  max: 500,
                  divisions: 499,
                  label:
                  '${_radiusKm.toStringAsFixed(0)} km',
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
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    const Text(
                      '1 km',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),

                    TextButton.icon(
                      onPressed: _radiusKm ==
                          _savedRadiusKm
                          ? null
                          : _resetToSavedRadius,
                      icon: const Icon(
                        Icons.restore,
                        size: 17,
                      ),
                      label: const Text(
                        'Use Saved Radius',
                      ),
                    ),

                    const Text(
                      '500 km',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ==================================================
                // RESULT COUNT
                // ==================================================

                Container(
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                  BoxDecoration(
                    color: const Color(
                      0xFFF5F5F5,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          '${attractions.length} '
                              'attraction'
                              '${attractions.length == 1 ? '' : 's'} '
                              'found within '
                              '${_radiusKm.toStringAsFixed(0)} km',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // UPCOMING BOOKING MESSAGE
                // ==================================================

                if (anchor != null) ...[
                  const SizedBox(height: 10),

                  Text(
                    'Your upcoming visit to '
                        '${anchor.attractionName} ends at '
                        '${_clock(anchor.endsAt)}. '
                        'Only attractions with a suitable same-day '
                        'slot are shown.',
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
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
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .search_off_outlined,
                            size: 42,
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            'No attractions found within '
                                '${_radiusKm.toStringAsFixed(0)} km.',
                            textAlign:
                            TextAlign.center,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          const Text(
                            'Try increasing the search radius '
                                'or changing your location.',
                            textAlign:
                            TextAlign.center,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          OutlinedButton.icon(
                            onPressed:
                            _showManualLocation,
                            icon: const Icon(
                              Icons
                                  .edit_location_alt_outlined,
                            ),
                            label: const Text(
                              'Change Location',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // ATTRACTION LIST
                // ==================================================

                ...attractions.map(
                      (attraction) {
                    final distance =
                    attraction.distanceKm!;

                    return Card(
                      color: Colors.white,
                      margin:
                      const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AttractionDetailsPage
                                .routeName,
                            arguments:
                            attraction.id,
                          );
                        },
                        leading:
                        const CircleAvatar(
                          backgroundColor:
                          Color(
                            0xFFE7F0E4,
                          ),
                          child: Icon(
                            Icons
                                .place_outlined,
                          ),
                        ),
                        title: Text(
                          attraction.name,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w800,
                          ),
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
                        trailing:
                        const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==============================================================
  // FORMAT BOOKING TIME
  // ==============================================================

  String _clock(
      DateTime value,
      ) {
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