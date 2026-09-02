import 'package:flutter/material.dart';
import '../../widgets/tourflow_widgets.dart';

class SubmitFeedbackPage extends StatefulWidget {
  const SubmitFeedbackPage({super.key});

  static const routeName = '/submit-feedback';

  @override
  State<SubmitFeedbackPage> createState() => _SubmitFeedbackPageState();
}

class _SubmitFeedbackPageState extends State<SubmitFeedbackPage> {
  int _overallRating = 4;
  int _crowdComfort = 4;

  final Set<String> _selectedTags = {
    'Friendly staff',
    'Well organised',
    'Not crowded',
  };

  final TextEditingController _commentController =
  TextEditingController(text: 'Quiet slot and helpful exhibits.');

  final List<String> _tags = [
    'Friendly staff',
    'Clean',
    'Well organised',
    'Not crowded',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Submit Rating & Feedback',
      role: 'TOURIST',
      selectedNavigationIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'National Museum',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9FBEF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: Color(0xFF20C875),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Color(0xFF20A45A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Visited 17 September · 4:00 PM',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Booking NM-170926-1600-A1',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          ModuleCard(
            child: Column(
              children: [
                const Text(
                  'Your Overall experience',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _ratingSelector(
                  selected: _overallRating,
                  onChanged: (value) {
                    setState(() {
                      _overallRating = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'What did you like most?',
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
            children: _tags.map((tag) {
              final selected = _selectedTags.contains(tag);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFFFFF5E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFA000)
                          : const Color(0xFFFFD9A0),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: selected
                          ? Colors.black
                          : const Color(0xFF9A6400),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          ModuleCard(
            child: Column(
              children: [
                const Text(
                  'Crowd comfort',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _ratingSelector(
                  selected: _crowdComfort,
                  onChanged: (value) {
                    setState(() {
                      _crowdComfort = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Comment',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFB6C0D0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFB6C0D0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC80),
                foregroundColor: const Color(0xFF7A5200),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Submit Feedback',
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

  Widget _ratingSelector({
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isSelected = value <= selected;

        return GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFFFA000)
                  : const Color(0xFFF4F5F7),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFA000)
                    : const Color(0xFFE2E5EA),
              ),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : TourFlowColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _submitFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback submitted successfully.'),
      ),
    );

    Navigator.pop(context);
  }
}