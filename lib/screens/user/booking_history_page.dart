import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import 'booking_details_page.dart';
import 'itinerary_planner_page.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});
  static const routeName = '/user/trips';
  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  final _repository = Module3Repository();
  late final TabController _tabs;
  late Future<List<TourBooking>> _bookings;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _bookings = _repository.fetchBookings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _bookings = _repository.fetchBookings());
    await _bookings;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Trips'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'Past'),
          Tab(text: 'Cancelled'),
        ],
      ),
    ),
    body: FutureBuilder<List<TourBooking>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _LoadError(onRetry: _refresh);
        final all = snapshot.data ?? const [];
        final groups = [
          all.where((b) => b.isUpcoming).toList(),
          all
              .where(
                (b) =>
                    b.status == BookingStatus.completed ||
                    (b.status == BookingStatus.confirmed &&
                        !b.slot.startsAt.isAfter(DateTime.now())),
              )
              .toList(),
          all.where((b) => b.status == BookingStatus.cancelled).toList(),
        ];
        return TabBarView(
          controller: _tabs,
          children: groups
              .map(
                (items) => RefreshIndicator(
                  onRefresh: _refresh,
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 150),
                            Icon(Icons.event_busy_outlined, size: 48),
                            Center(child: Text('No bookings in this section.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (_, index) => _BookingCard(
                            booking: items[index],
                            onChanged: _refresh,
                          ),
                        ),
                ),
              )
              .toList(),
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          Navigator.pushNamed(context, ItineraryPlannerPage.routeName),
      icon: const Icon(Icons.route_outlined),
      label: const Text('Plan itinerary'),
    ),
    bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onChanged});
  final TourBooking booking;
  final Future<void> Function() onChanged;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          BookingDetailsPage.routeName,
          arguments: booking,
        );
        onChanged();
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: booking.slot.coverImageUrl == null
                  ? Container(
                      width: 76,
                      height: 76,
                      color: const Color(0xFFFFE2B5),
                      child: const Icon(Icons.place_outlined),
                    )
                  : Image.network(
                      booking.slot.coverImageUrl!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 76,
                        height: 76,
                        child: Icon(Icons.place_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.slot.attractionName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${shortDate(booking.slot.startsAt)} · ${slotTime(booking.slot)}',
                  ),
                  Text(
                    '${booking.visitorCount} visitor(s) · ${booking.bookingCode}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: booking.status == BookingStatus.cancelled
                          ? Colors.red
                          : Colors.green.shade700,
                    ),
                  ),
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

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load your bookings.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
