import 'package:cd_project/l10n/tourflow_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/module3_models.dart';
import '../../models/saved_itinerary.dart';
import '../../repositories/module3_repository.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'community_itineraries_page.dart';

class ItineraryPlannerPage extends StatefulWidget {
  const ItineraryPlannerPage({super.key});
  static const routeName = '/itinerary-planner';

  @override
  State<ItineraryPlannerPage> createState() => _ItineraryPlannerPageState();
}

class _ItineraryPlannerPageState extends State<ItineraryPlannerPage> {
  final _repository = Module3Repository();
  final _title = TextEditingController(text: 'My Day Trip');
  final _selectedIds = <String>{};
  late Future<List<TourBooking>> _bookings;
  List<SavedItinerary>? _saved;
  bool _savedError = false;
  bool _busy = false;
  bool _builderOpen = false;
  String? _editingId;
  ItineraryPlan? _roadPlan;
  DateTime? _day;

  DateTime _date(DateTime value) => DateTime(value.year, value.month, value.day);

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: TourFlowText(message)),
    );
  }

  Future<void> _openBooking(TourBooking booking, {bool reschedule = false}) async {
    await Navigator.pushNamed(
      context,
      reschedule ? '/reschedule-booking' : '/booking-details',
      arguments: booking,
    );
    if (mounted) await _refresh();
  }

  @override
  void initState() {
    super.initState();
    _bookings = _repository.fetchBookings();
    _loadSaved();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    if (mounted) setState(() { _saved = null; _savedError = false; });
    try {
      final rows = await _repository.fetchItineraries();
      if (mounted) setState(() => _saved = rows);
    } catch (_) {
      if (mounted) setState(() => _savedError = true);
    }
  }

  void _edit(SavedItinerary? itinerary, List<TourBooking> available) {
    final valid = available.map((booking) => booking.id).toSet();
    final ids = itinerary?.bookingIds ?? const <String>[];
    setState(() {
      _builderOpen = true;
      _editingId = itinerary?.id;
      _title.text = itinerary?.title ?? 'My Day Trip';
      _day = itinerary == null ? null : _date(itinerary.date);
      _selectedIds
        ..clear()
        ..addAll(ids.where(valid.contains));
      _roadPlan = null;
    });
    if (ids.any((id) => !valid.contains(id))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: TourFlowText(
          'Some visits are no longer upcoming. Review the remaining bookings.',
        ),
      ));
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _bookings = _repository.fetchBookings();
      _roadPlan = null;
    });
    try {
      final latest = await _bookings;
      if (!mounted) return;
      final validIds = latest.where((b) => b.isUpcoming).map((b) => b.id).toSet();
      final removed = _selectedIds.difference(validIds).length;
      setState(() => _selectedIds.removeWhere((id) => !validIds.contains(id)));
      if (removed > 0) _message('$removed unavailable visits were removed from this draft.');
    } catch (_) {
      // The booking FutureBuilder displays the load failure and retry action.
    }
    await _loadSaved();
  }

  Future<void> _save(ItineraryPlan plan) async {
    if (plan.bookings.isEmpty || plan.hasConflict || plan.bookings.length > 20) {
      _message('Select up to 20 visits and resolve travel conflicts before saving.');
      return;
    }
    if (_title.text.trim().length < 2 || _title.text.trim().length > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TourFlowText('Enter an itinerary name.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await _repository.saveItinerary(
        title: _title.text,
        plan: plan,
        itineraryId: _editingId,
      );
      if (!mounted) return;
      setState(() => _editingId = id);
      await _loadSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TourFlowText('Itinerary saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        final changed = error.toString().contains('ITINERARY_BOOKING_UNAVAILABLE');
        final conflict = error.toString().contains('ITINERARY_TRAVEL_CONFLICT');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: TourFlowText(changed
              ? 'A visit changed or closed. Refresh before saving.'
              : conflict ? 'Travel conflict detected. Recalculate or reschedule a visit.'
              : 'Could not save the itinerary. Please retry.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(SavedItinerary itinerary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TourFlowText('Delete itinerary?'),
        content: const TourFlowText(
          'Bookings remain in Trips. A published copy is also removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const TourFlowText('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const TourFlowText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.deleteItinerary(itinerary.id);
      if (!mounted) return;
      if (_editingId == itinerary.id) _edit(null, const <TourBooking>[]);
      await _loadSaved();
    } catch (_) {
      _message('Could not delete the itinerary. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish(SavedItinerary itinerary) async {
    final description = TextEditingController();
    var showAuthor = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: TourFlowText(
            itinerary.isPublished ? 'Update shared itinerary' : 'Share itinerary',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TourFlowText(
                  'Only the title, attractions, visit times and travel estimates '
                  'are shared. Booking codes and QR tickets stay private.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Short description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: showAuthor,
                  title: const TourFlowText('Show my profile name'),
                  onChanged: (value) =>
                      setDialogState(() => showAuthor = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const TourFlowText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const TourFlowText('Share'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      description.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      await _repository.publishItinerary(
        itineraryId: itinerary.id,
        description: description.text,
        showAuthor: showAuthor,
      );
      await _loadSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TourFlowText('Itinerary is now discoverable.')),
        );
      }
    } catch (_) {
      _message('Could not share the itinerary. Save your changes and retry.');
    } finally {
      description.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish(SavedItinerary itinerary) async {
    setState(() => _busy = true);
    try {
      await _repository.unpublishItinerary(itinerary.id);
      await _loadSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TourFlowText('Itinerary is private again.')),
        );
      }
    } catch (_) {
      _message('Could not make the itinerary private. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: UserSidebar(
      displayName: '',
      email: '',
      selectedIndex: 5,
      onLogout: () async => signOutAndReturnToSignIn(context),
    ),
    appBar: AppBar(
      title: const TourFlowText('Itinerary Planner'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: FutureBuilder<List<TourBooking>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const TourFlowText('Could not load confirmed bookings.'),
              TextButton(onPressed: _refresh, child: const TourFlowText('Retry')),
            ]),
          );
        }
        final available = (snapshot.data ?? const <TourBooking>[])
            .where((booking) => booking.isUpcoming)
            .toList();
        final dates = available.map((b) => _date(b.slot.startsAt)).toSet().toList()..sort();
        final visible = _day == null ? available
            : available.where((b) => _date(b.slot.startsAt) == _day).toList();
        final plan = _roadPlan ?? ItineraryPlan.build(
          available.where((booking) => _selectedIds.contains(booking.id)),
        );
        final selectedDates = plan.bookings.map((b) => _date(b.slot.startsAt)).toSet().toList()..sort();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_builderOpen) ...[
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const TourFlowText(
                  'Saved itineraries',
                  style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  CommunityItinerariesPage.routeName,
                ),
                icon: const Icon(Icons.public_outlined),
                label: const TourFlowText('Discover'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _edit(null, available),
                icon: const Icon(Icons.add),
                label: const TourFlowText('New'),
              ),
            ]),
            if (_savedError)
              const TourFlowText('Could not load saved plans. Refresh to retry.')
            else if (_saved == null)
              const LinearProgressIndicator()
            else if (_saved!.isEmpty)
              const TourFlowText('Your saved plans will appear here.')
            else
              ..._saved!.map((saved) => Card(
                child: ListTile(
                  leading: Icon(
                    saved.isPublished ? Icons.public : Icons.lock_outline,
                  ),
                  title: TourFlowText(saved.title),
                  subtitle: TourFlowText(
                    '${shortDate(saved.date)} – ${shortDate(saved.endDate ?? saved.date)} · ${saved.bookingIds.length} visits · '
                    '${saved.isPublished ? 'Shared' : 'Private'}',
                  ),
                  selected: saved.id == _editingId,
                  onTap: _busy ? null : () => _edit(saved, available),
                  trailing: PopupMenuButton<String>(
                    enabled: !_busy,
                    onSelected: (action) {
                      if (action == 'share') _publish(saved);
                      if (action == 'private') _unpublish(saved);
                      if (action == 'delete') _delete(saved);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'share',
                        child: TourFlowText(
                          saved.isPublished ? 'Update shared copy' : 'Share publicly',
                        ),
                      ),
                      if (saved.isPublished)
                        const PopupMenuItem(
                          value: 'private',
                          child: TourFlowText('Make private'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: TourFlowText('Delete'),
                      ),
                    ],
                  ),
                ),
              )),
            const SizedBox(height: 16),
            ] else ...[
              Row(children: [
                IconButton(
                  tooltip: 'Back to my itineraries',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _busy ? null : () => setState(() {
                    _builderOpen = false;
                    _editingId = null;
                    _selectedIds.clear();
                    _roadPlan = null;
                  }),
                ),
                Expanded(child: TourFlowText(
                  _editingId == null ? 'Create itinerary' : 'Edit itinerary',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
              ]),
              const SizedBox(height: 8),
            ],
            if (_builderOpen) ...[
            const TourFlowText('Build a single-day or multi-day trip. Visits stay in booking-time order. Overnight transfers and accommodation are not included.'),
            const SizedBox(height: 12),
            TextField(
              enabled: !_busy,
              maxLength: 120,
              controller: _title,
              decoration: InputDecoration(
                labelText: context.tr('Itinerary name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const TourFlowText(
              'Choose confirmed bookings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (available.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: TourFlowText(
                    'Create an upcoming booking before building an itinerary.',
                  ),
                ),
              ),
            Wrap(spacing: 8, runSpacing: 4, children: [
              ChoiceChip(label: const TourFlowText('All days'), selected: _day == null,
                onSelected: _busy ? null : (_) => setState(() => _day = null)),
              ...dates.map((date) => ChoiceChip(label: Text(shortDate(date)), selected: _day == date,
                onSelected: _busy ? null : (_) => setState(() => _day = date))),
            ]),
            Wrap(spacing: 8, children: [
              TextButton(onPressed: _busy ? null : () => setState(() {
                _selectedIds.addAll(visible.map((b) => b.id));
                _roadPlan = null;
              }), child: const TourFlowText('Select visible visits')),
              TextButton(onPressed: _busy ? null : () => setState(() {
                _selectedIds.clear(); _roadPlan = null;
              }), child: const TourFlowText('Clear selection')),
              TextButton.icon(onPressed: _busy ? null : () async {
                await Navigator.pushNamed(context, '/attraction-discovery');
                if (mounted) await _refresh();
              }, icon: const Icon(Icons.add_location_alt_outlined), label: const TourFlowText('Find more attractions')),
            ]),
            ...visible.map((booking) => Card(
              color: Colors.white,
              child: CheckboxListTile(
                value: _selectedIds.contains(booking.id),
                onChanged: _busy
                    ? null
                    : (checked) => setState(() {
                        _roadPlan = null;
                        checked == true
                            ? _selectedIds.add(booking.id)
                            : _selectedIds.remove(booking.id);
                      }),
                title: TourFlowText(
                  booking.slot.attractionName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: TourFlowText(
                  '${shortDate(booking.slot.startsAt)} · ${slotTime(booking.slot)}',
                ),
              ),
            )),
            if (plan.bookings.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (plan.bookings.length > 20)
                const TourFlowText('A trip supports up to 20 visits. Remove some visits before saving.'),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                TourFlowText('${plan.bookings.length} visits · ${selectedDates.length} planned days',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${shortDate(selectedDates.first)} – ${shortDate(selectedDates.last)}'),
                Text('${plan.legs.fold<int>(0, (sum, leg) => sum + leg.travelMinutes)} min travel + buffers · '
                  '${plan.legs.fold<double>(0, (sum, leg) => sum + leg.distanceKm).toStringAsFixed(1)} km'),
                Text('${plan.bookings.fold<int>(0, (sum, b) => sum + b.slot.endsAt.difference(b.slot.startsAt).inMinutes)} min at attractions'),
                const TourFlowText('Removing a visit here does not cancel its booking.'),
              ]))),
              const TourFlowText(
                'Travel time and safety buffers update automatically when visits change.',
              ),
              _PlanStatus(conflict: plan.hasConflict),
              ...selectedDates.map((date) => Column(children: [
                ListTile(title: Text(shortDate(date), style: const TextStyle(fontWeight: FontWeight.bold))),
                _ItineraryMap(key: ValueKey('$date-${plan.bookings.map((b) => b.id).join()}'),
                  plan: ItineraryPlan.build(plan.bookings.where((b) => _date(b.slot.startsAt) == date))),
              ])),
              ...List.generate(plan.bookings.length, (index) {
                final booking = plan.bookings[index];
                final newDay = index == 0 || !ItineraryPlan.sameDay(
                    plan.bookings[index - 1].slot.startsAt, booking.slot.startsAt);
                final leg = newDay ? null : plan.legs[index - 1];
                final gap = index == 0 ? 0 : booking.slot.startsAt
                    .difference(plan.bookings[index - 1].slot.endsAt).inMinutes;
                final spare = gap - (leg?.travelMinutes ?? 0);
                return Column(children: [
                  if (newDay) ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(shortDate(booking.slot.startsAt),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: index == 0 ? null : const TourFlowText('New day — overnight travel is not calculated'),
                  ),
                  if (leg != null)
                    ListTile(
                      leading: const Icon(Icons.directions_car_outlined),
                      title: TourFlowText(
                        '${leg.travelMinutes} min including safety buffer\n'
                        '${spare < 0 ? '${-spare} min short — reschedule a visit' : '$spare min free time'}',
                      ),
                      subtitle: leg.distanceKm == 0
                          ? const TourFlowText('Distance unavailable')
                          : TourFlowText(
                              '${leg.distanceKm.toStringAsFixed(1)} km '
                              '${plan.usesRoadRoutes ? 'by road' : 'approximate'}',
                            ),
                    ),
                  Card(
                    child: ListTile(
                      leading: TourFlowText(
                        clockTime(booking.slot.startsAt),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      title: TourFlowText(booking.slot.attractionName),
                      subtitle: TourFlowText(slotTime(booking.slot)),
                      onTap: _busy ? null : () => _openBooking(booking),
                      trailing: PopupMenuButton<String>(
                        enabled: !_busy,
                        onSelected: (action) {
                          if (action == 'view') _openBooking(booking);
                          if (action == 'reschedule') _openBooking(booking, reschedule: true);
                          if (action == 'remove') setState(() {
                            _selectedIds.remove(booking.id); _roadPlan = null;
                          });
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'view', child: TourFlowText('Booking details')),
                          PopupMenuItem(value: 'reschedule', child: TourFlowText('Reschedule')),
                          PopupMenuItem(value: 'remove', child: TourFlowText('Remove from itinerary')),
                        ],
                      ),
                    ),
                  ),
                ]);
              }),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy || plan.hasConflict || plan.bookings.length > 20 ? null : () => _save(plan),
                icon: const Icon(Icons.save_outlined),
                label: TourFlowText(
                  _busy
                      ? 'Saving…'
                      : _editingId == null
                          ? 'Save Itinerary'
                          : 'Update Itinerary',
                ),
              ),
            ],
            ],
          ],
        );
      },
    ),
  );
}

