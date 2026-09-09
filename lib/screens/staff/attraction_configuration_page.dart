import 'package:flutter/material.dart';

import '../../repositories/management_repository.dart';
import 'management_ui.dart';

class AttractionConfigurationPage extends StatefulWidget {
  const AttractionConfigurationPage({
    super.key,
    this.attraction,
  });

  static const routeName = '/attraction-configuration';

  final ManagementRow? attraction;

  @override
  State<AttractionConfigurationPage> createState() =>
      _AttractionConfigurationPageState();
}

class _AttractionConfigurationPageState
    extends State<AttractionConfigurationPage> {
  // ============================================================
  // NORMAL FORM FIELDS
  // ============================================================

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

  // ============================================================
  // CATEGORY OPTIONS
  // ============================================================

  static const List<String> _categoryOptions = [
    'history',
    'nature',
    'culture',
    'family',
    'photography',
    'art',
    'food',
    'entertainment',
    'adventure',
    'shopping',
    'education',
    'religious',
    'beach',
    'park & recreation',
    'museum',
    'heritage',
    'science & technology',
    'wildlife',
    'theme park',
    'sports',
  ];

  // ============================================================
  // SERVICES / CONTROLLERS
  // ============================================================

  final _repository = ManagementRepository();

  final _form = GlobalKey<FormState>();

  final _fields = {
    for (final key in _labels.keys)
      key: TextEditingController(),
  };

  final _otherCategoryController =
  TextEditingController();

  final _opens = List.generate(
    7,
        (_) => TextEditingController(
      text: '09:00',
    ),
  );

  final _closes = List.generate(
    7,
        (_) => TextEditingController(
      text: '17:00',
    ),
  );

  final _closed = List.filled(
    7,
    false,
  );

  // ============================================================
  // PAGE STATE
  // ============================================================

  List<ManagementRow> _organizations = [];

  List<ManagementRow> _images = [];

  String? _orgId;

  String? _id;

  String? _selectedCategory;

  String _type = 'indoor';

  String _status = 'draft';

  bool _loading = true;

  bool _busy = false;

  String? _error;

  bool get _editable =>
      const [
        'draft',
        'rejected',
        'approved',
      ].contains(_status);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _load();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    for (final controller in [
      ..._fields.values,
      ..._opens,
      ..._closes,
    ]) {
      controller.dispose();
    }

    _otherCategoryController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD ATTRACTION
  // ============================================================

  Future<void> _load() async {
    try {
      final row =
          widget.attraction ??
              <String, dynamic>{};

      final orgs =
      await _repository.organizations();

      final id =
      row['id'] as String?;

      final hours =
      id == null
          ? <ManagementRow>[]
          : await _repository.hours(id);

      final images =
      id == null
          ? <ManagementRow>[]
          : await _repository.images(id);

      if (!mounted) {
        return;
      }

      // ========================================================
      // LOAD NORMAL FIELD VALUES
      // ========================================================

      for (final entry in _fields.entries) {
        final value =
        row[entry.key];

        entry.value.text =
        value is List
            ? value.join(', ')
            : '${value ?? ''}';
      }

      // ========================================================
      // CATEGORY
      // ========================================================

      final existingCategory =
      '${row['category'] ?? ''}'
          .trim();

      final normalizedCategory =
      existingCategory.toLowerCase();

      final isStandardCategory =
      _categoryOptions.contains(
        normalizedCategory,
      );

      if (existingCategory.isEmpty) {
        _selectedCategory = null;

        _otherCategoryController.clear();
      } else if (isStandardCategory) {
        _selectedCategory =
            normalizedCategory;

        _otherCategoryController.clear();

        _fields['category']!.text =
            normalizedCategory;
      } else {
        // Existing categories which are not part
        // of our standard list automatically use Other.
        _selectedCategory = 'other';

        _otherCategoryController.text =
            existingCategory;

        _fields['category']!.text =
            existingCategory;
      }

      // ========================================================
      // DEFAULT VALUES FOR NEW ATTRACTION
      // ========================================================

      if (id == null) {
        _fields['entrance_price_myr']!
            .text = '0';

        _fields['maximum_capacity']!
            .text = '100';

        _fields['geofence_radius_m']!
            .text = '200';
      }

      // ========================================================
      // OPERATING HOURS
      // ========================================================

      for (final hour in hours) {
        final day =
        hour['day_of_week'] as int;

        _closed[day] =
        hour['is_closed'] as bool;

        _opens[day].text =
            '${hour['opens_at'] ?? '09:00'}'
                .substring(
              0,
              5,
            );

        _closes[day].text =
            '${hour['closes_at'] ?? '17:00'}'
                .substring(
              0,
              5,
            );
      }

      setState(() {
        _organizations = orgs;

        _id = id;

        _images = images;

        _orgId =
            row['organization_id']
            as String? ??
                (
                    orgs.isEmpty
                        ? null
                        : orgs.first['id']
                    as String
                );

        _type =
            row['attraction_type']
            as String? ??
                'indoor';

        _status =
            row['listing_status']
            as String? ??
                'draft';

        _loading = false;

        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;

          _error =
              managementError(error);
        });
      }
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save(
      String status,
      ) async {
    // ==========================================================
    // PREPARE FINAL CATEGORY
    // ==========================================================

    final finalCategory =
    _selectedCategory == 'other'
        ? _otherCategoryController
        .text
        .trim()
        : (_selectedCategory ?? '');

    // Store final category back into the existing
    // controller because the repository already expects
    // category inside the normal values map.
    _fields['category']!.text =
        finalCategory;

    // ==========================================================
    // VALIDATE FORM
    // ==========================================================

    if (!_form.currentState!.validate()) {
      return;
    }

    if (_orgId == null) {
      managementMessage(
        context,
        'An approved operator organization is required.',
      );

      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      // ========================================================
      // VALUES
      // ========================================================

      final values =
      <String, dynamic>{
        for (final entry
        in _fields.entries)
          entry.key:
          entry.value.text.trim(),
      };

      values.addAll({
        'id': _id,
        'organization_id': _orgId,
        'attraction_type': _type,
        'listing_status': status,

        'facilities':
        _fields['facilities']!
            .text
            .split(',')
            .map(
              (value) =>
              value.trim(),
        )
            .where(
              (value) =>
          value.isNotEmpty,
        )
            .toList(),
      });

      // ========================================================
      // OPERATING HOURS
      // ========================================================

      final hours = List.generate(
        7,
            (day) =>
        <String, dynamic>{
          'day_of_week': day,

          'is_closed':
          _closed[day],

          'opens_at':
          _closed[day]
              ? null
              : _opens[day]
              .text
              .trim(),

          'closes_at':
          _closed[day]
              ? null
              : _closes[day]
              .text
              .trim(),
        },
      );

      // ========================================================
      // SAVE TO REPOSITORY
      // ========================================================

      final id =
      await _repository
          .saveAttraction(
        values,
        hours,
      );

      if (mounted) {
        setState(() {
          _id = id;

          // Editing an approved attraction requires
          // another admin review.
          _status =
          _status == 'approved'
              ? 'pending'
              : status;
        });

        managementMessage(
          context,
          'Attraction and hours saved ($_status).',
        );
      }
    } catch (error) {
      if (mounted) {
        managementMessage(
          context,
          managementError(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<void> _upload() async {
    if (_orgId == null ||
        _id == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final path =
      await pickManagementImage(
        _repository,
        bucket:
        'attraction-images',
        folder:
        _orgId!,
      );

      if (path == null) {
        return;
      }

      await _repository
          .addAttractionImage(
        _id!,
        path,
        _images.length,
      );

      final images =
      await _repository.images(
        _id!,
      );

      if (mounted) {
        setState(() {
          _images = images;
        });
      }
    } catch (error) {
      if (mounted) {
        managementMessage(
          context,
          managementError(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // NORMAL FIELD VALIDATION
  // ============================================================

  String? _validate(
      String key,
      String? input,
      ) {
    final text =
    (input ?? '').trim();

    // Optional fields.
    if (const [
      'facilities',
      'visitor_guidelines',
      'attraction_rules',
    ].contains(key)) {
      return null;
    }

    if (text.isEmpty) {
      return 'Required';
    }

    // ==========================================================
    // NUMBER VALIDATION
    // ==========================================================

    if (const [
      'latitude',
      'longitude',
      'entrance_price_myr',
      'maximum_capacity',
      'geofence_radius_m',
    ].contains(key)) {
      final number =
      double.tryParse(text);

      if (number == null ||
          !number.isFinite) {
        return 'Enter a valid number';
      }

      // Latitude
      if (key == 'latitude' &&
          (
              number < -90 ||
                  number > 90
          )) {
        return 'Use −90 to 90';
      }

      // Longitude
      if (key == 'longitude' &&
          (
              number < -180 ||
                  number > 180
          )) {
        return 'Use −180 to 180';
      }

      // Price
      if (key ==
          'entrance_price_myr' &&
          number < 0) {
        return 'Must be zero or greater';
      }

      // Capacity
      if (key ==
          'maximum_capacity' &&
          (
              int.tryParse(text) ==
                  null ||
                  number < 1
          )) {
        return 'Enter a positive whole number';
      }

      // Geofence
      if (key ==
          'geofence_radius_m' &&
          (
              int.tryParse(text) ==
                  null ||
                  number < 25 ||
                  number > 2000
          )) {
        return 'Use a whole number from 25 to 2000';
      }
    }

    // ==========================================================
    // NAME VALIDATION
    // ==========================================================

    if (key == 'name' &&
        (
            text.length < 2 ||
                text.length > 160
        )) {
      return 'Use 2–160 characters';
    }

    return null;
  }

  // ============================================================
  // CATEGORY LABEL
  // ============================================================

  static String _categoryLabel(
      String value,
      ) {
    return value
        .split(' ')
        .map(
          (word) {
        if (word.isEmpty) {
          return word;
        }

        return '${word[0].toUpperCase()}'
            '${word.substring(1)}';
      },
    )
        .join(' ');
  }

  // ============================================================
  // PAGE
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attraction Configuration',
        ),
      ),

      body:
      _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Text(
              _error!,
            ),

            TextButton(
              onPressed:
              _load,
              child:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      )
          : Form(
        key: _form,

        child: ListView(
          padding:
          const EdgeInsets
              .all(16),

          children: [
            // ==========================================
            // STATUS
            // ==========================================

            Text(
              'Status: $_status. '
                  'Approved edits require a new review.',
            ),

            if (!_editable)
              const Padding(
                padding:
                EdgeInsets
                    .only(
                  top: 6,
                  bottom: 10,
                ),
                child: Text(
                  'This listing is read-only until its '
                      'review or suspension is resolved.',
                ),
              ),

            // ==========================================
            // EDITABLE FORM
            // ==========================================

            AbsorbPointer(
              absorbing:
              _busy ||
                  !_editable,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

                children: [
                  // ====================================
                  // ORGANIZATION
                  // ====================================

                  DropdownButtonFormField<
                      String>(
                    initialValue:
                    _orgId,

                    isExpanded:
                    true,

                    decoration:
                    const InputDecoration(
                      labelText:
                      'Organization',
                      border:
                      OutlineInputBorder(),
                    ),

                    items:
                    _organizations
                        .map(
                          (
                          organization,
                          ) {
                        return DropdownMenuItem<
                            String>(
                          value:
                          organization['id']
                          as String,
                          child:
                          Text(
                            organization['name']
                            as String,
                          ),
                        );
                      },
                    )
                        .toList(),

                    onChanged:
                    _id == null
                        ? (
                        value,
                        ) {
                      setState(
                            () {
                          _orgId =
                              value;
                        },
                      );
                    }
                        : null,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ====================================
                  // NORMAL FORM FIELDS
                  // CATEGORY IS HANDLED SEPARATELY
                  // ====================================

                  for (final entry
                  in _labels
                      .entries)
                    if (entry.key ==
                        'category') ...[
                      // ================================
                      // CATEGORY DROPDOWN
                      // ================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                        _selectedCategory,

                        isExpanded:
                        true,

                        decoration:
                        const InputDecoration(
                          labelText:
                          'Category',
                          hintText:
                          'Select attraction category',
                          border:
                          OutlineInputBorder(),
                        ),

                        items: [
                          for (final category
                          in _categoryOptions)
                            DropdownMenuItem<
                                String>(
                              value:
                              category,
                              child:
                              Text(
                                _categoryLabel(
                                  category,
                                ),
                              ),
                            ),

                          const DropdownMenuItem<
                              String>(
                            value:
                            'other',
                            child:
                            Text(
                              'Other',
                            ),
                          ),
                        ],

                        validator:
                            (
                            value,
                            ) {
                          if (value ==
                              null ||
                              value
                                  .isEmpty) {
                            return 'Please select a category';
                          }

                          return null;
                        },

                        onChanged:
                            (
                            value,
                            ) {
                          setState(
                                () {
                              _selectedCategory =
                                  value;

                              if (value !=
                                  'other') {
                                _otherCategoryController
                                    .clear();

                                _fields['category']!
                                    .text =
                                    value ??
                                        '';
                              } else {
                                _fields['category']!
                                    .clear();
                              }
                            },
                          );
                        },
                      ),

                      // ================================
                      // OTHER CATEGORY
                      // ================================

                      if (_selectedCategory ==
                          'other') ...[
                        const SizedBox(
                          height:
                          12,
                        ),

                        TextFormField(
                          controller:
                          _otherCategoryController,

                          textCapitalization:
                          TextCapitalization
                              .words,

                          decoration:
                          const InputDecoration(
                            labelText:
                            'Other category',
                            hintText:
                            'Enter attraction category',
                            helperText:
                            'Use this only when the attraction category '
                                'is not available above.',
                            border:
                            OutlineInputBorder(),
                          ),

                          validator:
                              (
                              value,
                              ) {
                            if (_selectedCategory !=
                                'other') {
                              return null;
                            }

                            final text =
                            (
                                value ??
                                    ''
                            )
                                .trim();

                            if (text
                                .isEmpty) {
                              return 'Please enter the category';
                            }

                            if (text
                                .length <
                                2) {
                              return 'Enter at least 2 characters';
                            }

                            if (text
                                .length >
                                100) {
                              return 'Use 100 characters or fewer';
                            }

                            return null;
                          },
                        ),
                      ],

                      const SizedBox(
                        height: 12,
                      ),
                    ] else ...[
                      managementField(
                        entry.value,
                        _fields[
                        entry.key]!,

                        validator:
                            (
                            value,
                            ) =>
                            _validate(
                              entry.key,
                              value,
                            ),

                        lines:
                        entry.key ==
                            'description'
                            ? 3
                            : 1,
                      ),
                    ],

                  // ====================================
                  // ATTRACTION TYPE
                  // ====================================

                  DropdownButtonFormField<
                      String>(
                    initialValue:
                    _type,

                    isExpanded:
                    true,

                    decoration:
                    const InputDecoration(
                      labelText:
                      'Attraction type',
                      border:
                      OutlineInputBorder(),
                    ),

                    items:
                    const [
                      DropdownMenuItem<
                          String>(
                        value:
                        'indoor',
                        child:
                        Text(
                          'Indoor — staff QR scan',
                        ),
                      ),

                      DropdownMenuItem<
                          String>(
                        value:
                        'outdoor',
                        child:
                        Text(
                          'Outdoor — GPS with staff QR fallback',
                        ),
                      ),
                    ],

                    onChanged:
                        (
                        value,
                        ) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(
                            () {
                          _type =
                              value;
                        },
                      );
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ====================================
                  // OPERATING HOURS TITLE
                  // ====================================

                  const Align(
                    alignment:
                    Alignment
                        .centerLeft,
                    child: Text(
                      'Operating hours '
                          '(local attraction time, HH:mm)',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ====================================
                  // OPERATING HOURS
                  // ====================================

                  for (var day = 0;
                  day < 7;
                  day++)
                    Column(
                      children: [
                        SwitchListTile(
                          contentPadding:
                          EdgeInsets
                              .zero,

                          title:
                          Text(
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

                          subtitle:
                          const Text(
                            'Closed all day',
                          ),

                          value:
                          _closed[
                          day],

                          onChanged:
                              (
                              value,
                              ) {
                            setState(
                                  () {
                                _closed[
                                day] =
                                    value;
                              },
                            );
                          },
                        ),

                        if (!_closed[
                        day])
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Expanded(
                                child:
                                managementField(
                                  'Opens',
                                  _opens[
                                  day],
                                  validator:
                                      (
                                      value,
                                      ) {
                                    final valid =
                                    RegExp(
                                      r'^([01]\d|2[0-3]):[0-5]\d$',
                                    ).hasMatch(
                                      value ??
                                          '',
                                    );

                                    return valid
                                        ? null
                                        : 'HH:mm';
                                  },
                                ),
                              ),

                              const SizedBox(
                                width:
                                8,
                              ),

                              Expanded(
                                child:
                                managementField(
                                  'Closes',
                                  _closes[
                                  day],
                                  validator:
                                      (
                                      value,
                                      ) {
                                    if (!RegExp(
                                      r'^([01]\d|2[0-3]):[0-5]\d$',
                                    ).hasMatch(
                                      value ??
                                          '',
                                    )) {
                                      return 'HH:mm';
                                    }

                                    return value!
                                        .compareTo(
                                      _opens[
                                      day]
                                          .text,
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

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // IMAGES
            // ==========================================

            for (final image
            in _images)
              Padding(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 10,
                ),
                child:
                ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                  child:
                  Image.network(
                    _repository
                        .imageUrl(
                      image['storage_path']
                      as String,
                    ),
                    height:
                    120,
                    width:
                    double
                        .infinity,
                    fit:
                    BoxFit
                        .cover,
                    errorBuilder:
                        (
                        _,
                        _,
                        _,
                        ) =>
                    const SizedBox(
                      height:
                      120,
                      child:
                      Center(
                        child:
                        Text(
                          'Image unavailable',
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ==========================================
            // ADD IMAGE
            // ==========================================

            if (_id != null &&
                const [
                  'draft',
                  'rejected',
                ].contains(
                  _status,
                ))
              TextButton.icon(
                onPressed:
                _busy
                    ? null
                    : _upload,
                icon:
                const Icon(
                  Icons
                      .add_photo_alternate_outlined,
                ),
                label:
                const Text(
                  'Add Gallery Image',
                ),
              ),

            if (_id == null)
              const Padding(
                padding:
                EdgeInsets
                    .symmetric(
                  vertical: 8,
                ),
                child: Text(
                  'Save a draft first to upload gallery '
                      'images, then submit for review.',
                ),
              ),

            // ==========================================
            // ACTION BUTTONS
            // ==========================================

            if (_editable)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_status !=
                      'approved')
                    OutlinedButton.icon(
                      onPressed:
                      _busy
                          ? null
                          : () =>
                          _save(
                            'draft',
                          ),
                      icon:
                      const Icon(
                        Icons
                            .save_outlined,
                      ),
                      label:
                      const Text(
                        'Save Draft',
                      ),
                    ),

                  FilledButton.icon(
                    onPressed:
                    _busy
                        ? null
                        : () =>
                        _save(
                          'pending',
                        ),
                    icon:
                    const Icon(
                      Icons
                          .send_outlined,
                    ),
                    label:
                    const Text(
                      'Submit for Review',
                    ),
                  ),
                ],
              ),

            // ==========================================
            // BUSY INDICATOR
            // ==========================================

            if (_busy) ...[
              const SizedBox(
                height: 12,
              ),

              const LinearProgressIndicator(),
            ],

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}