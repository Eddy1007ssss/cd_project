import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  static const routeName = '/report-issue';

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _repository = EngagementRepository();

  final _location = TextEditingController();
  final _description = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  static const _categories = [
    'Overcrowding',
    'Safety',
    'Facility',
    'Accessibility',
    'Others',
  ];

  String _category = _categories.first;

  List<VisitOption> _visits = const [];
  VisitOption? _visit;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _saving = false;
  bool _loadingVisits = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      final visits = await _repository.fetchUpcomingVisits();

      if (!mounted) return;

      setState(() {
        _visits = visits;
        _visit = visits.firstOrNull;
        _loadingVisits = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingVisits = false;
      });

      _snack(error.toString());
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              6,
              18,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Photo Evidence',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose how you want to add the photo.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 16),

                // CAMERA
                _PhotoOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  subtitle: 'Use your camera to capture evidence',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  },
                ),

                const SizedBox(height: 10),

                // GALLERY
                _PhotoOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      // Maximum 5 MB
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _snack('Photo must be smaller than 5 MB.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      debugPrint('IMAGE PICKER ERROR: $error');

      if (mounted) {
        _snack('Unable to add photo.');
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Report an Issue',
      role: 'TOURIST',
      selectedNavigationIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF9800),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tell us what happened so the attraction operator can review the issue.',
                    style: TextStyle(
                      color: Color(0xFF8A5A00),
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Related Visit',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          if (_loadingVisits)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFDDE3EC),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_visits.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFDDE3EC),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: Color(0xFF98A2B3),
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'No confirmed visit available.',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<VisitOption>(
              initialValue: _visit,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select related visit',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFFDDE3EC),
                  ),
                ),
              ),
              items: _visits
                  .map(
                    (visit) => DropdownMenuItem(
                  value: visit,
                  child: Text(
                    '${visit.attractionName} · ${visit.bookingCode}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _visit = value;
                });
              },
            ),

          const SizedBox(height: 16),

          const Text(
            'Issue Category',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 9),

          Wrap(
            spacing: 8,
            runSpacing: 9,
            children: _categories.map((category) {
              final selected = _category == category;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _category = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF5252)
                        : const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFCACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        category,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFFB42318),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          const Text(
            'Location',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _location,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'e.g. Main entrance, Level 2, Gallery A',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF98A2B3),
              ),
              counterText: '',
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFFF6B35),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDDE3EC),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Description',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _description,
            maxLength: 2000,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the issue clearly...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF98A2B3),
              ),
              counterText: '',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDDE3EC),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Photo Evidence',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFFDDE3EC),
              ),
            ),
            child: _selectedImageBytes == null
                ? InkWell(
              onTap: _showPhotoSourceSheet,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Color(0xFF667085),
                      size: 23,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: Color(0xFF344054),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Take a photo or choose from gallery.',
                            style: TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Optional · Maximum 5 MB',
                            style: TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF98A2B3),
                    ),
                  ],
                ),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _selectedImageBytes!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 17,
                    ),

                    const SizedBox(width: 7),

                    const Expanded(
                      child: Text(
                        'Photo attached',
                        style: TextStyle(
                          color: Color(0xFF344054),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: _showPhotoSourceSheet,
                      child: const Text(
                        'Change',
                      ),
                    ),

                    TextButton(
                      onPressed: _removePhoto,
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC80),
                foregroundColor: const Color(0xFF7A5415),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                _saving
                    ? 'Submitting…'
                    : 'Submit Issue Report',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_visit == null) {
      _snack(
        'A confirmed visit is required so the report reaches its operator.',
      );
      return;
    }

    if (_location.text.trim().length < 2) {
      _snack('Please enter the issue location.');
      return;
    }

    if (_description.text.trim().length < 10) {
      _snack('Please enter a clearer description with at least 10 characters.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String? evidencePath;

      // Upload photo first if selected
      if (_selectedImage != null &&
          _selectedImageBytes != null) {
        var extension = 'jpg';

        final fileName = _selectedImage!.name;

        if (fileName.contains('.')) {
          extension = fileName
              .split('.')
              .last
              .toLowerCase();
        }

        evidencePath =
        await _repository.uploadIssueEvidence(
          bytes: _selectedImageBytes!,
          extension: extension,
        );
      }

      // Save issue report
      await _repository.submitIssue(
        category: _category,
        location: _location.text,
        description: _description.text,
        evidencePath: evidencePath,
        visit: _visit,
      );

      if (!mounted) return;

      _snack(
        'Issue report submitted successfully.',
      );

      Navigator.pushReplacementNamed(
        context,
        '/feedback-centre',
      );
    } catch (error) {
      if (mounted) {
        _snack(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FC),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF9800),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}