import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import 'my_feedback_page.dart';

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
      final visits = await _repository.fetchCompletedVisitsWithoutFeedback();
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _visit = visits.firstOrNull;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Submit Rating & Feedback',
    role: 'TOURIST',
    selectedNavigationIndex: 4,
    child: _visits == null && _error == null
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorView(message: _error!, onRetry: _retry)
        : _visits!.isEmpty
        ? const ModuleCard(
            child: Text('No completed visits are waiting for feedback.'),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<VisitOption>(
                initialValue: _visit,
                decoration: const InputDecoration(
                  labelText: 'Completed visit',
                  border: OutlineInputBorder(),
                ),
                items: _visits!
                    .map(
                      (visit) => DropdownMenuItem(
                        value: visit,
                        child: Text(
                          '${visit.attractionName} · ${visit.bookingCode}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _visit = value),
              ),
              const SizedBox(height: 16),
              _RatingCard(
                title: 'Overall experience',
                value: _overallRating,
                onChanged: (value) => setState(() => _overallRating = value),
              ),
              const SizedBox(height: 14),
              _RatingCard(
                title: 'Crowd comfort',
                value: _crowdComfort,
                onChanged: (value) => setState(() => _crowdComfort = value),
              ),
              const SizedBox(height: 14),
              const Text('What did you like most?'),
              Wrap(
                spacing: 8,
                children: _tags
                    .map(
                      (tag) => FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (selected) => setState(() {
                          selected
                              ? _selectedTags.add(tag)
                              : _selectedTags.remove(tag);
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _commentController,
                maxLength: 2000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Submitting…' : 'Submit Feedback'),
                ),
              ),
            ],
          ),
  );

  void _retry() {
    setState(() => _error = null);
    _load();
  }

  Future<void> _submit() async {
    if (_visit == null || _overallRating == 0 || _crowdComfort == 0) {
      _snack('Choose a completed visit and both ratings.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.submitFeedback(
        bookingId: _visit!.bookingId,
        overallRating: _overallRating,
        crowdComfort: _crowdComfort,
        tags: _selectedTags.toList(),
        comment: _commentController.text,
      );
      if (!mounted) return;
      _snack('Feedback submitted successfully.');
      Navigator.pushReplacementNamed(context, MyFeedbackPage.routeName);
    } catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
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
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => IconButton(
              onPressed: () => onChanged(index + 1),
              icon: Icon(index < value ? Icons.star : Icons.star_border),
              color: const Color(0xFFFFA000),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String _message(Object error) => error
    .toString()
    .replaceFirst('AuthException(message: ', '')
    .replaceFirst(')', '')
    .replaceFirst('Exception: ', '');
