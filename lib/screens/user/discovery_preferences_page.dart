import 'package:flutter/material.dart';

import '../../models/preference_profile.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';

class DiscoveryPreferencesPage extends StatefulWidget {
  const DiscoveryPreferencesPage({super.key});
  static const routeName = '/discovery-preferences';
  @override
  State<DiscoveryPreferencesPage> createState() =>
      _DiscoveryPreferencesPageState();
}

class _DiscoveryPreferencesPageState extends State<DiscoveryPreferencesPage> {
  final _service = AttractionService();
  final _budget = TextEditingController();
  final _radius = TextEditingController();
  final _interests = <String>{};
  final _facilities = <String>{};
  PreferenceProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String _crowd = 'moderate';
  String? _error;

  static const interestOptions = [
    'history',
    'nature',
    'culture',
    'family',
    'photography',
    'art',
    'food',
  ];
  static const facilityOptions = [
    'Restrooms',
    'Wheelchair access',
    'Prayer room',
    'Cafe',
    'Parking',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _budget.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final origin = await LocationService().currentLocation();
      final profile = await _service.getPreferences(defaultOrigin: origin);
      _profile = profile;
      _budget.text = profile.maxBudgetMyr?.toStringAsFixed(0) ?? '';
      _radius.text = profile.travelRadiusKm.toStringAsFixed(0);
      _interests.addAll(profile.interests);
      _facilities.addAll(profile.requiredFacilities);
      _crowd = profile.preferredCrowdLevel;
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final budget = _budget.text.trim().isEmpty
        ? null
        : double.tryParse(_budget.text.trim());
    final radius = double.tryParse(_radius.text.trim());
    if (radius == null ||
        radius <= 0 ||
        radius > 200 ||
        (budget != null && budget < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid budget and travel radius between 1 and 200 km.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.savePreferences(
        PreferenceProfile(
          touristId: _profile!.touristId,
          interests: _interests.toList()..sort(),
          maxBudgetMyr: budget,
          preferredLocation: _profile!.preferredLocation,
          preferredLatitude: _profile!.preferredLatitude,
          preferredLongitude: _profile!.preferredLongitude,
          travelRadiusKm: radius,
          preferredCrowdLevel: _crowd,
          preferredVisitStart: _profile!.preferredVisitStart,
          preferredVisitEnd: _profile!.preferredVisitEnd,
          requiredFacilities: _facilities.toList()..sort(),
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discovery preferences saved.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preferences: $error')),
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
    appBar: AppBar(title: const Text('Discovery Preferences')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sign in with the shared Module 1 tourist account before saving preferences.\n\n$_error',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_service.isDemoMode)
                const Card(
                  color: Color(0xFFFFE7C2),
                  child: ListTile(
                    leading: Icon(Icons.science_outlined),
                    title: Text('Demo preferences'),
                    subtitle: Text(
                      'Changes are kept for this app session only.',
                    ),
                  ),
                ),
              const Text(
                'Interests',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Wrap(
                spacing: 7,
                children: interestOptions
                    .map(
                      (value) => FilterChip(
                        label: Text(value),
                        selected: _interests.contains(value),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _interests.add(value)
                              : _interests.remove(value),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum budget (RM)',
                  hintText: 'Leave blank for any budget',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _radius,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Travel radius (km)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _crowd,
                decoration: const InputDecoration(
                  labelText: 'Preferred crowd level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (value) => setState(() => _crowd = value!),
              ),
              const SizedBox(height: 18),
              const Text(
                'Required facilities',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Wrap(
                spacing: 7,
                children: facilityOptions
                    .map(
                      (value) => FilterChip(
                        label: Text(value),
                        selected: _facilities.contains(value),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _facilities.add(value)
                              : _facilities.remove(value),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save Preferences'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ],
          ),
  );
}
