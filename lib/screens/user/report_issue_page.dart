import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  static const routeName = '/report-issue';

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _selectedCategory = 'Overcrowding';

  final TextEditingController _locationController =
  TextEditingController(text: 'Gallery 3 entrance');

  final TextEditingController _descriptionController =
  TextEditingController(text: 'Queue blocked the emergency path.');

  final List<String> _categories = [
    'Overcrowding',
    'Safety',
    'Facility',
    'Accessibility',
    'Others',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us about what happened',
                  style: TextStyle(
                    color: Color(0xFFFF424D),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your report helps us take action quickly',
                  style: TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Issue Category',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final selected = _selectedCategory == category;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF4D5A)
                        : const Color(0xFFFFF4F4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF4D5A)
                          : const Color(0xFFFFD5D8),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFFF4D5A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              labelStyle: const TextStyle(
                color: TourFlowColors.muted,
                fontSize: 11,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFAAB7CC),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: const TextStyle(
                color: TourFlowColors.muted,
                fontSize: 11,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFAAB7CC),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          ModuleCard(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo attachment selected.'),
                  ),
                );
              },
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo attachment',
                    style: TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add an optional photo without including identifiable faces.',
                    style: TextStyle(
                      color: TourFlowColors.body,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'JPG or PNG · maximum 5 MB',
                    style: TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitIssue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC80),
                foregroundColor: const Color(0xFF7A5200),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Submit Issue Report',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitIssue() {
    if (_locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete the location and description.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Issue report submitted successfully.',
        ),
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      '/feedback-centre',
    );
  }
}