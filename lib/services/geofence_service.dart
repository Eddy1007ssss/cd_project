import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeofenceConfig {
  const GeofenceConfig({
    required this.bookingId,
    required this.latitude,
    required this.longitude,
    required this.entryRadiusM,
    required this.exitRadiusM,
    required this.entryDwellSeconds,
    required this.exitDwellSeconds,
    required this.visitStatus,
  });

  final String bookingId;

  final double latitude;
  final double longitude;

  final double entryRadiusM;
  final double exitRadiusM;

  final int entryDwellSeconds;
  final int exitDwellSeconds;

  final String visitStatus;

  bool get isCheckedIn => visitStatus == 'checked_in';

  bool get isCheckedOut => visitStatus == 'checked_out';

  factory GeofenceConfig.fromJson(
      Map<String, dynamic> json,
      ) {
    return GeofenceConfig(
      bookingId: json['booking_id'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      entryRadiusM:
      (json['entry_radius_m'] as num).toDouble(),
      exitRadiusM:
      (json['exit_radius_m'] as num).toDouble(),
      entryDwellSeconds:
      (json['entry_dwell_seconds'] as num).toInt(),
      exitDwellSeconds:
      (json['exit_dwell_seconds'] as num).toInt(),
      visitStatus:
      json['visit_status']?.toString() ?? '',
    );
  }
}

class GeofenceMonitorUpdate {
  const GeofenceMonitorUpdate({
    required this.message,
    required this.distanceM,
    this.secondsRemaining,
  });

  final String message;
  final double distanceM;
  final int? secondsRemaining;
}

class GeofenceService {
  // ============================================================
  // SINGLETON
  // ============================================================

  GeofenceService._internal();

  static final GeofenceService _instance =
  GeofenceService._internal();

  factory GeofenceService() => _instance;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // MONITOR STATE
  // ============================================================

  Timer? _monitorTimer;

  String? _activeBookingId;

  DateTime? _entryStartedAt;
  DateTime? _exitStartedAt;

  bool _processing = false;

  GeofenceMonitorUpdate? _lastUpdate;

  // ============================================================
  // CALLBACKS
  // These can be replaced when Booking Details is reopened.
  // ============================================================

  void Function(GeofenceMonitorUpdate update)?
  _onUpdate;

  Future<void> Function()?
  _onCheckedIn;

  Future<void> Function()?
  _onCheckedOut;

  void Function(Object error)?
  _onError;

  // ============================================================
  // PUBLIC STATE
  // ============================================================

  bool get isMonitoring =>
      _monitorTimer?.isActive == true;

  String? get activeBookingId =>
      _activeBookingId;

  GeofenceMonitorUpdate? get lastUpdate =>
      _lastUpdate;

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<Position> getCurrentPosition() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Please enable location services.',
      );
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {
        throw Exception(
          'Location permission denied.',
        );
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
            'Please enable it in Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings:
      const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ============================================================
  // GET GEOFENCE CONFIGURATION
  // ============================================================

  Future<GeofenceConfig> getGeofenceConfig({
    required String bookingId,
  }) async {
    final response =
    await _supabase.rpc(
      'get_booking_geofence',
      params: {
        'target_booking_id': bookingId,
      },
    );

    final json =
    Map<String, dynamic>.from(
      response as Map,
    );

    return GeofenceConfig.fromJson(
      json,
    );
  }

  // ============================================================
  // CONFIRM CHECK-IN
  // ============================================================

  Future<Map<String, dynamic>>
  confirmCheckIn({
    required String bookingId,
  }) async {
    final position =
    await getCurrentPosition();

    final response =
    await _supabase.rpc(
      'confirm_geofence_check_in',
      params: {
        'target_booking_id':
        bookingId,
        'current_latitude':
        position.latitude,
        'current_longitude':
        position.longitude,
        'accuracy_m':
        position.accuracy,

        // Important:
        // Use current time instead of the browser
        // position timestamp to avoid LOCATION_EXPIRED.
        'position_recorded_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      },
    );

    return Map<String, dynamic>.from(
      response as Map,
    );
  }

  // ============================================================
  // CONFIRM CHECK-OUT
  // ============================================================

  Future<Map<String, dynamic>>
  confirmCheckOut({
    required String bookingId,
  }) async {
    final position =
    await getCurrentPosition();

    final response =
    await _supabase.rpc(
      'confirm_geofence_check_out',
      params: {
        'target_booking_id':
        bookingId,
        'current_latitude':
        position.latitude,
        'current_longitude':
        position.longitude,
        'accuracy_m':
        position.accuracy,

        // Same LOCATION_EXPIRED fix.
        'position_recorded_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      },
    );

    return Map<String, dynamic>.from(
      response as Map,
    );
  }

  // ============================================================
  // START / REATTACH MONITORING
  // ============================================================

  Future<void> startMonitoring({
    required String bookingId,
    required void Function(
        GeofenceMonitorUpdate update,
        )
    onUpdate,
    required Future<void> Function()
    onCheckedIn,
    required Future<void> Function()
    onCheckedOut,
    required void Function(Object error)
    onError,
  }) async {
    // Always replace callbacks.
    // This is important when BookingDetailsPage
    // is closed and later opened again.
    _onUpdate = onUpdate;
    _onCheckedIn = onCheckedIn;
    _onCheckedOut = onCheckedOut;
    _onError = onError;

    // ----------------------------------------------------------
    // SAME BOOKING IS ALREADY RUNNING
    // DO NOT RESET 30 / 45 SECOND DWELL TIMER.
    // ----------------------------------------------------------

    if (_activeBookingId == bookingId &&
        _monitorTimer?.isActive == true) {
      if (_lastUpdate != null) {
        _onUpdate?.call(
          _lastUpdate!,
        );
      }

      return;
    }

    // ----------------------------------------------------------
    // DIFFERENT BOOKING
    // Stop old monitor and start new one.
    // ----------------------------------------------------------

    stopMonitoring(
      clearCallbacks: false,
    );

    _activeBookingId =
        bookingId;

    try {
      await _checkLocation();
    } catch (error) {
      _onError?.call(error);
    }

    // The first check may already have completed the visit.
    if (_activeBookingId != bookingId) {
      return;
    }

    _monitorTimer =
        Timer.periodic(
          const Duration(seconds: 5),
              (_) async {
            await _checkLocation();
          },
        );
  }

  // ============================================================
  // CHECK CURRENT LOCATION
  // ============================================================

  Future<void> _checkLocation() async {
    if (_processing) return;

    final bookingId =
        _activeBookingId;

    if (bookingId == null) return;

    _processing = true;

    try {
      final config =
      await getGeofenceConfig(
        bookingId: bookingId,
      );

      // ========================================================
      // BOOKING ALREADY CHECKED OUT
      // ========================================================

      if (config.isCheckedOut) {
        _entryStartedAt = null;
        _exitStartedAt = null;

        _sendUpdate(
          const GeofenceMonitorUpdate(
            message:
            'Visit completed',
            distanceM: 0,
          ),
        );

        stopMonitoring(
          clearCallbacks: false,
        );

        return;
      }

      final position =
      await getCurrentPosition();

      final distance =
      Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        config.latitude,
        config.longitude,
      );

      final accuracy =
          position.accuracy;

      // ========================================================
      // NOT CHECKED IN
      // ========================================================

      if (!config.isCheckedIn) {
        _exitStartedAt = null;

        // Safe entry rule:
        //
        // distance + GPS accuracy
        // must be inside the entry radius.
        final safelyInside =
            distance + accuracy <=
                config.entryRadiusM;

        if (!safelyInside) {
          // Tourist left the entry area.
          // Reset entry dwell timer.
          _entryStartedAt = null;

          _sendUpdate(
            GeofenceMonitorUpdate(
              message:
              'Outside entry area',
              distanceM:
              distance,
            ),
          );

          return;
        }

        // Tourist has entered the Geofence.
        // Only set this ONCE.
        _entryStartedAt ??=
            DateTime.now();

        final elapsed =
            DateTime.now()
                .difference(
              _entryStartedAt!,
            )
                .inSeconds;

        final remaining =
            config
                .entryDwellSeconds -
                elapsed;

        if (remaining > 0) {
          _sendUpdate(
            GeofenceMonitorUpdate(
              message:
              'Inside Geofence. '
                  'Waiting to check in...',
              distanceM:
              distance,
              secondsRemaining:
              remaining,
            ),
          );

          return;
        }

        // ======================================================
        // 30 SECOND ENTRY DWELL COMPLETED
        // ======================================================

        await confirmCheckIn(
          bookingId:
          bookingId,
        );

        _entryStartedAt = null;

        _sendUpdate(
          GeofenceMonitorUpdate(
            message:
            'Checked in automatically',
            distanceM:
            distance,
          ),
        );

        final callback =
            _onCheckedIn;

        if (callback != null) {
          await callback();
        }

        return;
      }

      // ========================================================
      // ALREADY CHECKED IN
      // NOW MONITOR CHECK-OUT
      // ========================================================

      _entryStartedAt = null;

      // Safe exit rule:
      //
      // distance - accuracy
      // must be OUTSIDE exit radius.
      final safelyOutside =
          distance - accuracy >
              config.exitRadiusM;

      if (!safelyOutside) {
        // Tourist moved back inside.
        // Reset exit dwell timer.
        _exitStartedAt = null;

        _sendUpdate(
          GeofenceMonitorUpdate(
            message:
            'Inside attraction area',
            distanceM:
            distance,
          ),
        );

        return;
      }

      // Tourist is outside.
      // Only start timer once.
      _exitStartedAt ??=
          DateTime.now();

      final elapsed =
          DateTime.now()
              .difference(
            _exitStartedAt!,
          )
              .inSeconds;

      final remaining =
          config.exitDwellSeconds -
              elapsed;

      if (remaining > 0) {
        _sendUpdate(
          GeofenceMonitorUpdate(
            message:
            'Outside Geofence. '
                'Waiting to check out...',
            distanceM:
            distance,
            secondsRemaining:
            remaining,
          ),
        );

        return;
      }

      // ========================================================
      // 45 SECOND EXIT DWELL COMPLETED
      // ========================================================

      await confirmCheckOut(
        bookingId:
        bookingId,
      );

      _exitStartedAt = null;

      _sendUpdate(
        GeofenceMonitorUpdate(
          message:
          'Checked out automatically',
          distanceM:
          distance,
        ),
      );

      final callback =
          _onCheckedOut;

      if (callback != null) {
        await callback();
      }

      stopMonitoring(
        clearCallbacks: false,
      );
    } catch (error) {
      _onError?.call(
        error,
      );
    } finally {
      _processing = false;
    }
  }

  // ============================================================
  // SEND UPDATE
  // ============================================================

  void _sendUpdate(
      GeofenceMonitorUpdate update,
      ) {
    _lastUpdate = update;

    _onUpdate?.call(
      update,
    );
  }

  // ============================================================
  // DETACH PAGE CALLBACKS
  // ============================================================

  /// Use this when BookingDetailsPage is closed.
  ///
  /// Monitoring continues, but the old page will
  /// no longer receive UI callbacks.
  void detachCallbacks() {
    _onUpdate = null;
    _onCheckedIn = null;
    _onCheckedOut = null;
    _onError = null;
  }

  // ============================================================
  // STOP MONITORING
  // ============================================================

  void stopMonitoring({
    bool clearCallbacks = true,
  }) {
    _monitorTimer?.cancel();
    _monitorTimer = null;

    _entryStartedAt = null;
    _exitStartedAt = null;

    _activeBookingId = null;

    if (clearCallbacks) {
      _onUpdate = null;
      _onCheckedIn = null;
      _onCheckedOut = null;
      _onError = null;
    }

    _processing = false;
  }

  // ============================================================
  // FULL DISPOSE
  // ============================================================

  /// Do NOT call this when simply leaving BookingDetailsPage.
  ///
  /// Only use this when you intentionally want to completely
  /// stop the active Geofence session, for example logout.
  void dispose() {
    stopMonitoring();
  }
}