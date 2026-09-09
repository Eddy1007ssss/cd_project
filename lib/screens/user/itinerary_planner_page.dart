import 'package:cd_project/l10n/tourflow_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/module3_models.dart';
import '../../models/saved_itinerary.dart';
import '../../repositories/module3_repository.dart';
import '../../services/itinerary_routing_service.dart';
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
  final _router = ItineraryRoutingService();
  final _title = TextEditingController(text: 'My Penang Day');
  final _selectedIds = <String>{};
  late Future<List<TourBooking>> _bookings;
  List<SavedItinerary>? _saved;
  bool _savedError = false;
  bool _busy = false;
  bool _routing = false;
  String? _editingId;
  ItineraryPlan? _roadPlan;

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
      _editingId = itinerary?.id;
      _title.text = itinerary?.title ?? 'My Penang Day';
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
    await _loadSaved();
  }

  Future<void> _calculate(ItineraryPlan plan) async {
    setState(() => _routing = true);
    try {
      final routed = await _router.calculate(plan);
      if (mounted) setState(() => _roadPlan = routed);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: TourFlowText(
            'Driving route unavailable. Approximate times are still shown.',
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Future<void> _save(ItineraryPlan plan) async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: TourFlowText(changed
              ? 'A visit changed or closed. Refresh before saving.'
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
          onPressed: _busy || _routing ? null : _refresh,
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
          return const Center(
            child: TourFlowText('Could not load confirmed bookings.'),
          );
        }
        final available = (snapshot.data ?? const <TourBooking>[])
            .where((booking) => booking.isUpcoming)
            .toList();
        final plan = _roadPlan ?? ItineraryPlan.build(
          available.where((booking) => _selectedIds.contains(booking.id)),
        );
        final sameDay = plan.bookings
                .map((booking) => shortDate(booking.slot.startsAt))
                .toSet()
                .length <=
            1;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              const Expanded(
                child: TourFlowText(
                  'Saved itineraries',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                onPressed: _busy || _routing ? null : () => _edit(null, available),
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
                    '${shortDate(saved.date)} · ${saved.bookingIds.length} visits · '
                    '${saved.isPublished ? 'Shared' : 'Private'}',
                  ),
                  selected: saved.id == _editingId,
                  onTap: _busy || _routing ? null : () => _edit(saved, available),
                  trailing: PopupMenuButton<String>(
                    enabled: !_busy && !_routing,
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
            TextField(
              enabled: !_busy && !_routing,
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
            ...available.map((booking) => Card(
              color: Colors.white,
              child: CheckboxListTile(
                value: _selectedIds.contains(booking.id),
                onChanged: _busy || _routing
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
              if (!sameDay)
                const TourFlowText(
                  'Choose visits on the same day, or make separate itineraries.',
                ),
              if (plan.bookings.length > 1)
                OutlinedButton.icon(
                  onPressed: _busy || _routing || !sameDay
                      ? null
                      : () => _calculate(plan),
                  icon: const Icon(Icons.directions_car),
                  label: TourFlowText(
                    _routing ? 'Calculating…' : 'Calculate driving route',
                  ),
                ),
              TourFlowText(plan.usesRoadRoutes
                  ? 'Road estimates include a 15-minute safety buffer.'
                  : 'Travel times are approximate until a route is calculated.'),
              _PlanStatus(conflict: plan.hasConflict),
              if (plan.bookings.length > 1) _ItineraryMap(plan: plan),
              ...List.generate(plan.bookings.length, (index) {
                final booking = plan.bookings[index];
                final leg = index == 0 ? null : plan.legs[index - 1];
                return Column(children: [
                  if (leg != null)
                    ListTile(
                      leading: const Icon(Icons.directions_car_outlined),
                      title: TourFlowText(
                        '${leg.travelMinutes} min including safety buffer',
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
                    ),
                  ),
                ]);
              }),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy || _routing || !sameDay ? null : () => _save(plan),
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
        );
      },
    ),
  );
}

class _ItineraryMap extends StatelessWidget {
  const _ItineraryMap({required this.plan});
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
              'The line shows visit order. Road distance and time are listed below.',
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
