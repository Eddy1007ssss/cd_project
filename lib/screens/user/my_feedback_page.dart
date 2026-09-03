import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class MyFeedbackPage extends StatefulWidget {
  const MyFeedbackPage({super.key});
  static const routeName = '/my-feedback';
  @override
  State<MyFeedbackPage> createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends State<MyFeedbackPage> {
  final _repository = EngagementRepository();
  late Future<List<FeedbackEntry>> _feedback;
  @override
  void initState() {
    super.initState();
    _feedback = _repository.fetchMyFeedback();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'My Feedback',
    role: 'TOURIST',
    selectedNavigationIndex: 4,
    child: FutureBuilder<List<FeedbackEntry>>(
      future: _feedback,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ModuleCard(child: Text(snapshot.error.toString()));
        }
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return const ModuleCard(child: Text('No feedback submitted yet.'));
        }
        return Column(
          children: entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeedbackCard(entry: entry),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry});
  final FeedbackEntry entry;
  @override
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.attractionName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text('Booking ${entry.bookingCode}'),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < entry.overallRating ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFA000),
            ),
          ),
        ),
        Text('Crowd comfort: ${entry.crowdComfort}/5'),
        if (entry.tags.isNotEmpty) Text(entry.tags.join(' · ')),
        if (entry.comment.isNotEmpty) ...[const Divider(), Text(entry.comment)],
        const SizedBox(height: 8),
        Text(
          '${entry.createdAt.toLocal()}',
          style: const TextStyle(color: TourFlowColors.muted, fontSize: 10),
        ),
      ],
    ),
  );
}
