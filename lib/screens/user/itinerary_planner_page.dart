import 'package:flutter/material.dart';
import 'package:cd_project/l10n/tourflow_localization.dart';

import '../../models/module3_models.dart';
import '../../models/saved_itinerary.dart';
import '../../services/itinerary_routing_service.dart';
import '../../repositories/module3_repository.dart';
import '../../widgets/navigation/navigation_logout.dart';
import '../../widgets/navigation/user_sidebar.dart';

class ItineraryPlannerPage extends StatefulWidget {
  const ItineraryPlannerPage({super.key});
  static const routeName = '/itinerary-planner';
  @override
  State<ItineraryPlannerPage> createState() => _ItineraryPlannerPageState();
}

class _ItineraryPlannerPageState extends State<ItineraryPlannerPage> {
  final _repository = Module3Repository();
  final _title = TextEditingController(text: 'My Kuala Lumpur Day');
  late Future<List<TourBooking>> _bookings;
  final _selectedIds = <String>{};
  bool _saving = false;
  bool _routing = false;
  String? _editingId;
  ItineraryPlan? _roadPlan;
  List<SavedItinerary>? _saved;
  bool _savedError = false;

  Future<void> _loadSaved() async {
    if (mounted) setState(() { _saved = null; _savedError = false; });
    try {
      final rows = await _repository.fetchItineraries();
      if (mounted) setState(() => _saved = rows);
    } catch (_) {
      if (mounted) setState(() => _savedError = true);
    }
  }
  final _router = ItineraryRoutingService();

