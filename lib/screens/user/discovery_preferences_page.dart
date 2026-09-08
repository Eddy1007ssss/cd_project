import 'package:flutter/material.dart';

import '../../models/preference_profile.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';

class DiscoveryPreferencesPage
    extends StatefulWidget {
  const DiscoveryPreferencesPage({
    super.key,
  });

  static const routeName =
      '/discovery-preferences';

  @override
  State<DiscoveryPreferencesPage>
  createState() =>
      _DiscoveryPreferencesPageState();
}

class _DiscoveryPreferencesPageState
    extends State<DiscoveryPreferencesPage> {
  final _service = AttractionService();

  final _minBudget =
  TextEditingController();

  final _maxBudget =
  TextEditingController();

  final _radius =
  TextEditingController();

  final _interests = <String>{};
  final _facilities = <String>{};
  final _accessibilityNeeds =
  <String>{};

  PreferenceProfile? _profile;

  bool _loading = true;
  bool _saving = false;

  String _crowd = 'moderate';
  String _environment = 'both';
  String _travellingType = 'solo';

  String? _error;

  static const double _minimumRadiusKm = 1;
  static const double _maximumRadiusKm = 50;

  // ==============================================================
  // OPTIONS
  // ==============================================================

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

  static const accessibilityOptions = [
    'Wheelchair access',
    'Accessible restroom',
    'Lift / elevator',
    'Step-free access',
  ];

  // ==============================================================
  // INIT
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _minBudget.dispose();
    _maxBudget.dispose();
    _radius.dispose();

    super.dispose();
  }

  // ==============================================================
  // LOAD
  // ==============================================================

  Future<void> _load() async {
    try {
      final origin =
      await LocationService()
          .currentLocation();

      final profile =
      await _service.getPreferences(
        defaultOrigin: origin,
      );

      _profile = profile;

      _minBudget.text =
          profile.minBudgetMyr
              .toStringAsFixed(
            0,
          );

      _maxBudget.text =
          profile.maxBudgetMyr
              ?.toStringAsFixed(
            0,
          ) ??
              '';

      // Old accounts may have radius above 50 km.
      // Display a valid value under the new rule.
      final radius =
      profile.travelRadiusKm
          .clamp(
        _minimumRadiusKm,
        _maximumRadiusKm,
      )
          .toDouble();

      _radius.text =
          radius.toStringAsFixed(
            0,
          );

      _interests
        ..clear()
        ..addAll(
          profile.interests,
        );

      _facilities
        ..clear()
        ..addAll(
          profile.requiredFacilities,
        );

      _accessibilityNeeds
        ..clear()
        ..addAll(
          profile.accessibilityNeeds,
        );

      _crowd =
          profile.preferredCrowdLevel;

      _environment =
          profile.environmentPreference;

      _travellingType =
          profile.travellingType;
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==============================================================
  // SAVE
  // ==============================================================

  Future<void> _save() async {
    if (_profile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load your preference profile.',
          ),
        ),
      );

      return;
    }

    final minBudget =
    double.tryParse(
      _minBudget.text.trim(),
    );

    final maxBudget =
    _maxBudget.text.trim().isEmpty
        ? null
        : double.tryParse(
      _maxBudget.text.trim(),
    );

    final radius =
    double.tryParse(
      _radius.text.trim(),
    );

    // ============================================================
    // MIN BUDGET VALIDATION
    // ============================================================

    if (minBudget == null ||
        minBudget < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid minimum budget.',
          ),
        ),
      );

      return;
    }

    // ============================================================
    // MAX BUDGET VALIDATION
    // ============================================================

    if (maxBudget != null &&
        (maxBudget < 0 ||
            maxBudget < minBudget)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum budget must be greater than or equal to minimum budget.',
          ),
        ),
      );

      return;
    }

    // ============================================================
    // RADIUS VALIDATION
    // ============================================================

    if (radius == null ||
        radius < _minimumRadiusKm ||
        radius > _maximumRadiusKm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Travel radius must be between 1 and 50 km.',
          ),
        ),
      );

      return;
    }

    // ============================================================
    // INTEREST VALIDATION
    // ============================================================

    if (_interests.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one interest.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final updatedProfile =
      PreferenceProfile(
        touristId:
        _profile!.touristId,

        interests:
        _interests.toList()
          ..sort(),

        minBudgetMyr:
        minBudget,

        maxBudgetMyr:
        maxBudget,

        preferredLocation:
        _profile!
            .preferredLocation,

        preferredLatitude:
        _profile!
            .preferredLatitude,

        preferredLongitude:
        _profile!
            .preferredLongitude,

        travelRadiusKm:
        radius,

        preferredCrowdLevel:
        _crowd,

        preferredVisitStart:
        _profile!
            .preferredVisitStart,

        preferredVisitEnd:
        _profile!
            .preferredVisitEnd,

        requiredFacilities:
        _facilities.toList()
          ..sort(),

        accessibilityNeeds:
        _accessibilityNeeds
            .toList()
          ..sort(),

        environmentPreference:
        _environment,

        travellingType:
        _travellingType,
      );

      await _service
          .savePreferences(
        updatedProfile,
      );

      _profile =
          updatedProfile;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Discovery preferences saved successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Could not save preferences: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ==============================================================
  // SECTION TITLE
  // ==============================================================

  Widget _sectionTitle(
      String title,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),
      child: Text(
        title,
        style:
        const TextStyle(
          fontSize: 17,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }

  // ==============================================================
  // PAGE
  // ==============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discovery Preferences',
        ),
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets
              .all(
            24,
          ),
          child: Text(
            'Sign in with a tourist account before '
                'saving preferences.\n\n$_error',
            textAlign:
            TextAlign.center,
          ),
        ),
      )
          : ListView(
        padding:
        const EdgeInsets
            .all(
          16,
        ),
        children: [
          // =============================================
          // DEMO MODE
          // =============================================

          if (_service
              .isDemoMode)
            const Card(
              color: Color(
                0xFFFFE7C2,
              ),
              child: ListTile(
                leading: Icon(
                  Icons
                      .science_outlined,
                ),
                title: Text(
                  'Demo preferences',
                ),
                subtitle: Text(
                  'Changes are kept for this app session only.',
                ),
              ),
            ),

          // =============================================
          // INTERESTS
          // =============================================

          _sectionTitle(
            'Interests',
          ),

          const Text(
            'Select the types of attractions you are interested in.',
          ),

          const SizedBox(
            height: 8,
          ),

          Wrap(
            spacing: 7,
            runSpacing: 4,
            children:
            interestOptions
                .map(
                  (value) {
                return FilterChip(
                  label: Text(
                    _capitalize(
                      value,
                    ),
                  ),
                  selected:
                  _interests
                      .contains(
                    value,
                  ),
                  onSelected:
                      (selected) {
                    setState(() {
                      if (selected) {
                        _interests
                            .add(
                          value,
                        );
                      } else {
                        _interests
                            .remove(
                          value,
                        );
                      }
                    });
                  },
                );
              },
            ).toList(),
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // BUDGET
          // =============================================

          _sectionTitle(
            'Budget Range',
          ),

          Row(
            children: [
              Expanded(
                child:
                TextField(
                  controller:
                  _minBudget,
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Minimum (RM)',
                    prefixText:
                    'RM ',
                    border:
                    OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                TextField(
                  controller:
                  _maxBudget,
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                  const InputDecoration(
                    labelText:
                    'Maximum (RM)',
                    prefixText:
                    'RM ',
                    hintText:
                    'Any',
                    border:
                    OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // TRAVEL DISTANCE
          // =============================================

          _sectionTitle(
            'Preferred Travel Distance',
          ),

          const Text(
            'Set how far you normally want to travel '
                'for nearby attractions.',
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller:
            _radius,
            keyboardType:
            const TextInputType
                .numberWithOptions(
              decimal: true,
            ),
            decoration:
            const InputDecoration(
              labelText:
              'Travel radius (km)',
              hintText:
              '1 - 50',
              helperText:
              'Nearby search supports a maximum of 50 km.',
              suffixText: 'km',
              border:
              OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // CROWD
          // =============================================

          _sectionTitle(
            'Crowd Preference',
          ),

          DropdownButtonFormField<
              String>(
            initialValue:
            _crowd,
            decoration:
            const InputDecoration(
              labelText:
              'Preferred crowd level',
              border:
              OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'low',
                child:
                Text('Low'),
              ),
              DropdownMenuItem(
                value:
                'moderate',
                child: Text(
                  'Moderate',
                ),
              ),
              DropdownMenuItem(
                value: 'high',
                child:
                Text('High'),
              ),
              DropdownMenuItem(
                value:
                'critical',
                child: Text(
                  'Critical',
                ),
              ),
            ],
            onChanged: (value) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                _crowd = value;
              });
            },
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // ENVIRONMENT
          // =============================================

          _sectionTitle(
            'Environment Preference',
          ),

          DropdownButtonFormField<
              String>(
            initialValue:
            _environment,
            decoration:
            const InputDecoration(
              labelText:
              'Indoor / Outdoor Preference',
              border:
              OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value:
                'indoor',
                child: Text(
                  'Indoor',
                ),
              ),
              DropdownMenuItem(
                value:
                'outdoor',
                child: Text(
                  'Outdoor',
                ),
              ),
              DropdownMenuItem(
                value: 'both',
                child:
                Text('Both'),
              ),
            ],
            onChanged: (value) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                _environment =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // TRAVELLING TYPE
          // =============================================

          _sectionTitle(
            'Travelling Type',
          ),

          DropdownButtonFormField<
              String>(
            initialValue:
            _travellingType,
            decoration:
            const InputDecoration(
              labelText:
              'Who are you travelling with?',
              border:
              OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'solo',
                child:
                Text('Solo'),
              ),
              DropdownMenuItem(
                value:
                'family',
                child:
                Text('Family'),
              ),
              DropdownMenuItem(
                value:
                'group',
                child:
                Text('Group'),
              ),
            ],
            onChanged: (value) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                _travellingType =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // ACCESSIBILITY
          // =============================================

          _sectionTitle(
            'Accessibility Needs',
          ),

          const Text(
            'Select any accessibility facilities you require.',
          ),

          const SizedBox(
            height: 8,
          ),

          Wrap(
            spacing: 7,
            runSpacing: 4,
            children:
            accessibilityOptions
                .map(
                  (value) {
                return FilterChip(
                  label:
                  Text(value),
                  selected:
                  _accessibilityNeeds
                      .contains(
                    value,
                  ),
                  onSelected:
                      (selected) {
                    setState(() {
                      if (selected) {
                        _accessibilityNeeds
                            .add(
                          value,
                        );
                      } else {
                        _accessibilityNeeds
                            .remove(
                          value,
                        );
                      }
                    });
                  },
                );
              },
            ).toList(),
          ),

          const SizedBox(
            height: 18,
          ),

          // =============================================
          // FACILITIES
          // =============================================

          _sectionTitle(
            'Required Facilities',
          ),

          Wrap(
            spacing: 7,
            runSpacing: 4,
            children:
            facilityOptions
                .map(
                  (value) {
                return FilterChip(
                  label:
                  Text(value),
                  selected:
                  _facilities
                      .contains(
                    value,
                  ),
                  onSelected:
                      (selected) {
                    setState(() {
                      if (selected) {
                        _facilities
                            .add(
                          value,
                        );
                      } else {
                        _facilities
                            .remove(
                          value,
                        );
                      }
                    });
                  },
                );
              },
            ).toList(),
          ),

          const SizedBox(
            height: 28,
          ),

          // =============================================
          // SAVE
          // =============================================

          FilledButton.icon(
            onPressed:
            _saving
                ? null
                : _save,
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth:
                2,
              ),
            )
                : const Icon(
              Icons
                  .save_outlined,
            ),
            label: Text(
              _saving
                  ? 'Saving...'
                  : 'Save Preferences',
            ),
            style:
            FilledButton
                .styleFrom(
              padding:
              const EdgeInsets
                  .all(
                16,
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // CAPITALIZE
  // ==============================================================

  static String _capitalize(
      String value,
      ) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}'
        '${value.substring(1)}';
  }
}