import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

const _reportInk = Color(0xFF101828);
const _reportBody = Color(0xFF475467);
const _reportMuted = Color(0xFF667085);
const _reportGold = Color(0xFFFF9800);
const _reportBorder = Color(0xFFDDE3EC);

class ReportStatusPage extends StatefulWidget {
  const ReportStatusPage({super.key});

  static const routeName = '/report-status';

  @override
  State<ReportStatusPage> createState() => _ReportStatusPageState();
}

class _ReportStatusPageState extends State<ReportStatusPage>
    with WidgetsBindingObserver {
  final _repository = EngagementRepository();

  Timer? _timer;
  Future<void>? _loadTask;

  List<IssueReport> _reports = const [];

  bool _loading = true;
  bool _hasLoaded = false;
  bool _foreground = true;

  String _filter = 'all';
  String? _error;
  String? _selectedReportId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadReports();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;

    if (_foreground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _loadReports();
      }

      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ==========================================================
  // AUTO REFRESH EVERY 5 SECONDS
  // ==========================================================

  void _startTimer() {
    _timer?.cancel();

    if (!_foreground) return;

    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        if (!mounted || !_foreground) return;

        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        _loadReports();
      },
    );
  }

  // ==========================================================
  // LOAD REPORTS
  // ==========================================================

  Future<void> _loadReports() {
    if (!mounted || !_foreground) {
      return Future<void>.value();
    }

    return _loadTask ??= _fetchReports().whenComplete(
          () {
        _loadTask = null;
      },
    );
  }

  Future<void> _fetchReports() async {
    try {
      final reports = await _repository.fetchMyReports();

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _hasLoaded = true;
        _error = null;

        if (_selectedReportId != null &&
            !reports.any(
                  (report) => report.id == _selectedReportId,
            )) {
          _selectedReportId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = _hasLoaded
            ? 'Unable to refresh. Showing previously loaded reports.'
            : 'Unable to load reports.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================
  // STATUS COUNT
  // ==========================================================

  int _count(String status) {
    return _reports.where(
          (report) => report.status == status,
    ).length;
  }

  Widget _stat({
    required String label,
    required String filter,
    required int count,
  }) {
    return Expanded(
      child: _StatCard(
        label: label,
        count: count,
        selected: _filter == filter,
        onTap: () {
          setState(() {
            _filter = filter;
          });
        },
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _errorNotice() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _reportGold,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFF8A5A00),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PAGE CONTENT
  // ==========================================================

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 48,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    IssueReport? selectedReport;

    for (final report in _reports) {
      if (report.id == _selectedReportId) {
        selectedReport = report;
        break;
      }
    }

    // ========================================================
    // REPORT DETAILS
    // ========================================================

    if (selectedReport != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedReportId = null;
                });
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
              ),
              label: const Text(
                'Your Reports',
              ),
              style: TextButton.styleFrom(
                foregroundColor: _reportGold,
              ),
            ),
          ),

          const SizedBox(height: 4),

          if (_error != null) _errorNotice(),

          _ReportDetails(
            report: selectedReport,
          ),
        ],
      );
    }

    // ========================================================
    // FILTER REPORTS
    // ========================================================

    final visibleReports = _reports
        .where(
          (report) =>
      _filter == 'all' ||
          report.status == _filter,
    )
        .toList();

    // ========================================================
    // REPORT LIST
    // ========================================================

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =====================================================
        // INFO CARD
        // =====================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: _reportGold,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Track the progress and response of your submitted reports.',
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

        if (_error != null) _errorNotice(),

        if (_hasLoaded) ...[
          // ==================================================
          // STATUS FILTER
          // ==================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stat(
                label: 'All',
                filter: 'all',
                count: _reports.length,
              ),

              const SizedBox(width: 7),

              _stat(
                label: 'Pending',
                filter: 'new',
                count: _count('new'),
              ),

              const SizedBox(width: 7),

              _stat(
                label: 'In Progress',
                filter: 'in_progress',
                count: _count('in_progress'),
              ),

              const SizedBox(width: 7),

              _stat(
                label: 'Resolved',
                filter: 'resolved',
                count: _count('resolved'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ==================================================
          // YOUR REPORTS
          // ==================================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Reports',
                  style: TextStyle(
                    color: _reportInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  _loadReports();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: _reportGold,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==================================================
          // EMPTY REPORT
          // ==================================================

          if (visibleReports.isEmpty)
            const _WhitePanel(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 22,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF98A2B3),
                      size: 34,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No reports in this section.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _reportMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==================================================
          // REPORT CARDS
          // ==================================================

          for (final report in visibleReports)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _ReportSummary(
                report: report,
                onTap: () {
                  setState(() {
                    _selectedReportId = report.id;
                  });
                },
              ),
            ),
        ],
      ],
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'My Report Status',
      role: 'TOURIST',
      selectedNavigationIndex: 4,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }
}

