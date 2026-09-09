import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/tourflow_localization.dart';
import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'booking_details_page.dart';
import 'itinerary_planner_page.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  static const routeName = TourFlowRoutes.userTrips;

  @override
  State<BookingHistoryPage> createState() =>
      _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final Module3Repository _repository = Module3Repository();

  late final TabController _tabs;

  Timer? _refreshTimer;

  List<TourBooking> _bookings = const [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  bool _hasError = false;
  bool _isForeground = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _tabs = TabController(
      length: 3,
      vsync: this,
    );

    _refresh();
    _startAutoRefresh();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    _isForeground =
        state == AppLifecycleState.resumed;

    if (_isForeground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }

      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _stopAutoRefresh();

    WidgetsBinding.instance.removeObserver(this);

    _tabs.dispose();

    super.dispose();
  }

  // ============================================================
  // AUTO REFRESH
  // ============================================================

  void _startAutoRefresh() {
    _stopAutoRefresh();

    if (!_isForeground) {
      return;
    }

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted || !_isForeground) {
          return;
        }

        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        _refresh();
      },
    );
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ============================================================
  // REFRESH BOOKINGS
  // ============================================================

  Future<void> _refresh() async {
    if (!mounted ||
        !_isForeground ||
        _isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;

      if (!_hasLoaded) {
        _isLoading = true;
      }
    });

    try {
      final updatedBookings =
      await _repository.fetchBookings();

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = updatedBookings;
        _hasLoaded = true;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN BOOKING DETAILS
  // ============================================================

  Future<void> _openBooking(
      TourBooking booking,
      ) async {
    await Navigator.pushNamed(
      context,
      BookingDetailsPage.routeName,
      arguments: booking,
    );

    if (!mounted) {
      return;
    }

    await _refresh();
  }

  // ============================================================
  // OPEN ITINERARY
  // ============================================================

  Future<void> _openItinerary() async {
    await Navigator.pushNamed(
      context,
      ItineraryPlannerPage.routeName,
    );

    if (!mounted) {
      return;
    }

    await _refresh();
  }

  // ============================================================
  // BOOKING LIST
  // ============================================================

  Widget _buildBookingList(
      List<TourBooking> items,
      String emptyMessage,
      String storageKey,
      ) {
    return RefreshIndicator(
      onRefresh: _refresh,

      child: items.isEmpty
          ? ListView(
        key: PageStorageKey<String>(
          storageKey,
        ),
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(
            height: 120,
          ),

          const Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: Colors.black45,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      )
          : ListView.builder(
        key: PageStorageKey<String>(
          storageKey,
        ),
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: items.length,
        itemBuilder: (
            context,
            index,
            ) {
          final booking =
          items[index];

          return _BookingCard(
            key: ValueKey(
              booking.id,
            ),
            booking: booking,
            onTap: () {
              _openBooking(
                booking,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final now = DateTime.now();

    final active =
    <TourBooking>[];

    final past =
    <TourBooking>[];

    final cancelled =
    <TourBooking>[];

    // ==========================================================
    // SORT BOOKINGS INTO TABS
    // ==========================================================

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
      backgroundColor:
      const Color(
        0xFFFAF8FF,
      ),

      // ========================================================
      // TOURIST SIDEBAR
      // ========================================================

      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',

        // My Trips & Bookings
        selectedIndex: 2,

        onLogout: () async {
          await signOutAndReturnToSignIn(
            context,
          );
        },
      ),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
        const Color(
          0xFFFAF8FF,
        ),

        surfaceTintColor:
        Colors.transparent,

        elevation: 1,

        shadowColor:
        const Color(
          0x140F172A,
        ),

        // ======================================================
        // REMOVE DEFAULT BACK BUTTON
        // ======================================================

        automaticallyImplyLeading: false,

        // ======================================================
        // NEW SIDEBAR MENU ICON
        // ======================================================

        leading: Builder(
          builder: (
              context,
              ) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(
                Icons.menu_rounded,
              ),
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer();
              },
            );
          },
        ),

        // ======================================================
        // MY TRIPS TITLE
        // ======================================================

        title: const TourFlowText(
          'My Trips',
          style: TextStyle(
            color: Color(
              0xFF131B2E,
            ),
            fontSize: 20,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        centerTitle: false,

        // ======================================================
        // NO REFRESH ICON
        // ======================================================

        actions: const [],

        // ======================================================
        // ACTIVE / PAST / CANCELLED
        // ======================================================

        bottom: TabBar(
          controller: _tabs,

          labelColor:
          const Color(
            0xFF79571E,
          ),

          unselectedLabelColor:
          const Color(
            0xFF6B7280,
          ),

          indicatorColor:
          const Color(
            0xFF79571E,
          ),

          tabs: const [
            Tab(child: TourFlowText('Active')),
            Tab(child: TourFlowText('Past')),
            Tab(child: TourFlowText('Cancelled')),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : !_hasLoaded &&
          _hasError
          ? _LoadError(
        onRetry: () {
          _refresh();
        },
      )
          : Column(
        children: [
          // ===========================================
          // REFRESH ERROR MESSAGE
          // ===========================================

          if (_hasError)
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color:
              const Color(
                0xFFFFF3CD,
              ),
              child:
              const TourFlowText(
                'Unable to refresh bookings. The displayed status may be out of date.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  Color(
                    0xFF92400E,
                  ),
                  fontSize: 12,
                ),
              ),
            ),

          // ===========================================
          // TABS
          // ===========================================

          Expanded(
            child:
            TabBarView(
              controller:
              _tabs,
              children: [
                // ACTIVE

                _buildBookingList(
                  active,
                  context.tr('No active bookings.'),
                  'active-bookings',
                ),

                // PAST

                _buildBookingList(
                  past,
                  context.tr('No past bookings.'),
                  'past-bookings',
                ),

                // CANCELLED

                _buildBookingList(
                  cancelled,
                  context.tr('No cancelled bookings.'),
                  'cancelled-bookings',
                ),
              ],
            ),
          ),
        ],
      ),

      // ========================================================
      // PLAN ITINERARY
      // ========================================================

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _openItinerary,
        icon:
        const Icon(
          Icons.route_outlined,
        ),
        label:
        const TourFlowText(
          'Plan itinerary',
        ),
      ),
    );
  }
}

// ============================================================
// BOOKING CARD
// ============================================================

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final TourBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final statusColor =
    _bookingStatusColor(
      booking,
    );

    final imageUrl =
        booking.slot.coverImageUrl;

    return Card(
      color: Colors.white,

      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      clipBehavior:
      Clip.antiAlias,

      child: InkWell(
        onTap: onTap,

        child: Padding(
          padding:
          const EdgeInsets.all(
            14,
          ),

          child: Row(
            children: [
              // =================================================
              // IMAGE
              // =================================================

              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                child:
                imageUrl == null ||
                    imageUrl.isEmpty
                    ? const _AttractionPlaceholder()
                    : Image.network(
                  imageUrl,
                  width: 76,
                  height: 76,
                  fit:
                  BoxFit.cover,
                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return const _AttractionPlaceholder();
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // =================================================
              // DETAILS
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.slot
                          .attractionName,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '${shortDate(booking.slot.startsAt)} '
                          '· ${slotTime(booking.slot)}',
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '${booking.visitorCount} visitor(s) '
                          '· ${booking.bookingCode}',
                      style:
                      const TextStyle(
                        fontSize: 11,
                        color:
                        Colors.black54,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // =============================================
                    // STATUS
                    // =============================================

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        statusColor.withAlpha(
                          20,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                      child: Text(
                        _bookingStatusLabel(
                          booking,
                        ),
                        style:
                        TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          statusColor,
                        ),
                      ),
                    ),

                    // =============================================
                    // CHECKED IN
                    // =============================================

                    if (booking
                        .isCheckedIn &&
                        !_isFinished(
                          booking,
                        )) ...[
                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Your visit is in progress.',
                        style:
                        TextStyle(
                          fontSize: 11,
                          color:
                          Color(
                            0xFF15803D,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ATTRACTION IMAGE PLACEHOLDER
// ============================================================

class _AttractionPlaceholder extends StatelessWidget {
  const _AttractionPlaceholder();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: 76,
      height: 76,

      color:
      const Color(
        0xFFFFE2B5,
      ),

      child:
      const Icon(
        Icons.place_outlined,
        color:
        Color(
          0xFF79571E,
        ),
      ),
    );
  }
}

// ============================================================
// LOAD ERROR
// ============================================================

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color:
            Colors.black45,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Could not load your bookings.',
          ),

          const SizedBox(
            height: 8,
          ),

          TextButton(
            onPressed:
            onRetry,
            child:
            const Text(
              'Try again',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FINISHED
// ============================================================

bool _isFinished(
    TourBooking booking,
    ) {
  return booking.isCompleted ||
      booking.isCheckedOut;
}

// ============================================================
// STATUS LABEL
// ============================================================

String _bookingStatusLabel(
    TourBooking booking,
    ) {
  if (_isFinished(booking)) {
    return 'Completed';
  }

  if (booking.isCheckedIn) {
    return 'Checked In';
  }

  if (booking.isCancelled) {
    return 'Cancelled';
  }

  return 'Confirmed';
}

// ============================================================
// STATUS COLOR
// ============================================================

Color _bookingStatusColor(
    TourBooking booking,
    ) {
  if (_isFinished(booking)) {
    return const Color(
      0xFF2563EB,
    );
  }

  if (booking.isCheckedIn) {
    return const Color(
      0xFF15803D,
    );
  }

  if (booking.isCancelled) {
    return const Color(
      0xFFB91C1C,
    );
  }

  return const Color(
    0xFF92400E,
  );
}
