import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import 'booking_details_page.dart';
import 'itinerary_planner_page.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  static const routeName = TourFlowRoutes.userTrips;

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _repository = Module3Repository();

  late final TabController _tabs;
  Timer? _refreshTimer;

  List<TourBooking> _bookings = const [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  bool _hasError = false;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 3, vsync: this);

    _refresh();
    _startAutoRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;

    if (_isForeground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }

      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();

    if (!_isForeground) return;

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted || !_isForeground) return;
        if (ModalRoute.of(context)?.isCurrent != true) return;

        _refresh();
      },
    );
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _refresh() async {
    if (!mounted || !_isForeground || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;

      if (!_hasLoaded) {
        _isLoading = true;
      }
    });

    try {
      final updatedBookings = await _repository.fetchBookings();

      if (!mounted) return;

      setState(() {
        _bookings = updatedBookings;
        _hasLoaded = true;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openBooking(TourBooking booking) async {
    await Navigator.pushNamed(
      context,
      BookingDetailsPage.routeName,
      arguments: booking,
    );

    if (!mounted) return;

    await _refresh();
  }

  Future<void> _openItinerary() async {
    await Navigator.pushNamed(
      context,
      ItineraryPlannerPage.routeName,
    );

    if (!mounted) return;

    await _refresh();
  }

  Widget _buildBookingList(
      List<TourBooking> items,
      String emptyMessage,
      String storageKey,
      ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: items.isEmpty
          ? ListView(
        key: PageStorageKey<String>(storageKey),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: Colors.black45,
          ),
          const SizedBox(height: 12),
          Text(
            emptyMessage,
            textAlign: TextAlign.center,
          ),
        ],
      )
          : ListView.builder(
        key: PageStorageKey<String>(storageKey),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, index) {
          final booking = items[index];

          return _BookingCard(
            key: ValueKey(booking.id),
            booking: booking,
            onTap: () => _openBooking(booking),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final active = <TourBooking>[];
    final past = <TourBooking>[];
    final cancelled = <TourBooking>[];

    for (final booking in _bookings) {
      if (_isFinished(booking)) {
        past.add(booking);
      } else if (booking.isCheckedIn) {
        active.add(booking);
      } else if (booking.isCancelled) {
        cancelled.add(booking);
      } else if (booking.slot.endsAt.isBefore(now)) {
        past.add(booking);
      } else {
        active.add(booking);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            tooltip: 'Refresh bookings',
            onPressed: _isRefreshing ? null : () => _refresh(),
            icon: _isRefreshing
                ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : !_hasLoaded && _hasError
          ? _LoadError(
        onRetry: () => _refresh(),
      )
          : Column(
        children: [
          if (_hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: const Color(0xFFFFF3CD),
              child: const Text(
                'Unable to refresh bookings. '
                    'The displayed status may be out of date.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildBookingList(
                  active,
                  'No active bookings.',
                  'active-bookings',
                ),
                _buildBookingList(
                  past,
                  'No past bookings.',
                  'past-bookings',
                ),
                _buildBookingList(
                  cancelled,
                  'No cancelled bookings.',
                  'cancelled-bookings',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openItinerary,
        icon: const Icon(Icons.route_outlined),
        label: const Text('Plan itinerary'),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final TourBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _bookingStatusColor(booking);
    final imageUrl = booking.slot.coverImageUrl;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl == null || imageUrl.isEmpty
                    ? const _AttractionPlaceholder()
                    : Image.network(
                  imageUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const _AttractionPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.slot.attractionName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shortDate(booking.slot.startsAt)} '
                          '· ${slotTime(booking.slot)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.visitorCount} visitor(s) '
                          '· ${booking.bookingCode}',
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _bookingStatusLabel(booking),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (booking.isCheckedIn &&
                        !_isFinished(booking)) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Your visit is in progress.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttractionPlaceholder extends StatelessWidget {
  const _AttractionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      color: const Color(0xFFFFE2B5),
      child: const Icon(Icons.place_outlined),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load your bookings.'),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

bool _isFinished(TourBooking booking) =>
    booking.isCompleted || booking.isCheckedOut;

String _bookingStatusLabel(TourBooking booking) {
  if (_isFinished(booking)) return 'Completed';
  if (booking.isCheckedIn) return 'Checked In';
  if (booking.isCancelled) return 'Cancelled';

  return 'Confirmed';
}

Color _bookingStatusColor(TourBooking booking) {
  if (_isFinished(booking)) {
    return const Color(0xFF2563EB);
  }

  if (booking.isCheckedIn) {
    return const Color(0xFF15803D);
  }

  if (booking.isCancelled) {
    return const Color(0xFFB91C1C);
  }

  return const Color(0xFF92400E);
}