import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import '../../widgets/navigation/user_bottom_navigation_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _bookings = _repository.fetchBookings();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save(ItineraryPlan plan) async {
    if (_title.text.trim().length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an itinerary name.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.saveItinerary(title: _title.text, plan: plan);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Itinerary saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save itinerary: $error')),
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
    appBar: AppBar(title: const Text('Itinerary Planner')),
    body: FutureBuilder<List<TourBooking>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load confirmed bookings.'),
          );
        }
        final available = (snapshot.data ?? const [])
            .where((booking) => booking.isUpcoming)
            .toList();
        final selected = available.where(
          (booking) => _selectedIds.contains(booking.id),
        );
        final plan = ItineraryPlan.build(selected);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Itinerary name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose confirmed bookings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (available.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Create an upcoming booking before building an itinerary.',
                  ),
                ),
              ),
            ...available.map(
              (booking) => Card(
                color: Colors.white,
                child: CheckboxListTile(
                  value: _selectedIds.contains(booking.id),
                  onChanged: (checked) => setState(() {
                    checked == true
                        ? _selectedIds.add(booking.id)
                        : _selectedIds.remove(booking.id);
                  }),
                  title: Text(
                    booking.slot.attractionName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${shortDate(booking.slot.startsAt)} · ${slotTime(booking.slot)}',
                  ),
                ),
              ),
            ),
            if (plan.bookings.isNotEmpty) ...[
              const SizedBox(height: 14),
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
                        title: Text(
                          '${leg.travelMinutes} min including 15-min safety buffer',
                        ),
                        subtitle: leg.distanceKm == 0
                            ? const Text(
                                'Distance unavailable; conservative travel estimate used',
                              )
                            : Text(
                                '${leg.distanceKm.toStringAsFixed(1)} km estimated',
                              ),
                      ),
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: Text(
                          clockTime(booking.slot.startsAt),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        title: Text(booking.slot.attractionName),
                        subtitle: Text(slotTime(booking.slot)),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(plan),
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save Itinerary'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ],
          ],
        );
      },
    ),
    bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
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
      title: Text(
        conflict ? 'Conflict Detected' : 'Conflict-Free',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        conflict
            ? 'There is insufficient time between at least two visits.'
            : 'Visits are ordered by time with travel and safety buffers.',
      ),
    ),
  );
}