// =============================================================
// STATUS CARD
// =============================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFFFF4E5)
          : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFC46B)
                  : _reportBorder,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? _reportGold
                      : _reportInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF8A5A00)
                      : _reportMuted,
                  fontSize: 9,
                  height: 1.3,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// REPORT SUMMARY CARD
// =============================================================

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({
    required this.report,
    required this.onTap,
  });

  final IssueReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = report.location.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _reportBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // CATEGORY + STATUS
              // =================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF5252),
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.category,
                          style: const TextStyle(
                            color: _reportInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Report #${report.code}',
                          style: const TextStyle(
                            color: _reportMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _StatusBadge(
                    status: report.status,
                  ),
                ],
              ),

              const SizedBox(height: 13),

              // =================================================
              // ATTRACTION
              // =================================================

              if (report.attractionName != null &&
                  report.attractionName!.trim().isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.location_city_outlined,
                      size: 15,
                      color: _reportMuted,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        report.attractionName!,
                        style: const TextStyle(
                          color: _reportBody,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

              // =================================================
              // LOCATION
              // =================================================

              if (location.isNotEmpty) ...[
                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: _reportMuted,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: _reportBody,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // =================================================
              // DESCRIPTION
              // =================================================

              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _reportBody,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 13),

              const Divider(
                height: 1,
                color: Color(0xFFEAECF0),
              ),

              const SizedBox(height: 10),

              // =================================================
              // TIME
              // =================================================

              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: Color(0xFF98A2B3),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      'Submitted ${_relativeTime(report.createdAt)}',
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 9,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF98A2B3),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// STATUS BADGE
// =============================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (status) {
      'new' => const Color(0xFFE53935),
      'in_progress' => const Color(0xFFD99000),
      'resolved' => const Color(0xFF159447),
      _ => _reportMuted,
    };

    final background = switch (status) {
      'new' => const Color(0xFFFFECEB),
      'in_progress' => const Color(0xFFFFF8E5),
      'resolved' => const Color(0xFFE7FAEC),
      _ => const Color(0xFFF0F2F5),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================
// REPORT DETAILS
// =============================================================

class _ReportDetails extends StatelessWidget {
  const _ReportDetails({
    required this.report,
  });

  final IssueReport report;

  @override
  Widget build(BuildContext context) {
    final response = report.resolutionNote?.trim();

    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =====================================================
          // TITLE + STATUS
          // =====================================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Report Details',
                  style: TextStyle(
                    color: _reportInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              _StatusBadge(
                status: report.status,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _statusDescription(
              report.status,
            ),
            style: const TextStyle(
              color: _reportMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const Divider(
            height: 30,
            color: _reportBorder,
          ),

          // =====================================================
          // REPORT INFORMATION
          // =====================================================

          _DetailField(
            label: 'Report ID',
            value: report.code,
          ),

          _DetailField(
            label: 'Category',
            value: report.category,
          ),

          _DetailField(
            label: 'Submitted On',
            value: _fullDateTime(
              report.createdAt,
            ),
          ),

          _DetailField(
            label: 'Attraction',
            value:
            report.attractionName ??
                'Not available',
          ),

          _DetailField(
            label: 'Location',
            value: report.location,
          ),

          _DetailField(
            label: 'Description',
            value: report.description,
          ),

          // =====================================================
          // PHOTO EVIDENCE
          // =====================================================

          if (report.evidencePath != null &&
              report.evidencePath!.trim().isNotEmpty) ...[
            const Text(
              'Photo Evidence',
              style: TextStyle(
                color: _reportMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            _EvidencePhoto(
              evidencePath: report.evidencePath!,
            ),

            const SizedBox(height: 18),
          ],

          // =====================================================
          // OPERATOR RESPONSE
          // =====================================================

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: _reportGold,
                      size: 19,
                    ),

                    SizedBox(width: 7),

                    Text(
                      'Operator Response',
                      style: TextStyle(
                        color: Color(0xFF8A5A00),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                SelectableText(
                  response == null ||
                      response.isEmpty
                      ? 'No response provided yet.'
                      : response,
                  style: const TextStyle(
                    color: _reportBody,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PHOTO EVIDENCE
// =============================================================

class _EvidencePhoto extends StatefulWidget {
  const _EvidencePhoto({
    required this.evidencePath,
  });

  final String evidencePath;

  @override
  State<_EvidencePhoto> createState() =>
      _EvidencePhotoState();
}

class _EvidencePhotoState extends State<_EvidencePhoto> {
  final _repository = EngagementRepository();

  late Future<String?> _signedUrl;

  @override
  void initState() {
    super.initState();

    _loadPhoto();
  }

  void _loadPhoto() {
    _signedUrl =
        _repository.createIssueEvidenceSignedUrl(
          widget.evidencePath,
        );
  }

  @override
  void didUpdateWidget(
      covariant _EvidencePhoto oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.evidencePath != widget.evidencePath) {
      _loadPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _signedUrl,
      builder: (context, snapshot) {
        // =====================================================
        // LOADING
        // =====================================================

        if (snapshot.connectionState !=
            ConnectionState.done) {
          return Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _reportBorder,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }

        final url = snapshot.data;

        // =====================================================
        // ERROR
        // =====================================================

        if (snapshot.hasError ||
            url == null ||
            url.trim().isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _reportBorder,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF98A2B3),
                  size: 21,
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

        // =====================================================
        // IMAGE
        // =====================================================

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _reportBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              url,
              width: double.infinity,
              height: 190,
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
                  height: 190,
                  color: const Color(0xFFF8F9FC),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
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
                  height: 170,
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

// =============================================================
// DETAIL FIELD
// =============================================================

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 17,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _reportMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          SelectableText(
            value.trim().isEmpty
                ? 'Not provided'
                : value,
            style: const TextStyle(
              color: _reportInk,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// WHITE PANEL
// =============================================================

class _WhitePanel extends StatelessWidget {
  const _WhitePanel({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _reportBorder,
        ),
      ),
      child: child,
    );
  }
}

// =============================================================
// STATUS LABEL
// =============================================================

String _statusLabel(String status) {
  return switch (status) {
    'new' => 'Pending',
    'in_progress' => 'In Progress',
    'resolved' => 'Resolved',
    _ => status.replaceAll('_', ' '),
  };
}

// =============================================================
// STATUS DESCRIPTION
// =============================================================

String _statusDescription(String status) {
  return switch (status) {
    'new' =>
    'Your report has been submitted and is awaiting review.',

    'in_progress' =>
    'Your report is currently being handled by the operator.',

    'resolved' =>
    'Your report has been marked as resolved.',

    _ =>
    'Check the operator response for further information.',
  };
}

// =============================================================
// RELATIVE TIME
// =============================================================

String _relativeTime(DateTime value) {
  final localValue = value.toLocal();

  final difference = DateTime.now().difference(
    localValue,
  );

  if (difference.isNegative ||
      difference.inMinutes < 1) {
    return 'just now';
  }

  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;

    return '$minutes '
        '${minutes == 1 ? 'minute' : 'minutes'} ago';
  }

  if (difference.inHours < 24) {
    final hours = difference.inHours;

    return '$hours '
        '${hours == 1 ? 'hour' : 'hours'} ago';
  }

  if (difference.inDays < 7) {
    final days = difference.inDays;

    return '$days '
        '${days == 1 ? 'day' : 'days'} ago';
  }

  return 'on ${_dateLabel(localValue)}';
}

// =============================================================
// DATE
// =============================================================

String _dateLabel(DateTime value) {
  final local = value.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${local.day} '
      '${months[local.month - 1]} '
      '${local.year}';
}

// =============================================================
// FULL DATE TIME
// =============================================================

String _fullDateTime(DateTime value) {
  final local = value.toLocal();

  final hour =
  local.hour.toString().padLeft(2, '0');

  final minute =
  local.minute.toString().padLeft(2, '0');

  return '${_dateLabel(local)} · '
      '$hour:$minute';
}