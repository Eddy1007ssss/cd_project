import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class ResolveReportPage extends StatefulWidget {
  const ResolveReportPage({super.key});

  static const routeName = '/resolve-report';

  @override
  State<ResolveReportPage> createState() =>
      _ResolveReportPageState();
}

class _ResolveReportPageState extends State<ResolveReportPage> {
  final _repository = EngagementRepository();
  final _note = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report =
    ModalRoute.of(context)?.settings.arguments as IssueReport?;

    return TourFlowPage(
      title: 'Report Details',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 3,
      child: report == null
          ? const ModuleCard(
        child: Text(
          'No report was selected.',
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF5252),
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.category,
                            style: const TextStyle(
                              color: TourFlowColors.heading,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Report #${report.code}',
                            style: const TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _ReportStatusBadge(
                      status: report.status,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Divider(
                  height: 1,
                  color: Color(0xFFEAECF0),
                ),

                const SizedBox(height: 15),

                _DetailRow(
                  icon: Icons.location_city_outlined,
                  label: 'Attraction',
                  value: report.attractionName ??
                      'Attraction unavailable',
                ),

                const SizedBox(height: 13),

                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: report.location,
                ),

                const SizedBox(height: 13),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFF98A2B3),
                      size: 17,
                    ),

                    const SizedBox(width: 8),

                    const SizedBox(
                      width: 68,
                      child: Text(
                        'Priority',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    _PriorityChip(
                      priority: report.priority,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issue Description',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  report.description.trim().isEmpty
                      ? 'No description provided.'
                      : report.description,
                  style: const TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          if (report.evidencePath != null &&
              report.evidencePath!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),

            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: Color(0xFFFF9800),
                        size: 19,
                      ),

                      SizedBox(width: 7),

                      Text(
                        'Photo Evidence',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  _EvidencePhoto(
                    evidencePath: report.evidencePath!,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Photo submitted by the tourist as supporting evidence.',
                    style: TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          if (report.status == 'new') ...[
            ModuleCard(
              color: const Color(0xFFF8FAFC),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF64748B),
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Start handling this report before adding a resolution response.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                  _startHandling(report);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(
                    color: Color(0xFF93C5FD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.handyman_outlined,
                  size: 19,
                ),
                label: Text(
                  _saving
                      ? 'Updating...'
                      : 'Start Handling',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],

          if (report.status == 'in_progress') ...[
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFFFF9800),
                        size: 19,
                      ),

                      SizedBox(width: 7),

                      Text(
                        'Operator Response',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Explain how the issue was handled before resolving the report.',
                    style: TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _note,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Enter response for the tourist...',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF98A2B3),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.all(13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFDDE3EC),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF22A06B),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                  _resolve(report);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22A06B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 19,
                ),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : 'Mark as Resolved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],

          if (report.status == 'resolved') ...[
            ModuleCard(
              color: const Color(0xFFF0FDF4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF159447),
                        size: 20,
                      ),

                      SizedBox(width: 7),

                      Text(
                        'Operator Response',
                        style: TextStyle(
                          color: Color(0xFF137A3A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SelectableText(
                    report.resolutionNote == null ||
                        report.resolutionNote!
                            .trim()
                            .isEmpty
                        ? 'No response was provided.'
                        : report.resolutionNote!,
                    style: const TextStyle(
                      color: TourFlowColors.body,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _startHandling(
      IssueReport report,
      ) async {
    setState(() {
      _saving = true;
    });

    try {
      await _repository.startReport(
        report.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report moved to In Progress.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _resolve(
      IssueReport report,
      ) async {
    if (_note.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a response before resolving the report.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _repository.resolveReport(
        report.id,
        _note.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report resolved successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF98A2B3),
          size: 17,
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value.trim().isEmpty
                ? 'Not provided'
                : value,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportStatusBadge extends StatelessWidget {
  const _ReportStatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (status) {
      'new' => const Color(0xFFE53935),
      'in_progress' => const Color(0xFFD99000),
      'resolved' => const Color(0xFF159447),
      _ => TourFlowColors.muted,
    };

    final background = switch (status) {
      'new' => const Color(0xFFFFECEB),
      'in_progress' => const Color(0xFFFFF8E5),
      'resolved' => const Color(0xFFE7FAEC),
      _ => const Color(0xFFF0F2F5),
    };

    final label = switch (status) {
      'new' => 'Pending',
      'in_progress' => 'In Progress',
      'resolved' => 'Resolved',
      _ => status.replaceAll('_', ' '),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
  });

  final String priority;

  @override
  Widget build(BuildContext context) {
    final urgent =
        priority.toLowerCase() == 'urgent';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFFECEB)
            : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: urgent
              ? const Color(0xFFE53935)
              : const Color(0xFFB36A00),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EvidencePhoto extends StatefulWidget {
  const _EvidencePhoto({
    required this.evidencePath,
  });

  final String evidencePath;

  @override
  State<_EvidencePhoto> createState() =>
      _EvidencePhotoState();
}

class _EvidencePhotoState
    extends State<_EvidencePhoto> {
  final _repository = EngagementRepository();

  late Future<String?> _signedUrl;

  @override
  void initState() {
    super.initState();

    _signedUrl =
        _repository.createIssueEvidenceSignedUrl(
          widget.evidencePath,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _signedUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFDDE3EC),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }

        final url = snapshot.data;

        if (snapshot.hasError ||
            url == null ||
            url.trim().isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFDDE3EC),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF98A2B3),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Unable to load photo evidence.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFDDE3EC),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              url,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,

              loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                  ) {
                if (loadingProgress == null) {
                  return child;
                }

                return Container(
                  width: double.infinity,
                  height: 200,
                  color: const Color(0xFFF8F9FC),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              },

              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                return Container(
                  width: double.infinity,
                  height: 180,
                  color: const Color(0xFFF8F9FC),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF98A2B3),
                        size: 28,
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Unable to load photo.',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}