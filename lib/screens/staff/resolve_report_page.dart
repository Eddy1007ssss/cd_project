import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class ResolveReportPage extends StatefulWidget {
  const ResolveReportPage({super.key});

  static const routeName = '/resolve-report';

  @override
  State<ResolveReportPage> createState() => _ResolveReportPageState();
}

class _ResolveReportPageState extends State<ResolveReportPage> {
  final TextEditingController _resolutionController =
  TextEditingController(
    text: 'Emergency path cleared and monitored',
  );

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Resolve Report',
      role: 'TOURFLOW · OPERATOR',
      isStaff: true,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // REPORT DETAILS
          // =========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report #R-2041',
                  style: TextStyle(
                    color: Color(0xFFFF4D5A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Emergency path obstructed near Gallery 3.',
                  style: TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _UrgentChip(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =========================
          // RESOLUTION ACTIVITY
          // =========================
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resolution activity',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                const _ActivityItem(
                  text: 'Report received',
                  time: '4:18 PM',
                  completed: true,
                ),

                const Divider(height: 22),

                const _ActivityItem(
                  text: 'Floor supervisor assigned',
                  time: '4:20 PM',
                  completed: true,
                ),

                const Divider(height: 22),

                const _ActivityItem(
                  text: 'Queue barriers repositioned',
                  time: '4:27 PM',
                  completed: true,
                ),

                const Divider(height: 22),

                const _ActivityItem(
                  text: 'Tourist confirmation pending',
                  time: 'Current step',
                  completed: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =========================
          // RESOLUTION NOTE
          // =========================
          const Text(
            'Resolution note',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: _resolutionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter resolution note',
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

          const SizedBox(height: 14),

          // =========================
          // MARK AS RESOLVED
          // =========================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _markAsResolved,
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
                'Mark as Resolved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsResolved() {
    if (_resolutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a resolution note.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report resolved successfully.',
        ),
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      '/operator-report-queue',
    );
  }
}

// =========================
// URGENT CHIP
// =========================

class _UrgentChip extends StatelessWidget {
  const _UrgentChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D5A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'URGENT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =========================
// ACTIVITY ITEM
// =========================

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.text,
    required this.time,
    required this.completed,
  });

  final String text;
  final String time;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? const Color(0xFF20C875)
                : const Color(0xFFB8C0CC),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}