  Future<void> _calculate(ItineraryPlan plan) async {
    setState(() => _routing = true);
    try {
      final routed = await _router.calculate(plan);
      if (mounted) setState(() => _roadPlan = routed);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TourFlowText('Driving route unavailable. Approximate travel times are still shown.')));
    } finally { if (mounted) setState(() => _routing = false); }
  }

  void _edit(SavedItinerary? itinerary, List<TourBooking> available) {
    final valid = available.map((b) => b.id).toSet();
    final ids = itinerary?.bookingIds ?? <String>[];
    setState(() {
      _editingId = itinerary?.id;
      _title.text = itinerary?.title ?? 'My Kuala Lumpur Day';
      _selectedIds..clear()..addAll(ids.where(valid.contains));
      _roadPlan = null;
    });
    if (ids.any((id) => !valid.contains(id))) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: TourFlowText('Some visits are no longer upcoming. Review the remaining bookings before saving.')));
  }

  Future<void> _delete(SavedItinerary itinerary) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const TourFlowText('Delete itinerary?'),
      content: const TourFlowText('Your bookings will remain available in Trips.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const TourFlowText('Keep')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const TourFlowText('Delete'))]));
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _repository.deleteItinerary(itinerary.id);
      if (mounted) {
        setState(() {
          if (_editingId == itinerary.id) {
            _editingId = null; _selectedIds.clear(); _roadPlan = null;
          }
        });
        await _loadSaved();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TourFlowText('Could not delete the itinerary. Please retry.')));
    } finally { if (mounted) setState(() => _saving = false); }
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

  Future<void> _save(ItineraryPlan plan) async {
    if (_title.text.trim().length < 2 || _title.text.trim().length > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TourFlowText('Enter an itinerary name.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await _repository.saveItinerary(title: _title.text, plan: plan, itineraryId: _editingId);
      if (mounted) {
        setState(() => _editingId = id);
        await _loadSaved();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TourFlowText('Itinerary saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TourFlowText(error.toString().contains('ITINERARY_BOOKING_UNAVAILABLE')
            ? 'A visit changed or is closed. Refresh your bookings before saving.'
            : 'Could not save itinerary. Check your connection and selected visits, then retry.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
    appBar: AppBar(title: const TourFlowText('Itinerary Planner'), actions: [
      IconButton(onPressed: _saving || _routing ? null : () {
        setState(() { _bookings = _repository.fetchBookings(); _roadPlan = null; });
        _loadSaved();
      }, icon: const Icon(Icons.refresh), tooltip: 'Refresh')]),
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
        final available = (snapshot.data ?? const [])
            .where((booking) => booking.isUpcoming)
            .toList();
        final selected = available.where(
          (booking) => _selectedIds.contains(booking.id),
        );
        final plan = _roadPlan ?? ItineraryPlan.build(selected);
        final sameDay = plan.bookings.map((b) => shortDate(b.slot.startsAt)).toSet().length <= 1;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [const Expanded(child: TourFlowText('Saved itineraries', style: TextStyle(fontWeight: FontWeight.bold))),
              TextButton.icon(onPressed: _saving || _routing ? null : () => _edit(null, available),
                icon: const Icon(Icons.add), label: const TourFlowText('New'))]),
            if (_savedError) const TourFlowText('Could not load saved plans. Tap Refresh to retry.')
            else if (_saved == null) const LinearProgressIndicator()
            else if (_saved!.isEmpty) const TourFlowText('Your saved plans will appear here.')
            else ..._saved!.map((saved) => Card(child: ListTile(
              title: TourFlowText(saved.title),
              subtitle: TourFlowText('${shortDate(saved.date)} · ${saved.bookingIds.length} visits'),
              selected: saved.id == _editingId,
              onTap: _saving || _routing ? null : () => _edit(saved, available),
              trailing: IconButton(onPressed: _saving || _routing ? null : () => _delete(saved),
                icon: const Icon(Icons.delete_outline), tooltip: 'Delete itinerary')))),
            const SizedBox(height: 16),
            TextField(
              enabled: !_saving && !_routing, maxLength: 120,
              controller: _title,
              decoration: InputDecoration(
                labelText: context.tr('Itinerary name'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
            ...available.map(
              (booking) => Card(
                color: Colors.white,
                child: CheckboxListTile(
                  value: _selectedIds.contains(booking.id),
                  onChanged: _saving || _routing ? null : (checked) => setState(() {
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
              ),
            ),
            if (plan.bookings.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (!sameDay) const TourFlowText('Choose visits on the same day, or create separate itineraries.'),
              if (plan.bookings.length > 1) OutlinedButton.icon(
                onPressed: _saving || _routing || !sameDay ? null : () => _calculate(plan),
                icon: const Icon(Icons.directions_car),
                label: TourFlowText(_routing ? 'Calculating…' : 'Calculate driving route')),
              TourFlowText(plan.usesRoadRoutes
                ? 'Driving routes include a 15-minute buffer. Live traffic may change travel time.'
                : 'Travel times are approximate. Calculate a driving route for a better estimate.'),
              _PlanStatus(conflict: plan.hasConflict),
              const SizedBox(height: 8),
              ...List.generate(plan.bookings.length, (index) {
                final booking = plan.bookings[index];
                final leg = index == 0 ? null : plan.legs[index - 1];
                return Column(
                  children: [
                    if (leg != null)
                      ListTile(
                        leading: const Icon(Icons.directions_car_outlined),
                        title: TourFlowText(
                          '${leg.travelMinutes} min including 15-min safety buffer',
                        ),
                        subtitle: leg.distanceKm == 0
                            ? const TourFlowText(
                                'Distance unavailable; conservative travel estimate used',
                              )
                            : TourFlowText(
                                '${leg.distanceKm.toStringAsFixed(1)} km ${plan.usesRoadRoutes ? 'by road' : 'approximate'}',
                              ),
                      ),
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: TourFlowText(
                          clockTime(booking.slot.startsAt),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        title: TourFlowText(booking.slot.attractionName),
                        subtitle: TourFlowText(slotTime(booking.slot)),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving || _routing || !sameDay ? null : () => _save(plan),
                icon: const Icon(Icons.save_outlined),
                label: TourFlowText(_saving ? 'Saving…' : _editingId == null ? 'Save Itinerary' : 'Update Itinerary'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
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
      subtitle: TourFlowText(
        conflict
            ? 'There is insufficient time between at least two visits.'
            : 'Visits are ordered by time with travel and safety buffers.',
      ),
    ),
  );
}
