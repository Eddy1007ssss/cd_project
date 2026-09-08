import 'package:flutter/material.dart';
import '../../repositories/management_repository.dart';
import 'management_ui.dart';

class AttractionConfigurationPage extends StatefulWidget {
  const AttractionConfigurationPage({super.key, this.attraction});
  static const routeName = '/attraction-configuration';
  final ManagementRow? attraction;
  @override
  State<AttractionConfigurationPage> createState() =>
      _AttractionConfigurationPageState();
}

class _AttractionConfigurationPageState
    extends State<AttractionConfigurationPage> {
  static const _labels = {
    'name': 'Attraction name',
    'description': 'Description',
    'category': 'Category',
    'location_name': 'Location name',
    'address': 'Address',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
    'entrance_price_myr': 'Entrance price (RM)',
    'maximum_capacity': 'Maximum visitors',
    'geofence_radius_m': 'Geofence radius (25–2000 m)',
    'facilities': 'Facilities (comma-separated)',
    'visitor_guidelines': 'Visitor guidelines',
    'attraction_rules': 'Attraction rules',
  };
  final _repository = ManagementRepository();
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in _labels.keys) key: TextEditingController(),
  };
  final _opens = List.generate(7, (_) => TextEditingController(text: '09:00'));
  final _closes = List.generate(7, (_) => TextEditingController(text: '17:00'));
  final _closed = List.filled(7, false);
  List<ManagementRow> _organizations = [];
  List<ManagementRow> _images = [];
  String? _orgId;
  String? _id;
  String _type = 'indoor';
  String _status = 'draft';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool get _editable =>
      const ['draft', 'rejected', 'approved'].contains(_status);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [..._fields.values, ..._opens, ..._closes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row = widget.attraction ?? <String, dynamic>{};
      final orgs = await _repository.organizations();
      final id = row['id'] as String?;
      final hours = id == null
          ? <ManagementRow>[]
          : await _repository.hours(id);
      final images = id == null
          ? <ManagementRow>[]
          : await _repository.images(id);
      if (!mounted) return;
      for (final e in _fields.entries) {
        final value = row[e.key];
        e.value.text = value is List ? value.join(', ') : '${value ?? ''}';
      }
      if (id == null) {
        _fields['entrance_price_myr']!.text = '0';
        _fields['maximum_capacity']!.text = '100';
        _fields['geofence_radius_m']!.text = '200';
      }
      for (final h in hours) {
        final day = h['day_of_week'] as int;
        _closed[day] = h['is_closed'] as bool;
        _opens[day].text = '${h['opens_at'] ?? '09:00'}'.substring(0, 5);
        _closes[day].text = '${h['closes_at'] ?? '17:00'}'.substring(0, 5);
      }
      setState(() {
        _organizations = orgs;
        _id = id;
        _images = images;
        _orgId =
            row['organization_id'] as String? ??
            (orgs.isEmpty ? null : orgs.first['id'] as String);
        _type = row['attraction_type'] as String? ?? 'indoor';
        _status = row['listing_status'] as String? ?? 'draft';
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = managementError(error);
        });
      }
    }
  }

  Future<void> _save(String status) async {
    if (!_form.currentState!.validate()) return;
    if (_orgId == null) {
      managementMessage(
        context,
        'An approved operator organization is required.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final values = <String, dynamic>{
        for (final e in _fields.entries) e.key: e.value.text.trim(),
      };
      values.addAll({
        'id': _id,
        'organization_id': _orgId,
        'attraction_type': _type,
        'listing_status': status,
        'facilities': _fields['facilities']!.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      });
      final hours = List.generate(
        7,
        (day) => <String, dynamic>{
          'day_of_week': day,
          'is_closed': _closed[day],
          'opens_at': _closed[day] ? null : _opens[day].text.trim(),
          'closes_at': _closed[day] ? null : _closes[day].text.trim(),
        },
      );
      final id = await _repository.saveAttraction(values, hours);
      if (mounted) {
        setState(() {
          _id = id;
          _status = _status == 'approved' ? 'pending' : status;
        });
        managementMessage(context, 'Attraction and hours saved ($_status).');
      }
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final path = await pickManagementImage(
        _repository,
        bucket: 'attraction-images',
        folder: _orgId!,
      );
      if (path == null) return;
      await _repository.addAttractionImage(_id!, path, _images.length);
      final images = await _repository.images(_id!);
      if (mounted) setState(() => _images = images);
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validate(String key, String? input) {
    final text = (input ?? '').trim();
    if (const [
      'facilities',
      'visitor_guidelines',
      'attraction_rules',
    ].contains(key)) {
      return null;
    }
    if (text.isEmpty) return 'Required';
    if (const [
      'latitude',
      'longitude',
      'entrance_price_myr',
      'maximum_capacity',
      'geofence_radius_m',
    ].contains(key)) {
      final number = double.tryParse(text);
      if (number == null || !number.isFinite) return 'Enter a valid number';
      if (key == 'latitude' && (number < -90 || number > 90)) {
        return 'Use −90 to 90';
      }
      if (key == 'longitude' && (number < -180 || number > 180)) {
        return 'Use −180 to 180';
      }
      if (key == 'entrance_price_myr' && number < 0) {
        return 'Must be zero or greater';
      }
      if (key == 'maximum_capacity' &&
          (int.tryParse(text) == null || number < 1)) {
        return 'Enter a positive whole number';
      }
      if (key == 'geofence_radius_m' &&
          (int.tryParse(text) == null || number < 25 || number > 2000)) {
        return 'Use a whole number from 25 to 2000';
      }
    }
    if (key == 'name' && (text.length < 2 || text.length > 160)) {
      return 'Use 2–160 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Attraction Configuration')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Status: $_status. Approved edits require a new review.'),
                if (!_editable)
                  const Text(
                    'This listing is read-only until its review or suspension is resolved.',
                  ),
                AbsorbPointer(
                  absorbing: _busy || !_editable,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _orgId,
                        decoration: const InputDecoration(
                          labelText: 'Organization',
                        ),
                        items: _organizations
                            .map(
                              (o) => DropdownMenuItem(
                                value: o['id'] as String,
                                child: Text(o['name'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: _id == null
                            ? (value) => setState(() => _orgId = value)
                            : null,
                      ),
                      for (final e in _labels.entries)
                        managementField(
                          e.value,
                          _fields[e.key]!,
                          validator: (value) => _validate(e.key, value),
                          lines: e.key == 'description' ? 3 : 1,
                        ),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Attraction type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'indoor',
                            child: Text('Indoor — staff QR scan'),
                          ),
                          DropdownMenuItem(
                            value: 'outdoor',
                            child: Text('Outdoor — GPS with staff QR fallback'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _type = value!),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Operating hours (local attraction time, HH:mm)',
                      ),
                      for (var day = 0; day < 7; day++)
                        Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                const [
                                  'Sunday',
                                  'Monday',
                                  'Tuesday',
                                  'Wednesday',
                                  'Thursday',
                                  'Friday',
                                  'Saturday',
                                ][day],
                              ),
                              subtitle: const Text('Closed all day'),
                              value: _closed[day],
                              onChanged: (value) =>
                                  setState(() => _closed[day] = value),
                            ),
                            if (!_closed[day])
                              Row(
                                children: [
                                  Expanded(
                                    child: managementField(
                                      'Opens',
                                      _opens[day],
                                      validator: (value) =>
                                          RegExp(
                                            r'^([01]\d|2[0-3]):[0-5]\d$',
                                          ).hasMatch(value ?? '')
                                          ? null
                                          : 'HH:mm',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: managementField(
                                      'Closes',
                                      _closes[day],
                                      validator: (value) {
                                        if (!RegExp(
                                          r'^([01]\d|2[0-3]):[0-5]\d$',
                                        ).hasMatch(value ?? '')) {
                                          return 'HH:mm';
                                        }
                                        return value!.compareTo(
                                                  _opens[day].text,
                                                ) <=
                                                0
                                            ? 'Must be after opening'
                                            : null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                for (final image in _images)
                  Image.network(
                    _repository.imageUrl(image['storage_path'] as String),
                    height: 120,
                    errorBuilder: (_, _, _) => const Text('Image unavailable'),
                  ),
                if (_id != null &&
                    const ['draft', 'rejected'].contains(_status))
                  TextButton(
                    onPressed: _busy ? null : _upload,
                    child: const Text('Add Gallery Image'),
                  ),
                if (_id == null)
                  const Text(
                    'Save a draft first to upload gallery images, then submit for review.',
                  ),
                if (_editable)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_status != 'approved')
                        OutlinedButton(
                          onPressed: _busy ? null : () => _save('draft'),
                          child: const Text('Save Draft'),
                        ),
                      FilledButton(
                        onPressed: _busy ? null : () => _save('pending'),
                        child: const Text('Submit for Review'),
                      ),
                    ],
                  ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
  );
}
