import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/module3_models.dart';
import '../../services/geofence_service.dart';
import '../../widgets/tourflow_widgets.dart';

class GeofencePage extends StatefulWidget {
  const GeofencePage({super.key});

  static const routeName = '/geofence';

  @override
  State<GeofencePage> createState() =>
      _GeofencePageState();
}

class _GeofencePageState extends State<GeofencePage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final GeofenceService _geofenceService =
  GeofenceService();

  final MapController _mapController =
  MapController();

  StreamSubscription<Position>? _positionSubscription;

  TourBooking? _booking;

  AttractionMapData? _attraction;
  Position? _position;

  bool _initialized = false;
  bool _loading = true;
  bool _refreshing = false;

  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    if (arguments is! TourBooking) {
      setState(() {
        _loading = false;
        _error = 'Booking information is missing.';
      });

      return;
    }

    _booking = arguments;

    _load();
  }

  Future<void> _load() async {
    final booking = _booking;

    if (booking == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final slotRow = await _supabase
          .from('attraction_slots')
          .select('attraction_id')
          .eq(
        'id',
        booking.slot.id,
      )
          .single();

      final attractionId =
      slotRow['attraction_id']?.toString();

      if (attractionId == null ||
          attractionId.isEmpty) {
        throw Exception(
          'Unable to identify the attraction.',
        );
      }

      final attractionRow = await _supabase
          .from('attractions')
          .select(
        'id, '
            'name, '
            'address, '
            'location_name, '
            'latitude, '
            'longitude, '
            'check_in_method, '
            'geofence_radius_m, '
            'geofence_exit_radius_m, '
            'geofence_entry_dwell_seconds, '
            'geofence_exit_dwell_seconds',
      )
          .eq(
        'id',
        attractionId,
      )
          .single();

      final attraction =
      AttractionMapData.fromJson(
        Map<String, dynamic>.from(
          attractionRow,
        ),
      );

      final position =
      await _geofenceService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _attraction = attraction;
        _position = position;
        _loading = false;
      });

      await _startLocationUpdates();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _mapErrorMessage(
          error,
        );
      });
    }
  }

  Future<void> _startLocationUpdates() async {
    await _positionSubscription?.cancel();

    const locationSettings =
    LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
              (position) {
            if (!mounted) {
              return;
            }

            setState(() {
              _position = position;
              _error = null;
            });
          },
          onError: (
              Object error,
              ) {
            if (!mounted) {
              return;
            }

            setState(() {
              _error = _mapErrorMessage(
                error,
              );
            });
          },
        );
  }

  Future<void> _refreshLocation() async {
    if (_refreshing) {
      return;
    }

    setState(() {
      _refreshing = true;
    });

    try {
      final position =
      await _geofenceService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _mapErrorMessage(
          error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  double? get _distance {
    final attraction = _attraction;
    final position = _position;

    if (attraction == null ||
        position == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      attraction.latitude,
      attraction.longitude,
    );
  }

  String get _distanceText {
    final distance = _distance;

    if (distance == null) {
      return 'Locating...';
    }

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    }

    return '${(distance / 1000).toStringAsFixed(2)} km';
  }

  String get _geofenceStatus {
    final attraction = _attraction;
    final position = _position;
    final distance = _distance;

    if (attraction == null ||
        position == null ||
        distance == null) {
      return 'Location unavailable';
    }

    if (!attraction.usesGeofence) {
      return 'Staff QR Verification';
    }

    final entryRadius =
        attraction.entryRadiusM;

    final exitRadius =
        attraction.exitRadiusM;

    if (entryRadius == null ||
        exitRadius == null) {
      return 'Geofence configuration unavailable';
    }

    final accuracy =
        position.accuracy;

    final safelyInside =
        distance + accuracy <= entryRadius;

    if (safelyInside) {
      return 'Inside Entry Geofence';
    }

    final safelyOutside =
        distance - accuracy > exitRadius;

    if (safelyOutside) {
      return 'Outside Geofence';
    }

    return 'Geofence Transition Zone';
  }

  Color get _statusColor {
    final attraction = _attraction;

    if (attraction == null) {
      return const Color(
        0xFF6B7280,
      );
    }

    if (!attraction.usesGeofence) {
      return const Color(
        0xFF2563EB,
      );
    }

    switch (_geofenceStatus) {
      case 'Inside Entry Geofence':
        return const Color(
          0xFF15803D,
        );

      case 'Outside Geofence':
        return const Color(
          0xFFB91C1C,
        );

      default:
        return const Color(
          0xFFB45309,
        );
    }
  }

  IconData get _statusIcon {
    final attraction = _attraction;

    if (attraction == null) {
      return Icons.location_searching;
    }

    if (!attraction.usesGeofence) {
      return Icons.qr_code_scanner_rounded;
    }

    switch (_geofenceStatus) {
      case 'Inside Entry Geofence':
        return Icons.check_circle_outline_rounded;

      case 'Outside Geofence':
        return Icons.location_off_outlined;

      default:
        return Icons.location_searching_rounded;
    }
  }

  void _goToAttraction() {
    final attraction = _attraction;

    if (attraction == null) {
      return;
    }

    _mapController.move(
      LatLng(
        attraction.latitude,
        attraction.longitude,
      ),
      17,
    );
  }

  void _goToMyLocation() {
    final position = _position;

    if (position == null) {
      return;
    }

    _mapController.move(
      LatLng(
        position.latitude,
        position.longitude,
      ),
      17,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return TourFlowPage(
      title: 'Attraction Map',
      role: '',
      pageLevel: TourFlowPageLevel.secondary,
      selectedNavigationIndex: 2,
      showMenuButton: false,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(
            30,
          ),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_attraction == null) {
      return ModuleCard(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to Load Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _error ??
                  'Attraction location is unavailable.',
            ),
          ],
        ),
      );
    }

    final booking =
    _booking!;

    final attraction =
    _attraction!;

    final position =
        _position;

    final attractionPoint =
    LatLng(
      attraction.latitude,
      attraction.longitude,
    );

    final touristPoint =
    position == null
        ? null
        : LatLng(
      position.latitude,
      position.longitude,
    );

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        ModuleCard(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color:
                    Color(
                      0xFF79571E,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      attraction.name,
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Booking ${booking.bookingCode}',
                style:
                const TextStyle(
                  color:
                  Color(
                    0xFF6B7280,
                  ),
                ),
              ),

              if (attraction
                  .address.isNotEmpty) ...[
                const SizedBox(
                  height: 8,
                ),

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color:
                      Color(
                        0xFF6B7280,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        attraction.address,
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(
                height: 10,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  attraction.usesGeofence
                      ? const Color(
                    0xFFEAF7ED,
                  )
                      : const Color(
                    0xFFEFF6FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  attraction.usesGeofence
                      ? 'Automatic Geofence Entry'
                      : 'Staff QR Verification',
                  style:
                  TextStyle(
                    color:
                    attraction.usesGeofence
                        ? const Color(
                      0xFF15803D,
                    )
                        : const Color(
                      0xFF2563EB,
                    ),
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          child: SizedBox(
            height: 430,
            child: FlutterMap(
              mapController:
              _mapController,
              options:
              MapOptions(
                initialCenter:
                attractionPoint,
                initialZoom: 16,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.cd_project',
                ),

                if (attraction.usesGeofence &&
                    attraction.exitRadiusM !=
                        null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point:
                        attractionPoint,
                        radius:
                        attraction.exitRadiusM!,
                        useRadiusInMeter:
                        true,
                        color:
                        const Color(
                          0xFFF59E0B,
                        ).withValues(
                          alpha: 0.08,
                        ),
                        borderColor:
                        const Color(
                          0xFFF59E0B,
                        ),
                        borderStrokeWidth:
                        2,
                      ),
                    ],
                  ),

                if (attraction.usesGeofence &&
                    attraction.entryRadiusM !=
                        null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point:
                        attractionPoint,
                        radius:
                        attraction.entryRadiusM!,
                        useRadiusInMeter:
                        true,
                        color:
                        const Color(
                          0xFF16A34A,
                        ).withValues(
                          alpha: 0.15,
                        ),
                        borderColor:
                        const Color(
                          0xFF15803D,
                        ),
                        borderStrokeWidth:
                        2,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                      attractionPoint,
                      width: 58,
                      height: 58,
                      child:
                      const _MapPin(
                        icon:
                        Icons.place_rounded,
                        background:
                        Color(
                          0xFFB91C1C,
                        ),
                        tooltip:
                        'Attraction',
                      ),
                    ),

                    if (touristPoint !=
                        null)
                      Marker(
                        point:
                        touristPoint,
                        width: 58,
                        height: 58,
                        child:
                        const _MapPin(
                          icon: Icons
                              .person_pin_circle,
                          background:
                          Color(
                            0xFF2563EB,
                          ),
                          tooltip:
                          'Your Location',
                        ),
                      ),
                  ],
                ),

                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
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
                _goToAttraction,
                icon:
                const Icon(
                  Icons.place_outlined,
                ),
                label:
                const Text(
                  'Attraction',
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
              OutlinedButton.icon(
                onPressed:
                position == null
                    ? null
                    : _goToMyLocation,
                icon:
                const Icon(
                  Icons.my_location_rounded,
                ),
                label:
                const Text(
                  'My Location',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        ModuleCard(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color:
                    Color(
                      0xFF79571E,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Distance to Attraction',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                _distanceText,
                style:
                const TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        ModuleCard(
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Icon(
                _statusIcon,
                color:
                _statusColor,
                size: 30,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.usesGeofence
                          ? 'Current Geofence Status'
                          : 'Entry Method',
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      _geofenceStatus,
                      style:
                      TextStyle(
                        color:
                        _statusColor,
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    if (!attraction
                        .usesGeofence) ...[
                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Show your QR code to Staff for check-in and check-out.',
                        style:
                        TextStyle(
                          color:
                          Color(
                            0xFF6B7280,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        if (attraction
            .usesGeofence) ...[
          const SizedBox(
            height: 12,
          ),

          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Required Time For Check-In and Check-Out',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Check-In',
                  value: attraction.entryDwellSeconds == null
                      ? '-'
                      : '${attraction.entryDwellSeconds}s',
                ),
                const Divider(),
                _InfoRow(
                  label: 'Check-Out',
                  value: attraction.exitDwellSeconds == null
                      ? '-'
                      : '${attraction.exitDwellSeconds}s',
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              14,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFFFF7EA,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child:
            const Text(
              'Stay inside to check in. '
                  'Stay outside to check out.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],

        if (attraction
            .usesStaffScan) ...[
          const SizedBox(
            height: 12,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              14,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEFF6FF,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child:
            const Text(
              'Use the map to find the attraction. '
                  'Staff will scan your QR code for check-in and check-out.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(
            height: 12,
          ),

          Text(
            _error!,
            style:
            const TextStyle(
              color:
              Color(
                0xFFB45309,
              ),
            ),
          ),
        ],

        const SizedBox(
          height: 14,
        ),

        OutlinedButton.icon(
          onPressed:
          _refreshing
              ? null
              : _refreshLocation,
          icon:
          _refreshing
              ? const SizedBox.square(
            dimension:
            17,
            child:
            CircularProgressIndicator(
              strokeWidth:
              2,
            ),
          )
              : const Icon(
            Icons.refresh_rounded,
          ),
          label:
          Text(
            _refreshing
                ? 'Refreshing...'
                : 'Refresh Location',
          ),
        ),
      ],
    );
  }
}

class AttractionMapData {
  const AttractionMapData({
    required this.id,
    required this.name,
    required this.address,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.checkInMethod,
    required this.entryRadiusM,
    required this.exitRadiusM,
    required this.entryDwellSeconds,
    required this.exitDwellSeconds,
  });

  final String id;
  final String name;
  final String address;
  final String locationName;

  final double latitude;
  final double longitude;

  final String checkInMethod;

  final double? entryRadiusM;
  final double? exitRadiusM;

  final int? entryDwellSeconds;
  final int? exitDwellSeconds;

  bool get usesGeofence =>
      checkInMethod == 'geofence';

  bool get usesStaffScan =>
      checkInMethod == 'staff_scan';

  factory AttractionMapData.fromJson(
      Map<String, dynamic> json,
      ) {
    final latitude =
    json['latitude'];

    final longitude =
    json['longitude'];

    if (latitude == null ||
        longitude == null) {
      throw Exception(
        'Attraction location is unavailable.',
      );
    }

    return AttractionMapData(
      id:
      json['id']?.toString() ??
          '',

      name:
      json['name']?.toString() ??
          'Attraction',

      address:
      json['address']?.toString() ??
          '',

      locationName:
      json['location_name']
          ?.toString() ??
          '',

      latitude:
      (latitude as num)
          .toDouble(),

      longitude:
      (longitude as num)
          .toDouble(),

      checkInMethod:
      json['check_in_method']
          ?.toString() ??
          '',

      entryRadiusM:
      json['geofence_radius_m'] ==
          null
          ? null
          : (json['geofence_radius_m']
      as num)
          .toDouble(),

      exitRadiusM:
      json['geofence_exit_radius_m'] ==
          null
          ? null
          : (json['geofence_exit_radius_m']
      as num)
          .toDouble(),

      entryDwellSeconds:
      json['geofence_entry_dwell_seconds'] ==
          null
          ? null
          : (json[
      'geofence_entry_dwell_seconds']
      as num)
          .toInt(),

      exitDwellSeconds:
      json['geofence_exit_dwell_seconds'] ==
          null
          ? null
          : (json[
      'geofence_exit_dwell_seconds']
      as num)
          .toInt(),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.background,
    required this.tooltip,
  });

  final IconData icon;
  final Color background;
  final String tooltip;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Tooltip(
      message:
      tooltip,
      child: Container(
        decoration:
        BoxDecoration(
          color:
          background,
          shape:
          BoxShape.circle,
          border:
          Border.all(
            color:
            Colors.white,
            width:
            3,
          ),
          boxShadow:
          const [
            BoxShadow(
              blurRadius:
              7,
              color:
              Colors.black26,
            ),
          ],
        ),
        child:
        Icon(
          icon,
          color:
          Colors.white,
          size:
          31,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child:
            Text(
              label,
              style:
              const TextStyle(
                color:
                Color(
                  0xFF6B7280,
                ),
              ),
            ),
          ),
          Text(
            value,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _mapErrorMessage(
    Object error,
    ) {
  final value =
  error.toString();

  if (value.contains(
    'Location permission',
  )) {
    return 'Location permission is required to view your distance from the attraction.';
  }

  if (value.contains(
    'Please enable location services',
  )) {
    return 'Please enable location services on your device.';
  }

  return value.replaceFirst(
    'Exception: ',
    '',
  );
}