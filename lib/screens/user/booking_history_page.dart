import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'booking_details_page.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  static const routeName = '/user/trips';

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  _BookingTab _selectedTab = _BookingTab.upcoming;

  static const _bookings = <_Booking>[
    _Booking(
      attraction: 'National Museum',
      date: 'Sep 17, 2026',
      time: '16:00 – 16:30',
      code: 'TF-99210',
      status: _BookingStatus.confirmed,
      icon: Icons.account_balance_rounded,
      layout: _BookingCardLayout.compact,
    ),
    _Booking(
      attraction: 'Lake Garden',
      date: 'Sep 19, 2026',
      time: '10:00 – 11:30',
      code: 'TF-77456',
      status: _BookingStatus.processing,
      icon: Icons.park_rounded,
      layout: _BookingCardLayout.featured,
    ),
    _Booking(
      attraction: 'Heritage Walking Tour',
      date: 'Aug 18, 2026',
      time: '09:30 – 11:00',
      code: 'TF-68124',
      status: _BookingStatus.completed,
      icon: Icons.directions_walk_rounded,
      layout: _BookingCardLayout.compact,
    ),
    _Booking(
      attraction: 'City Art Gallery',
      date: 'Aug 09, 2026',
      time: '14:00 – 15:30',
      code: 'TF-53081',
      status: _BookingStatus.cancelled,
      icon: Icons.palette_outlined,
      layout: _BookingCardLayout.featured,
    ),
  ];

  List<_Booking> get _visibleBookings {
    return switch (_selectedTab) {
      _BookingTab.upcoming => _bookings
          .where((booking) =>
              booking.status == _BookingStatus.confirmed ||
              booking.status == _BookingStatus.processing)
          .toList(),
      _BookingTab.past => _bookings
          .where((booking) => booking.status == _BookingStatus.completed)
          .toList(),
      _BookingTab.cancelled => _bookings
          .where((booking) => booking.status == _BookingStatus.cancelled)
          .toList(),
    };
  }

  void _openBooking(_Booking booking) {
    final statusLabel = switch (booking.status) {
      _BookingStatus.confirmed => 'Confirmed',
      _BookingStatus.processing => 'Processing',
      _BookingStatus.completed => 'Completed',
      _BookingStatus.cancelled => 'Cancelled',
    };

    Navigator.pushNamed(
      context,
      BookingDetailsPage.routeName,
      arguments: BookingDetailsArguments(
        attraction: booking.attraction,
        date: booking.date,
        time: booking.time,
        code: booking.code,
        visitors: 1,
        statusLabel: statusLabel,
        qrAvailable: booking.status == _BookingStatus.confirmed,
        canReschedule: booking.status == _BookingStatus.confirmed,
        canCancel: booking.status == _BookingStatus.confirmed ||
            booking.status == _BookingStatus.processing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _visibleBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 2,
        onLogout: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/sign-in',
          (route) => false,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookings',
              style: TextStyle(
                color: Color(0xFF131B2E),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'TourFlow',
              style: TextStyle(
                color: Color(0xFF79571E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: _RoleBadge()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: _BookingTabs(
              selectedTab: _selectedTab,
              onSelected: (tab) => setState(() => _selectedTab = tab),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E2DA)),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: bookings.isEmpty
                    ? const _EmptyBookings()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 24, 12, 32),
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return booking.layout == _BookingCardLayout.compact
                              ? _CompactBookingCard(
                                  booking: booking,
                                  onTap: () => _openBooking(booking),
                                )
                              : _FeaturedBookingCard(
                                  booking: booking,
                                  onTap: () => _openBooking(booking),
                                );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}

enum _BookingTab { upcoming, past, cancelled }

enum _BookingStatus { confirmed, processing, completed, cancelled }

enum _BookingCardLayout { compact, featured }

class _Booking {
  const _Booking({
    required this.attraction,
    required this.date,
    required this.time,
    required this.code,
    required this.status,
    required this.icon,
    required this.layout,
  });

  final String attraction;
  final String date;
  final String time;
  final String code;
  final _BookingStatus status;
  final IconData icon;
  final _BookingCardLayout layout;
}

class _BookingTabs extends StatelessWidget {
  const _BookingTabs({required this.selectedTab, required this.onSelected});

  final _BookingTab selectedTab;
  final ValueChanged<_BookingTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _BookingTab.values.map((tab) {
          final selected = tab == selectedTab;
          final label = switch (tab) {
            _BookingTab.upcoming => 'Upcoming',
            _BookingTab.past => 'Past',
            _BookingTab.cancelled => 'Cancelled',
          };

          return Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF4F4539),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompactBookingCard extends StatelessWidget {
  const _CompactBookingCard({required this.booking, required this.onTap});

  final _Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BookingCardSurface(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 82,
              height: 102,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE2B5),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(
                booking.icon,
                size: 38,
                color: const Color(0xFF79571E),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          booking.attraction,
                          style: const TextStyle(
                            color: Color(0xFF131B2E),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MetadataLine(
                    icon: Icons.calendar_month_outlined,
                    text: booking.date,
                  ),
                  const SizedBox(height: 4),
                  _MetadataLine(
                    icon: Icons.schedule_rounded,
                    text: booking.time,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CODE: ${booking.code}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF79571E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBookingCard extends StatelessWidget {
  const _FeaturedBookingCard({required this.booking, required this.onTap});

  final _Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BookingCardSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 128,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1DC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  booking.icon,
                  size: 58,
                  color: const Color(0xFF79571E),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _StatusBadge(status: booking.status),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.attraction,
                        style: const TextStyle(
                          color: Color(0xFF131B2E),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF79571E),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    _MetadataLine(
                      icon: Icons.calendar_month_outlined,
                      text: booking.date,
                    ),
                    _MetadataLine(
                      icon: Icons.confirmation_num_outlined,
                      text: booking.code,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCardSurface extends StatelessWidget {
  const _BookingCardSurface({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x200F172A),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      _BookingStatus.confirmed => (
          'CONFIRMED',
          const Color(0xFFFFE2A8),
          const Color(0xFF79571E),
        ),
      _BookingStatus.processing => (
          'PROCESSING',
          const Color(0xFFFFE2A8),
          const Color(0xFF79571E),
        ),
      _BookingStatus.completed => (
          'COMPLETED',
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
        ),
      _BookingStatus.cancelled => (
          'CANCELLED',
          const Color(0xFFFEE2E2),
          const Color(0xFFBA1A1A),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF4F4539)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4F4539),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        border: Border.all(color: const Color(0xFFE8D3B7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'TOURIST',
        style: TextStyle(
          color: Color(0xFF79571E),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 54,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Text(
              'No bookings in this section',
              style: TextStyle(
                color: Color(0xFF131B2E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
