import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/module3_models.dart';
import 'booking_qr_page.dart';
import 'geofence_page.dart';

class CapacityAlertPage extends StatefulWidget {
  const CapacityAlertPage({super.key});

  static const String routeName = '/capacity-alert';

  @override
  State<CapacityAlertPage> createState() => _CapacityAlertPageState();
}

class _CapacityAlertPageState extends State<CapacityAlertPage>
    with WidgetsBindingObserver {
  Timer? _timer;
  TourBooking? _booking;
  _CapacityData? _data;

  bool _initialized = false;
  bool _loading = false;
  bool _foreground = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is! TourBooking) return;

    _booking = arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _refresh();
      _startTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;

    if (_foreground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }

      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    if (!_foreground || _booking == null) return;

    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted || !_foreground) return;
        if (ModalRoute.of(context)?.isCurrent != true) return;

        _refresh();
      },
    );
  }

  Future<void> _refresh() async {
    final booking = _booking;

    if (!mounted || !_foreground || _loading || booking == null) {
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await Supabase.instance.client.rpc(
        'get_booking_capacity',
        params: {
          'target_booking_id': booking.id,
        },
      );

      if (result is! Map) {
        throw const FormatException('Invalid capacity response.');
      }

      final data = _CapacityData.fromMap(
        result.cast<String, dynamic>(),
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = _data == null
            ? 'Unable to load capacity information. Please try again.'
            : 'Unable to refresh. The displayed information may be out of date.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openPage(String routeName) async {
    final booking = _booking;

    if (booking == null) return;

    await Navigator.pushNamed(
      context,
      routeName,
      arguments: booking,
    );

    if (!mounted) return;

    await _refresh();
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 210,
      color: const Color(0xFFFFEAD0),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 46,
            color: Color(0xFF79571E),
          ),
          SizedBox(height: 8),
          Text(
            'Attraction photo unavailable',
            style: TextStyle(
              color: Color(0xFF79571E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_CapacityData data) {
    final booking = _booking!;
    final imageUrl = data.coverImageUrl;
    final color = data.levelColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.white,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl == null || imageUrl.trim().isEmpty)
                _photoPlaceholder()
              else
                Image.network(
                  imageUrl,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _photoPlaceholder(),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.attractionName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.locationName,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.bookingCode,
                      style: const TextStyle(
                        color: Color(0xFF79571E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shortDate(booking.slot.startsAt)} '
                          '· ${slotTime(booking.slot)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withAlpha(60),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Crowd Level',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.levelLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Based on current attraction occupancy.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InformationCard(
          title: 'Current Visitors',
          icon: Icons.groups_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data.currentVisitors} / ${data.maximumCapacity}',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: data.occupancy.clamp(0.0, 1.0).toDouble(),
                  minHeight: 9,
                  backgroundColor: const Color(0xFFF0ECE5),
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(data.occupancy * 100).toStringAsFixed(0)}% occupied',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InformationCard(
          title: 'Available Capacity',
          icon: Icons.people_alt_outlined,
          child: Text(
            '${data.availableCapacity} space(s)',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _InformationCard(
          title: 'Estimated Waiting Time',
          icon: Icons.schedule_outlined,
          child: Text(
            'Not available. Please check with attraction staff.',
            style: TextStyle(
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InformationCard(
          title: 'Recommendation',
          icon: Icons.info_outline,
          child: Text(
            data.recommendation(booking.visitorCount),
            style: const TextStyle(
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _openPage(BookingQrPage.routeName),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF79571E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('Open QR Code'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _openPage(GeofencePage.routeName),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF79571E),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('View Geofence'),
        ),
        const SizedBox(height: 16),
        Text(
          'Last updated: ${clockTime(data.updatedAt)}\n'
              'Updates every 3 seconds while this page is open.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text('Capacity Alert'),
        actions: [
          IconButton(
            tooltip: 'Refresh capacity',
            onPressed: _loading || _booking == null
                ? null
                : () => _refresh(),
            icon: _loading
                ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _booking == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Open Capacity Alert from your booking details.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : data == null && _error == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF92400E),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => _refresh(),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (data != null) _buildContent(data),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE5E2DC),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: const Color(0xFF79571E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CapacityData {
  const _CapacityData({
    required this.attractionName,
    required this.locationName,
    required this.maximumCapacity,
    required this.currentVisitors,
    required this.updatedAt,
    this.coverImageUrl,
  });

  final String attractionName;
  final String locationName;
  final String? coverImageUrl;
  final int maximumCapacity;
  final int currentVisitors;
  final DateTime updatedAt;

  int get availableCapacity =>
      (maximumCapacity - currentVisitors)
          .clamp(0, maximumCapacity)
          .toInt();

  double get occupancy =>
      maximumCapacity > 0
          ? currentVisitors / maximumCapacity
          : 0;

  String get levelLabel {
    if (maximumCapacity <= 0) return 'UNAVAILABLE';
    if (currentVisitors >= maximumCapacity) return 'FULL';
    if (occupancy >= 0.8) return 'HIGH';
    if (occupancy >= 0.5) return 'MODERATE';

    return 'LOW';
  }

  Color get levelColor {
    if (maximumCapacity <= 0) return Colors.grey;
    if (occupancy >= 1) return const Color(0xFFB91C1C);
    if (occupancy >= 0.8) return const Color(0xFFC2410C);
    if (occupancy >= 0.5) return const Color(0xFFB77900);

    return const Color(0xFF15803D);
  }

  String recommendation(int partySize) {
    if (maximumCapacity <= 0) {
      return 'Capacity information is unavailable. Please contact staff.';
    }

    if (availableCapacity < partySize) {
      return 'There is currently insufficient capacity for your party. '
          'Please check with staff before entering.';
    }

    if (occupancy >= 0.8) {
      return 'The attraction is busy. Check with staff before entering.';
    }

    return 'There is currently enough capacity for your party. '
        'Entry still depends on your booking time and staff verification.';
  }

  factory _CapacityData.fromMap(Map<String, dynamic> map) {
    final maximumCapacity =
    (map['maximum_capacity'] as num).toInt();

    final currentVisitors =
    (map['current_visitors'] as num).toInt();

    if (maximumCapacity < 0 || currentVisitors < 0) {
      throw const FormatException('Invalid capacity values.');
    }

    return _CapacityData(
      attractionName: map['attraction_name'] as String,
      locationName: map['location_name'] as String? ?? '',
      coverImageUrl: map['cover_image_url'] as String?,
      maximumCapacity: maximumCapacity,
      currentVisitors: currentVisitors,
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ).toLocal(),
    );
  }
}