class _ItineraryMap extends StatelessWidget {
  const _ItineraryMap({required this.plan, super.key});
  final ItineraryPlan plan;

  @override
  Widget build(BuildContext context) {
    final located = plan.bookings
        .where((booking) =>
            booking.slot.latitude != null && booking.slot.longitude != null)
        .toList();
    if (located.length < 2) return const SizedBox.shrink();
    final points = located
        .map((booking) => LatLng(
              booking.slot.latitude!,
              booking.slot.longitude!,
            ))
        .toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 230,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(36),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cd_project',
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: points,
                    color: const Color(0xFF79571E),
                    strokeWidth: 4,
                  ),
                ]),
                MarkerLayer(
                  markers: List.generate(points.length, (index) => Marker(
                    point: points[index],
                    width: 38,
                    height: 38,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFFFD08B),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: TourFlowText(
              '© OpenStreetMap contributors. Lines show visit order, not road geometry.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.conflict});
  final bool conflict;

  @override
  Widget build(BuildContext context) => Card(
    color: conflict ? const Color(0xFFFFEDEA) : const Color(0xFFDCFCE7),
    child: ListTile(
      leading: Icon(
        conflict ? Icons.warning_amber : Icons.check_circle_outline,
        color: conflict ? Colors.red : Colors.green.shade700,
      ),
      title: TourFlowText(
        conflict ? 'Conflict Detected' : 'Conflict-Free',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: TourFlowText(conflict
          ? 'There is insufficient time between at least two visits.'
          : 'Visits include travel time and safety buffers.'),
    ),
  );
}
