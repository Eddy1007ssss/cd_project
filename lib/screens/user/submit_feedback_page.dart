import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class SubmitFeedbackPage extends StatefulWidget {
  const SubmitFeedbackPage({super.key});

  static const routeName = '/submit-feedback';

  @override
  State<SubmitFeedbackPage> createState() => _SubmitFeedbackPageState();
}

class _SubmitFeedbackPageState extends State<SubmitFeedbackPage> {
  final _repository = EngagementRepository();
  final _commentController = TextEditingController();

  final _selectedTags = <String>{};

  static const _tags = [
    'Friendly staff',
    'Clean',
    'Well organised',
    'Not crowded',
  ];

  List<VisitOption>? _visits;
  VisitOption? _visit;

  int _overallRating = 0;
  int _crowdComfort = 0;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final visits =
      await _repository.fetchCompletedVisitsWithoutFeedback();

      if (!mounted) return;

      setState(() {
        _visits = visits;
        _visit = visits.firstOrNull;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _message(error);
        });
      }
    }
  }

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
      child: _visits == null && _error == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? _ErrorView(
        message: _error!,
        onRetry: _retry,
      )
          : _visits!.isEmpty
          ? const ModuleCard(
        child: Text(
          'No completed visits are waiting for feedback.',
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFDDE3EC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _visit?.attractionName ?? '',
                        style: const TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F9ED),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Color(0xFF22C55E),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  'Booking ${_visit?.bookingCode ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                  ),
                ),

                if (_visits!.length > 1) ...[
                  const SizedBox(height: 12),

                  DropdownButtonFormField<VisitOption>(
                    initialValue: _visit,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select completed visit',
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    items: _visits!
                        .map(
                          (visit) => DropdownMenuItem(
                        value: visit,
                        child: Text(
                          '${visit.attractionName} · ${visit.bookingCode}',
                          overflow: TextOverflow.ellipsis,
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
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          _RatingCard(
            title: 'Your Overall experience',
            value: _overallRating,
            onChanged: (value) {
              setState(() {
                _overallRating = value;
              });
            },
          ),

          const SizedBox(height: 14),

          const Text(
            'What did you like most?',
            style: TextStyle(
              color: Color(0xFF475467),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 9,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFA000)
                        : const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFA000)
                          : const Color(0xFFFFD98A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        tag,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFFB36A00),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          _RatingCard(
            title: 'Crowd comfort',
            value: _crowdComfort,
            onChanged: (value) {
              setState(() {
                _crowdComfort = value;
              });
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _commentController,
            maxLength: 2000,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Comment',
              hintText:
              'Share more about your experience...',
              counterText: '',
              contentPadding: const EdgeInsets.all(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF98A2B3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFFFFCC80),
                foregroundColor:
                const Color(0xFF7A5415),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(9),
                ),
              ),
              child: Text(
                _submitting
                    ? 'Submitting…'
                    : 'Submit Feedback',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _error = null;
    });

    _load();
  }

  Future<void> _submit() async {
    if (_visit == null ||
        _overallRating == 0 ||
        _crowdComfort == 0) {
      _snack(
        'Choose a completed visit and both ratings.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _repository.submitFeedback(
        bookingId: _visit!.bookingId,
        overallRating: _overallRating,
        crowdComfort: _crowdComfort,
        tags: _selectedTags.toList(),
        comment: _commentController.text,
      );

      if (!mounted) return;

      _snack(
        'Feedback submitted successfully.',
      );

      Navigator.pushReplacementNamed(
        context,
        '/feedback-centre',
      );
    } catch (error) {
      if (mounted) {
        _snack(
          _message(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFDDE3EC),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 11),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
                  (index) {
                final rating = index + 1;
                final selected = rating <= value;

                return GestureDetector(
                  onTap: () {
                    onChanged(rating);
                  },
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 150),
                    width: 39,
                    height: 39,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? const Color(0xFFFFA000)
                          : const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFFA000)
                            : const Color(0xFFD8DEE8),
                      ),
                    ),
                    child: Text(
                      '$rating',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF667085),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Column(
        children: [
          Text(message),

          const SizedBox(height: 8),

          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _message(Object error) {
  return error
      .toString()
      .replaceFirst(
    'AuthException(message: ',
    '',
  )
      .replaceFirst(')', '')
      .replaceFirst(
    'Exception: ',
    '',
  );
}